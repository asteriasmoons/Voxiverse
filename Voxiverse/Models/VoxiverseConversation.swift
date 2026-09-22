import Foundation
import SwiftData

enum VoxiverseConversationSourceKind: String, Codable, Hashable {
    case report
    case featureRequest
}

@Model
final class VoxiverseConversation: Identifiable {
    var id: String = ""
    var reportID: String = ""
    var sourceRecordID: String = ""
    var sourceKindRawValue: String = VoxiverseConversationSourceKind.report.rawValue
    var appID: String = ""
    var appName: String = ""
    var reportType: String = ""
    var reportTitle: String = ""
    var reporterDisplayName: String = ""
    var conversationRecordName: String = ""
    var conversationZoneName: String = ""
    var conversationZoneOwnerName: String = ""
    var conversationStateRawValue: String = ReportConversationState.notStarted.rawValue
    var lastActivityAt: Date = Foundation.Date.distantPast
    var isPinned: Bool = false

    var sourceKind: VoxiverseConversationSourceKind {
        get { VoxiverseConversationSourceKind(rawValue: sourceKindRawValue) ?? .report }
        set { sourceKindRawValue = newValue.rawValue }
    }

    init(
        id: String,
        reportID: String,
        sourceRecordID: String,
        sourceKind: VoxiverseConversationSourceKind,
        appID: String,
        appName: String,
        reportType: String,
        reportTitle: String,
        reporterDisplayName: String,
        conversationRecordName: String,
        conversationZoneName: String,
        conversationZoneOwnerName: String,
        conversationState: ReportConversationState,
        lastActivityAt: Date,
        isPinned: Bool = false
    ) {
        self.id = id
        self.reportID = reportID
        self.sourceRecordID = sourceRecordID
        self.sourceKindRawValue = sourceKind.rawValue
        self.appID = appID
        self.appName = appName
        self.reportType = reportType
        self.reportTitle = reportTitle
        self.reporterDisplayName = reporterDisplayName
        self.conversationRecordName = conversationRecordName
        self.conversationZoneName = conversationZoneName
        self.conversationZoneOwnerName = conversationZoneOwnerName
        self.conversationStateRawValue = conversationState.rawValue
        self.lastActivityAt = lastActivityAt
        self.isPinned = isPinned
    }
}
