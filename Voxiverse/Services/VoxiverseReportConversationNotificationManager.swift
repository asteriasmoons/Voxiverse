//
//  VoxiverseReportConversationNotificationManager.swift
//  Voxiverse
//

import CloudKit
import Foundation
import UIKit
import UserNotifications

enum VoxiverseReportConversationNotificationManager {
    static func registerPrivateConversationNotifications(database: CKDatabase, zoneID: CKRecordZone.ID) async throws {
        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let subscriptionID = "voxiverse-report-conversations-\(zoneID.zoneName)"
        if let existing = try? await database.subscriptions(for: [subscriptionID]),
           existing[subscriptionID] != nil {
            return
        }

        let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: subscriptionID)
        let info = CKSubscription.NotificationInfo()
        info.alertBody = "A reporter replied to a private report conversation."
        info.shouldBadge = true
        subscription.notificationInfo = info
        _ = try await database.modifySubscriptions(saving: [subscription], deleting: [])
    }

    private static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return true
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
}
