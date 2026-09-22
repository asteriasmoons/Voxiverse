//
//  VoxiverseReportConversationNotificationManager.swift
//  Voxiverse
//

import CloudKit
import Foundation
import UIKit
import UserNotifications

enum VoxiverseReportConversationNotificationManager {
    private static let container = CKContainer(identifier: ReportConversationCloudKitSchema.containerIdentifier)
    private static let subscriptionPrefix = "voxiverse-reporter-message-events-v3-"
    private static let processedMessagePrefix = "voxiverse.reportConversation.processedMessage."
    private static let deduplicationLock = NSLock()

    static func prepareNotifications() async {
        _ = await requestAuthorizationIfNeeded()
        await registerForRemoteNotifications()
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: ReportConversationCloudKitSchema.zoneName, ownerName: CKCurrentUserDefaultName)
        if let result = try? await database.recordZones(for: [zoneID])[zoneID], (try? result.get()) != nil {
            do {
                try await ensureMessageSubscription(database: database, zoneID: zoneID)
            } catch {
                reportNotifLog("message subscription registration FAILED [type=CKRecordZoneSubscription scope=private zone=\(zoneID.zoneName) owner=\(zoneID.ownerName)]: \(error.localizedDescription)")
            }
        }
    }

    static func reportNotifLog(_ message: String) {
        #if DEBUG
        print("[ReportNotif][Voxiverse] \(message)")
        #endif
    }

    static func registerPrivateConversationNotifications(database: CKDatabase, conversationRecordID: CKRecord.ID) async throws {
        await prepareNotifications()
        try await ensureMessageSubscription(database: database, zoneID: conversationRecordID.zoneID)
    }

    static func clearReadConversationBadge() async {
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
    }

    /// Foreground/scene-active reconciliation. CloudKit does not deliver
    /// subscription pushes to the same device/account that made the change, so
    /// relying on push alone yields no notifications during single-device
    /// testing. This re-scans the private ReportConversations zone using the
    /// SAME persistent change token, dedup, and sender filter, so only
    /// genuinely new reporter messages notify.
    static func scanForNewMessages() async {
        await prepareNotifications()
        let zoneID = CKRecordZone.ID(zoneName: ReportConversationCloudKitSchema.zoneName, ownerName: CKCurrentUserDefaultName)
        if let result = try? await container.privateCloudDatabase.recordZones(for: [zoneID])[zoneID], (try? result.get()) != nil {
            _ = await processMessageChanges(in: zoneID)
        }
    }

    static func processMessageChanges(in zoneID: CKRecordZone.ID) async -> Bool {
        let database = container.privateCloudDatabase
        guard var token = loadChangeToken(for: zoneID) else {
            try? await seedChangeToken(database: database, zoneID: zoneID)
            return false
        }
        var didNotify = false
        var moreComing = true
        while moreComing {
            do {
                let changes = try await database.recordZoneChanges(inZoneWith: zoneID, since: token)
                for result in changes.modificationResultsByID.values {
                    guard let record = try? result.get().record else { continue }
                    didNotify = await notifyForNewReporterMessage(record, database: database) || didNotify
                }
                token = changes.changeToken
                saveChangeToken(token, for: zoneID)
                moreComing = changes.moreComing
            } catch let error as CKError where error.code == .changeTokenExpired {
                try? await seedChangeToken(database: database, zoneID: zoneID)
                return didNotify
            } catch {
                reportNotifLog("zone change fetch FAILED [scope=private zone=\(zoneID.zoneName) owner=\(zoneID.ownerName)]: \(error.localizedDescription)")
                return didNotify
            }
        }
        return didNotify
    }

    private static func ensureMessageSubscription(database: CKDatabase, zoneID: CKRecordZone.ID) async throws {
        let subscriptionID = subscriptionPrefix + zoneID.zoneName
        let obsoleteIDs = ["voxiverse-report-message-changes-v2-\(zoneID.zoneName)", "voxiverse-report-conversations-\(zoneID.zoneName)"]
        if loadChangeToken(for: zoneID) == nil { try await seedChangeToken(database: database, zoneID: zoneID) }
        // CloudKit stores subscriptions per-user (one server-side copy), but push
        // delivery is per-device+per-app: a device is only added to a subscription's
        // push set when THAT device saves the subscription while registered for
        // remote notifications. Checking server-side existence and skipping would
        // leave a second device (where the subscription already exists) without any
        // push. So gate on a per-device flag and save once per install, matching
        // Apple's CloudKit sample apps.
        let deviceFlagKey = deviceSubscriptionFlagKey(subscriptionID)
        guard !UserDefaults.standard.bool(forKey: deviceFlagKey) else { return }
        _ = try? await database.modifySubscriptions(saving: [], deleting: obsoleteIDs) // best-effort legacy cleanup
        let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: subscriptionID)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        _ = try await database.modifySubscriptions(saving: [subscription], deleting: [])
        UserDefaults.standard.set(true, forKey: deviceFlagKey)
    }

    private static func deviceSubscriptionFlagKey(_ subscriptionID: String) -> String {
        "voxiverse.reportConversation.deviceSubscriptionSaved.\(subscriptionID)"
    }

    private static func notifyForNewReporterMessage(_ message: CKRecord, database: CKDatabase) async -> Bool {
        guard message.recordType == ReportConversationCloudKitSchema.RecordType.message,
              message.voxConversationString(ReportConversationCloudKitSchema.MessageField.senderRole) == ReportConversationSenderRole.reporter.rawValue else { return false }
        let storedMessageID = message.voxConversationString(ReportConversationCloudKitSchema.MessageField.messageID)
        let messageID = storedMessageID.isEmpty ? message.recordID.recordName : storedMessageID
        let processedKey = processedMessagePrefix + messageID
        guard claimNotification(processedKey) else { return false }
        let rootID = (message[ReportConversationCloudKitSchema.MessageField.conversation] as? CKRecord.Reference)?.recordID
            ?? CKRecord.ID(recordName: message.voxConversationString(ReportConversationCloudKitSchema.MessageField.conversationRecordName), zoneID: message.recordID.zoneID)
        guard let root = try? await database.record(for: rootID) else { releaseNotification(processedKey); return false }
        guard await requestAuthorizationIfNeeded() else { releaseNotification(processedKey); return false }
        let reportID = root.voxConversationString(ReportConversationCloudKitSchema.ConversationField.reportID)
        let sourceAppID = root.voxConversationString(ReportConversationCloudKitSchema.ConversationField.sourceAppID)
        let sourceAppName = root.voxConversationString(ReportConversationCloudKitSchema.ConversationField.sourceAppName)
        guard !reportID.isEmpty, !sourceAppID.isEmpty else { releaseNotification(processedKey); return false }
        let content = UNMutableNotificationContent()
        content.title = sourceAppName.isEmpty ? sourceAppID : sourceAppName
        content.body = "A reporter replied to a private report conversation."
        content.sound = .default
        content.userInfo = ["kind": "reportConversationReply", "reportID": reportID, "sourceAppID": sourceAppID, "messageID": messageID]
        do {
            try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "voxiverse-report-conversation-message-\(messageID)", content: content, trigger: nil))
            return true
        } catch {
            reportNotifLog("local notification scheduling FAILED [messageID=\(messageID)]: \(error.localizedDescription)")
            releaseNotification(processedKey)
            return false
        }
    }

    private static func seedChangeToken(database: CKDatabase, zoneID: CKRecordZone.ID) async throws {
        var token: CKServerChangeToken?
        var moreComing = true
        while moreComing {
            let changes = try await database.recordZoneChanges(inZoneWith: zoneID, since: token, desiredKeys: [], resultsLimit: nil)
            token = changes.changeToken
            moreComing = changes.moreComing
        }
        saveChangeToken(token, for: zoneID)
    }

    private static func changeTokenKey(for zoneID: CKRecordZone.ID) -> String {
        "voxiverse.reportConversation.changeToken.\(zoneID.ownerName).\(zoneID.zoneName)"
    }

    private static func loadChangeToken(for zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
        guard let data = UserDefaults.standard.data(forKey: changeTokenKey(for: zoneID)) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }

    private static func saveChangeToken(_ token: CKServerChangeToken?, for zoneID: CKRecordZone.ID) {
        guard let token, let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else { return }
        UserDefaults.standard.set(data, forKey: changeTokenKey(for: zoneID))
    }

    private static func claimNotification(_ key: String) -> Bool {
        deduplicationLock.lock()
        defer { deduplicationLock.unlock() }
        guard !UserDefaults.standard.bool(forKey: key) else { return false }
        UserDefaults.standard.set(true, forKey: key)
        return true
    }

    private static func releaseNotification(_ key: String) {
        deduplicationLock.lock()
        UserDefaults.standard.removeObject(forKey: key)
        deduplicationLock.unlock()
    }

    private static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .ephemeral: return true
        case .provisional, .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied: return false
        @unknown default: return false
        }
    }

    private static func registerForRemoteNotifications() async {
        await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
    }
}

final class VoxiverseNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Task { await VoxiverseReportConversationNotificationManager.prepareNotifications() }
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Route on the zone, not the exact subscription-ID string. A CloudKit zone
        // push for ReportConversations is authoritative regardless of which
        // subscription (current or legacy/renamed) delivered it; requiring an exact
        // subscription-ID prefix silently drops real changes. The change-token +
        // dedup + reporter-only sender filter in processMessageChanges still prevent
        // historical replay and self-notification. Pushes for other zones (e.g.
        // SwiftData CloudKit mirroring) target a different zone and are ignored.
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
              let zoneID = (notification as? CKRecordZoneNotification)?.recordZoneID,
              zoneID.zoneName == ReportConversationCloudKitSchema.zoneName else {
            VoxiverseReportConversationNotificationManager.reportNotifLog("remote notification received but not a report-conversation zone push; ignoring")
            completionHandler(.noData)
            return
        }
        Task {
            let notified = await VoxiverseReportConversationNotificationManager.processMessageChanges(in: zoneID)
            completionHandler(notified ? .newData : .noData)
        }
    }
}
