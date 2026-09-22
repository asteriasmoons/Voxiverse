//
//  ReportConversationCloudKitSchema.swift
//  Voxiverse
//

import CloudKit
import Foundation

enum ReportConversationState: String, CaseIterable, Codable, Hashable {
    case notStarted
    case invited
    case accepted
    case declined
}

enum ReportConversationSenderRole: String, Codable, Hashable {
    case staff
    case reporter
    case unknown
}

struct ReportConversationContext: Identifiable, Hashable {
    let id: String
    let reportID: String
    let sourceAppID: String
    let sourceAppName: String
    let reportType: String
    let reportTitle: String
    let reporterDisplayName: String
    let conversationRecordName: String
    let conversationZoneName: String
    let conversationZoneOwnerName: String

    init(report: VoxiverseReport, app: VoxiverseManagedApp?, conversation: VoxiverseConversation? = nil) {
        self.id = report.reportID
        self.reportID = report.reportID
        self.sourceAppID = report.appID
        self.sourceAppName = app?.name ?? report.app?.name ?? report.appID
        self.reportType = report.reportType.rawValue
        self.reportTitle = report.title
        self.reporterDisplayName = report.reporter
        self.conversationRecordName = conversation?.conversationRecordName ?? ""
        self.conversationZoneName = conversation?.conversationZoneName ?? ""
        self.conversationZoneOwnerName = conversation?.conversationZoneOwnerName ?? ""
    }

    init(request: VoxiverseFeatureRequest, app: VoxiverseManagedApp?, conversation: VoxiverseConversation? = nil) {
        self.id = request.id
        self.reportID = request.id
        self.sourceAppID = request.appID
        self.sourceAppName = app?.name ?? request.app?.name ?? request.appID
        self.reportType = "Feature Request"
        self.reportTitle = request.title
        self.reporterDisplayName = request.submitter
        self.conversationRecordName = conversation?.conversationRecordName ?? ""
        self.conversationZoneName = conversation?.conversationZoneName ?? ""
        self.conversationZoneOwnerName = conversation?.conversationZoneOwnerName ?? ""
    }
}

struct ReportConversationMessage: Identifiable, Hashable {
    let id: String
    let senderRole: ReportConversationSenderRole
    let body: String
    let createdAt: Date
    let creatorRecordName: String
    let attachments: [ReportConversationAttachment]
    var deliveryState: ReportConversationDeliveryState = .sent

    var isFromStaff: Bool {
        senderRole == .staff
    }
}

enum ReportConversationDeliveryState: String, Codable, Hashable {
    case sending
    case sent
    case failed
}

struct ReportConversationAttachment: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let typeIdentifier: String
    let data: Data

    init(id: UUID = UUID(), name: String, typeIdentifier: String, data: Data) {
        self.id = id
        self.name = name
        self.typeIdentifier = typeIdentifier
        self.data = data
    }
}

struct ReportConversationSnapshot: Identifiable, Hashable {
    let id: String
    let context: ReportConversationContext
    let state: ReportConversationState
    let acceptsReplies: Bool
    let recordID: CKRecord.ID?
    let shareURL: URL?
    let createdAt: Date?
    let updatedAt: Date?
    let invitedAt: Date?
    let acceptedAt: Date?
    let declinedAt: Date?
    let reporterUnreadCount: Int
    let staffUnreadCount: Int
    let messages: [ReportConversationMessage]

    static func notStarted(context: ReportConversationContext) -> ReportConversationSnapshot {
        ReportConversationSnapshot(
            id: context.id,
            context: context,
            state: .notStarted,
            acceptsReplies: true,
            recordID: nil,
            shareURL: nil,
            createdAt: nil,
            updatedAt: nil,
            invitedAt: nil,
            acceptedAt: nil,
            declinedAt: nil,
            reporterUnreadCount: 0,
            staffUnreadCount: 0,
            messages: []
        )
    }
}

enum ReportConversationCloudKitSchema {
    static let containerIdentifier = "iCloud.im.lystaria.Voxiverse"
    static let zoneName = "ReportConversations"

    enum RecordType {
        static let report = "Report"
        static let conversation = "ReportConversation"
        static let message = "ReportConversationMessage"
    }

    enum ConversationField {
        static let conversationID = "conversationID"
        static let reportID = "reportID"
        static let sourceAppID = "sourceAppID"
        static let sourceAppName = "sourceAppName"
        static let reportType = "reportType"
        static let reportTitle = "reportTitle"
        static let reporterDisplayName = "reporterDisplayName"
        static let reporterUserRecordName = "reporterUserRecordName"
        static let staffUserRecordName = "staffUserRecordName"
        static let invitationState = "invitationState"
        static let acceptsReplies = "acceptsReplies"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
        static let invitedAt = "invitedAt"
        static let acceptedAt = "acceptedAt"
        static let declinedAt = "declinedAt"
        static let lastMessageAt = "lastMessageAt"
        static let lastMessageSenderRole = "lastMessageSenderRole"
        static let messageRecordNames = "messageRecordNames"
        static let reporterUnreadCount = "reporterUnreadCount"
        static let staffUnreadCount = "staffUnreadCount"
        static let reporterLastReadAt = "reporterLastReadAt"
        static let staffLastReadAt = "staffLastReadAt"
        static let shareURL = "conversationShareURL"
    }

    enum MessageField {
        static let messageID = "messageID"
        static let conversation = "conversation"
        static let conversationRecordName = "conversationRecordName"
        static let senderRole = "senderRole"
        static let body = "body"
        static let createdAt = "createdAt"
        static let clientMessageID = "clientMessageID"
        static let attachmentCount = "attachmentCount"
        static func attachment(_ index: Int) -> String { "attachment\(index)" }
        static func attachmentName(_ index: Int) -> String { "attachment\(index)Name" }
        static func attachmentType(_ index: Int) -> String { "attachment\(index)Type" }
    }

    enum PublicReportField {
        static let conversationRecordName = "conversationRecordName"
        static let conversationZoneName = "conversationZoneName"
        static let conversationZoneOwnerName = "conversationZoneOwnerName"
        static let conversationShareURL = "conversationShareURL"
        static let conversationState = "conversationState"
        static let conversationUpdatedAt = "conversationUpdatedAt"
        static let conversationLastMessageAt = "conversationLastMessageAt"
    }

    static func deterministicConversationRecordName(sourceAppID: String, reportID: String) -> String {
        let raw = "conversation-\(sourceAppID)-\(reportID)"
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }.reduce("") { $0 + String($1) }
    }
}

extension CKRecord {
    func voxConversationString(_ key: CKRecord.FieldKey, fallback: String = "") -> String {
        self[key] as? String ?? fallback
    }

    func voxConversationDate(_ key: CKRecord.FieldKey) -> Date? {
        self[key] as? Date
    }

    func voxConversationInt(_ key: CKRecord.FieldKey) -> Int {
        if let int = self[key] as? Int { return int }
        if let number = self[key] as? NSNumber { return number.intValue }
        return 0
    }
}
