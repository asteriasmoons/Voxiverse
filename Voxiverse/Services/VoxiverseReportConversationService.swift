//
//  VoxiverseReportConversationService.swift
//  Voxiverse
//

import CloudKit
import Combine
import Foundation

@MainActor
final class VoxiverseReportConversationService: ObservableObject {
    @Published private(set) var snapshot: ReportConversationSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    private let container: CKContainer

    init(container: CKContainer = CKContainer(identifier: ReportConversationCloudKitSchema.containerIdentifier)) {
        self.container = container
    }

    private struct ConversationPointer {
        let recordID: CKRecord.ID
    }

    func load(context: ReportConversationContext, markRead: Bool = false) async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await fetchSnapshot(context: context, markRead: markRead)
            snapshot = loaded
        } catch {
            snapshot = .notStarted(context: context)
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func sendStaffMessage(_ rawText: String, context: ReportConversationContext) async {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard !isSending else { return }

        isSending = true
        errorMessage = nil
        do {
            if let pointer = try await fetchConversationPointer(context: context) {
                let existing = try await fetchRecord(pointer.recordID, in: container.privateCloudDatabase)
                guard ReportConversationState(rawValue: existing.voxConversationString(ReportConversationCloudKitSchema.ConversationField.invitationState)) != .declined else {
                    throw ConversationError.declined
                }
                try await appendMessage(text, role: .staff, to: existing)
            } else {
                _ = try await createConversationRootAndShare(context: context, firstMessage: text)
            }
            snapshot = try await fetchSnapshot(context: context, markRead: true)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    static func fetchSummary(context: ReportConversationContext) async -> ReportConversationSnapshot {
        let service = VoxiverseReportConversationService()
        do {
            return try await service.fetchSnapshot(context: context, markRead: false)
        } catch {
            return .notStarted(context: context)
        }
    }

    private func fetchSnapshot(context: ReportConversationContext, markRead: Bool) async throws -> ReportConversationSnapshot {
        let database = container.privateCloudDatabase
        guard let pointer = try await fetchConversationPointer(context: context) else {
            return .notStarted(context: context)
        }

        let root = try await fetchRecord(pointer.recordID, in: database)

        if markRead {
            let now = Date()
            root[ReportConversationCloudKitSchema.ConversationField.staffUnreadCount] = 0 as CKRecordValue
            root[ReportConversationCloudKitSchema.ConversationField.staffLastReadAt] = now as CKRecordValue
            _ = try await database.modifyRecords(saving: [root], deleting: [], savePolicy: .changedKeys, atomically: true)
        }

        try await VoxiverseReportConversationNotificationManager.registerPrivateConversationNotifications(
            database: database,
            zoneID: root.recordID.zoneID
        )

        let messages = try await fetchMessages(from: root, in: database)
        return makeSnapshot(from: root, context: context, messages: messages)
    }

    private func fetchConversationPointer(context: ReportConversationContext) async throws -> ConversationPointer? {
        let publicReport = try await fetchPublicReport(context: context)
        let recordName = publicReport.voxConversationString(ReportConversationCloudKitSchema.PublicReportField.conversationRecordName)
        let zoneName = publicReport.voxConversationString(ReportConversationCloudKitSchema.PublicReportField.conversationZoneName)
        let zoneOwnerName = publicReport.voxConversationString(ReportConversationCloudKitSchema.PublicReportField.conversationZoneOwnerName)
        let shareURL = publicReport.voxConversationString(ReportConversationCloudKitSchema.PublicReportField.conversationShareURL)

        guard !recordName.isEmpty || !zoneName.isEmpty || !zoneOwnerName.isEmpty || !shareURL.isEmpty else {
            return nil
        }

        guard !recordName.isEmpty, !zoneName.isEmpty else {
            throw ConversationError.incompleteConversationPointer
        }

        let ownerName = zoneOwnerName.isEmpty ? CKCurrentUserDefaultName : zoneOwnerName
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
        return ConversationPointer(
            recordID: CKRecord.ID(recordName: recordName, zoneID: zoneID)
        )
    }

    private func createConversationRootAndShare(context: ReportConversationContext, firstMessage: String) async throws -> CKRecord {
        let publicReport = try await fetchPublicReport(context: context)
        guard let reporterRecordID = publicReport.creatorUserRecordID else {
            throw ConversationError.missingReporterIdentity
        }

        let participants = try await container.shareParticipants(forUserRecordIDs: [reporterRecordID])
        guard let participantResult = participants[reporterRecordID] else {
            throw ConversationError.missingReporterIdentity
        }
        let participant = try participantResult.get()
        participant.permission = .readWrite

        let database = container.privateCloudDatabase
        let zoneID = try await ensureConversationZone()
        let recordName = ReportConversationCloudKitSchema.deterministicConversationRecordName(
            sourceAppID: context.sourceAppID,
            reportID: context.reportID
        )
        let recordID = CKRecord.ID(recordName: recordName, zoneID: zoneID)
        let root = CKRecord(recordType: ReportConversationCloudKitSchema.RecordType.conversation, recordID: recordID)
        let now = Date()
        let staffRecordName = (try? await container.userRecordID().recordName) ?? ""
        let messageID = UUID().uuidString
        let messageRecordID = CKRecord.ID(recordName: "message-\(messageID)", zoneID: zoneID)
        let message = CKRecord(recordType: ReportConversationCloudKitSchema.RecordType.message, recordID: messageRecordID)
        message.parent = CKRecord.Reference(recordID: root.recordID, action: .none)
        message[ReportConversationCloudKitSchema.MessageField.messageID] = messageID as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.conversation] = CKRecord.Reference(recordID: root.recordID, action: .none)
        message[ReportConversationCloudKitSchema.MessageField.conversationRecordName] = root.recordID.recordName as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.senderRole] = ReportConversationSenderRole.staff.rawValue as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.body] = firstMessage as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.createdAt] = now as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.clientMessageID] = messageID as CKRecordValue

        root[ReportConversationCloudKitSchema.ConversationField.conversationID] = recordName as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.reportID] = context.reportID as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.sourceAppID] = context.sourceAppID as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.sourceAppName] = context.sourceAppName as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.reportType] = context.reportType as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.reportTitle] = context.reportTitle as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.reporterDisplayName] = context.reporterDisplayName as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.reporterUserRecordName] = reporterRecordID.recordName as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.staffUserRecordName] = staffRecordName as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.invitationState] = ReportConversationState.invited.rawValue as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.createdAt] = now as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.updatedAt] = now as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.invitedAt] = now as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.lastMessageAt] = now as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.lastMessageSenderRole] = ReportConversationSenderRole.staff.rawValue as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.messageRecordNames] = [messageRecordID.recordName] as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.reporterUnreadCount] = 1 as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.staffUnreadCount] = 0 as CKRecordValue

        let share = CKShare(rootRecord: root)
        share[CKShare.SystemFieldKey.title] = "Voxiverse Report Conversation" as CKRecordValue
        share.publicPermission = .none
        share.addParticipant(participant)

        let saveResult = try await database.modifyRecords(saving: [root, share, message], deleting: [], savePolicy: .ifServerRecordUnchanged, atomically: true)
        try throwIfAnySaveFailed(saveResult.saveResults)
        guard
            let shareRecordResult = saveResult.saveResults[share.recordID],
            let savedShare = try shareRecordResult.get() as? CKShare,
            let shareURL = savedShare.url
        else {
            throw ConversationError.shareURLUnavailable
        }

        root[ReportConversationCloudKitSchema.ConversationField.shareURL] = shareURL.absoluteString as CKRecordValue
        let rootURLSave = try await database.modifyRecords(saving: [root], deleting: [], savePolicy: .changedKeys, atomically: true)
        try throwIfAnySaveFailed(rootURLSave.saveResults)

        try await updatePublicReportConversationPointer(
            publicReport,
            conversationRecordID: recordID,
            shareURL: shareURL,
            state: .invited,
            timestamp: now
        )

        return try await fetchRecord(recordID, in: database)
    }

    private func appendMessage(_ text: String, role: ReportConversationSenderRole, to root: CKRecord) async throws {
        let database = container.privateCloudDatabase
        let now = Date()
        let messageID = UUID().uuidString
        let messageRecordID = CKRecord.ID(recordName: "message-\(messageID)", zoneID: root.recordID.zoneID)
        let message = CKRecord(recordType: ReportConversationCloudKitSchema.RecordType.message, recordID: messageRecordID)
        message.parent = CKRecord.Reference(recordID: root.recordID, action: .none)
        message[ReportConversationCloudKitSchema.MessageField.messageID] = messageID as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.conversation] = CKRecord.Reference(recordID: root.recordID, action: .none)
        message[ReportConversationCloudKitSchema.MessageField.conversationRecordName] = root.recordID.recordName as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.senderRole] = role.rawValue as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.body] = text as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.createdAt] = now as CKRecordValue
        message[ReportConversationCloudKitSchema.MessageField.clientMessageID] = messageID as CKRecordValue

        var names = root[ReportConversationCloudKitSchema.ConversationField.messageRecordNames] as? [String] ?? []
        if !names.contains(messageRecordID.recordName) {
            names.append(messageRecordID.recordName)
        }
        root[ReportConversationCloudKitSchema.ConversationField.messageRecordNames] = names as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.lastMessageAt] = now as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.lastMessageSenderRole] = role.rawValue as CKRecordValue
        root[ReportConversationCloudKitSchema.ConversationField.updatedAt] = now as CKRecordValue

        if role == .staff {
            root[ReportConversationCloudKitSchema.ConversationField.reporterUnreadCount] = (root.voxConversationInt(ReportConversationCloudKitSchema.ConversationField.reporterUnreadCount) + 1) as CKRecordValue
        } else {
            root[ReportConversationCloudKitSchema.ConversationField.staffUnreadCount] = (root.voxConversationInt(ReportConversationCloudKitSchema.ConversationField.staffUnreadCount) + 1) as CKRecordValue
        }

        let result = try await database.modifyRecords(saving: [root, message], deleting: [], savePolicy: .changedKeys, atomically: true)
        try throwIfAnySaveFailed(result.saveResults)

        let shareURLString = root.voxConversationString(ReportConversationCloudKitSchema.ConversationField.shareURL)
        if !shareURLString.isEmpty, let shareURL = URL(string: shareURLString) {
            try await updatePublicReportConversationPointer(
                try await fetchPublicReportByID(root.voxConversationString(ReportConversationCloudKitSchema.ConversationField.reportID)),
                conversationRecordID: root.recordID,
                shareURL: shareURL,
                state: ReportConversationState(rawValue: root.voxConversationString(ReportConversationCloudKitSchema.ConversationField.invitationState)) ?? .invited,
                timestamp: now
            )
        }
    }

    private func fetchMessages(from root: CKRecord, in database: CKDatabase) async throws -> [ReportConversationMessage] {
        let names = root[ReportConversationCloudKitSchema.ConversationField.messageRecordNames] as? [String] ?? []
        guard !names.isEmpty else { return [] }
        let ids = names.map { CKRecord.ID(recordName: $0, zoneID: root.recordID.zoneID) }
        let results = try await database.records(for: ids)
        return ids.compactMap { id in
            guard let result = results[id], let record = try? result.get() else { return nil }
            return ReportConversationMessage(
                id: record.voxConversationString(ReportConversationCloudKitSchema.MessageField.messageID, fallback: record.recordID.recordName),
                senderRole: ReportConversationSenderRole(rawValue: record.voxConversationString(ReportConversationCloudKitSchema.MessageField.senderRole)) ?? .unknown,
                body: record.voxConversationString(ReportConversationCloudKitSchema.MessageField.body),
                createdAt: record.voxConversationDate(ReportConversationCloudKitSchema.MessageField.createdAt) ?? record.creationDate ?? Date(),
                creatorRecordName: record.creatorUserRecordID?.recordName ?? ""
            )
        }
        .sorted { $0.createdAt < $1.createdAt }
    }

    private func makeSnapshot(from root: CKRecord, context: ReportConversationContext, messages: [ReportConversationMessage]) -> ReportConversationSnapshot {
        ReportConversationSnapshot(
            id: root.voxConversationString(ReportConversationCloudKitSchema.ConversationField.conversationID, fallback: root.recordID.recordName),
            context: context,
            state: ReportConversationState(rawValue: root.voxConversationString(ReportConversationCloudKitSchema.ConversationField.invitationState)) ?? .notStarted,
            recordID: root.recordID,
            shareURL: URL(string: root.voxConversationString(ReportConversationCloudKitSchema.ConversationField.shareURL)),
            createdAt: root.voxConversationDate(ReportConversationCloudKitSchema.ConversationField.createdAt) ?? root.creationDate,
            updatedAt: root.voxConversationDate(ReportConversationCloudKitSchema.ConversationField.updatedAt) ?? root.modificationDate,
            invitedAt: root.voxConversationDate(ReportConversationCloudKitSchema.ConversationField.invitedAt),
            acceptedAt: root.voxConversationDate(ReportConversationCloudKitSchema.ConversationField.acceptedAt),
            declinedAt: root.voxConversationDate(ReportConversationCloudKitSchema.ConversationField.declinedAt),
            reporterUnreadCount: root.voxConversationInt(ReportConversationCloudKitSchema.ConversationField.reporterUnreadCount),
            staffUnreadCount: root.voxConversationInt(ReportConversationCloudKitSchema.ConversationField.staffUnreadCount),
            messages: messages
        )
    }

    private func updatePublicReportConversationPointer(
        _ publicReport: CKRecord,
        conversationRecordID: CKRecord.ID,
        shareURL: URL,
        state: ReportConversationState,
        timestamp: Date
    ) async throws {
        publicReport[ReportConversationCloudKitSchema.PublicReportField.conversationRecordName] = conversationRecordID.recordName as CKRecordValue
        publicReport[ReportConversationCloudKitSchema.PublicReportField.conversationZoneName] = conversationRecordID.zoneID.zoneName as CKRecordValue
        publicReport[ReportConversationCloudKitSchema.PublicReportField.conversationZoneOwnerName] = conversationRecordID.zoneID.ownerName as CKRecordValue
        publicReport[ReportConversationCloudKitSchema.PublicReportField.conversationShareURL] = shareURL.absoluteString as CKRecordValue
        publicReport[ReportConversationCloudKitSchema.PublicReportField.conversationState] = state.rawValue as CKRecordValue
        publicReport[ReportConversationCloudKitSchema.PublicReportField.conversationUpdatedAt] = timestamp as CKRecordValue
        publicReport[ReportConversationCloudKitSchema.PublicReportField.conversationLastMessageAt] = timestamp as CKRecordValue

        let result = try await container.publicCloudDatabase.modifyRecords(saving: [publicReport], deleting: [], savePolicy: .changedKeys, atomically: true)
        try throwIfAnySaveFailed(result.saveResults)
    }

    private func fetchPublicReport(context: ReportConversationContext) async throws -> CKRecord {
        try await fetchPublicReportByID(context.reportID)
    }

    private func fetchPublicReportByID(_ reportID: String) async throws -> CKRecord {
        try await fetchRecord(CKRecord.ID(recordName: reportID), in: container.publicCloudDatabase)
    }

    private func ensureConversationZone() async throws -> CKRecordZone.ID {
        let database = container.privateCloudDatabase
        let zoneID = privateZoneID()
        let results = try await database.recordZones(for: [zoneID])
        if let result = results[zoneID], (try? result.get()) != nil {
            return zoneID
        }

        let zone = CKRecordZone(zoneID: zoneID)
        let saveResult = try await database.modifyRecordZones(saving: [zone], deleting: [])
        if let result = saveResult.saveResults[zoneID] {
            _ = try result.get()
        }
        return zoneID
    }

    private func privateZoneID() -> CKRecordZone.ID {
        CKRecordZone.ID(zoneName: ReportConversationCloudKitSchema.zoneName, ownerName: CKCurrentUserDefaultName)
    }

    private func fetchRecord(_ recordID: CKRecord.ID, in database: CKDatabase) async throws -> CKRecord {
        let results = try await database.records(for: [recordID])
        guard let result = results[recordID] else { throw ConversationError.recordNotFound }
        return try result.get()
    }

    private func throwIfAnySaveFailed(_ results: [CKRecord.ID: Result<CKRecord, any Error>]) throws {
        for result in results.values {
            if case .failure(let error) = result {
                throw error
            }
        }
    }

    enum ConversationError: LocalizedError {
        case missingReporterIdentity
        case shareURLUnavailable
        case recordNotFound
        case declined
        case incompleteConversationPointer

        var errorDescription: String? {
            switch self {
            case .missingReporterIdentity:
                return "Voxiverse could not securely identify the CloudKit account that submitted this report, so a private conversation was not created."
            case .shareURLUnavailable:
                return "CloudKit did not return a private invitation URL for this conversation."
            case .recordNotFound:
                return "No private conversation exists for this report yet."
            case .declined:
                return "The reporter declined this private conversation."
            case .incompleteConversationPointer:
                return "This report has incomplete private conversation metadata in CloudKit."
            }
        }
    }
}
