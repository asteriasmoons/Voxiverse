import Foundation
import SwiftData

@Model
final class VoxiverseActivity: Identifiable {
    var id: String = UUID().uuidString
    var activityType: String = ""
    var title: String = ""
    var detail: String = ""
    var date: Date = Date.now
    var assetName: String = "document"
    var relatedAppID: String = ""
    var relatedReportID: String = ""
    var relatedRequestID: String = ""
    var dedupeKey: String = ""

    init(
        id: String = UUID().uuidString,
        activityType: String,
        title: String,
        detail: String,
        date: Date,
        assetName: String,
        relatedAppID: String = "",
        relatedReportID: String = "",
        relatedRequestID: String = "",
        dedupeKey: String
    ) {
        self.id = id
        self.activityType = activityType
        self.title = title
        self.detail = detail
        self.date = date
        self.assetName = assetName
        self.relatedAppID = relatedAppID
        self.relatedReportID = relatedReportID
        self.relatedRequestID = relatedRequestID
        self.dedupeKey = dedupeKey
    }
}

@MainActor
enum VoxiverseActivityStore {
    static func recordReceived(
        for report: VoxiverseReport,
        appName: String,
        in modelContext: ModelContext
    ) throws {
        let title = report.reportType == .betaFeedback ? "Beta Feedback received" : "Report received"
        let assetName = report.reportType == .betaFeedback ? "chatsparkle" : "bug"
        try insertIfNeeded(
            VoxiverseActivity(
                activityType: "received",
                title: title,
                detail: "\(appName) · \(report.title)",
                date: report.submittedDate,
                assetName: assetName,
                relatedAppID: report.appID,
                relatedReportID: report.id,
                dedupeKey: "received-report-\(report.reportID)"
            ),
            into: modelContext
        )
    }

    static func recordStatusChange(
        for report: VoxiverseReport,
        from oldStatus: VoxiverseReportStatus,
        to newStatus: VoxiverseReportStatus,
        appName: String,
        dedupeKey: String,
        in modelContext: ModelContext
    ) throws {
        let title: String
        switch report.reportType {
        case .bugReport where newStatus == .resolved:
            title = "Bug resolved"
        case .betaFeedback where newStatus == .reviewed:
            title = "Beta Feedback reviewed"
        case _ where newStatus == .closed:
            title = report.reportType == .betaFeedback ? "Beta Feedback closed" : "Report closed"
        case .betaFeedback:
            title = "Beta Feedback status changed"
        default:
            title = "Report status changed"
        }

        try insertIfNeeded(
            VoxiverseActivity(
                activityType: "statusChanged",
                title: title,
                detail: "\(appName) · \(oldStatus.rawValue) → \(newStatus.rawValue)",
                date: Date.now,
                assetName: newStatus == .resolved || newStatus == .reviewed || newStatus == .closed ? "checkwavy" : "clockwavy",
                relatedAppID: report.appID,
                relatedReportID: report.id,
                dedupeKey: dedupeKey
            ),
            into: modelContext
        )
    }

    static func recordReceived(
        for request: VoxiverseFeatureRequest,
        appName: String,
        in modelContext: ModelContext
    ) throws {
        try insertIfNeeded(
            VoxiverseActivity(
                activityType: "received",
                title: "Feature Request received",
                detail: "\(appName) · \(request.title)",
                date: request.createdDate,
                assetName: "bulbxoxo",
                relatedAppID: request.appID,
                relatedRequestID: request.id,
                dedupeKey: "received-request-\(request.id)"
            ),
            into: modelContext
        )
    }

    static func recordStatusChange(
        for request: VoxiverseFeatureRequest,
        from oldStatus: VoxiverseFeatureRequestStatus,
        to newStatus: VoxiverseFeatureRequestStatus,
        appName: String,
        dedupeKey: String,
        in modelContext: ModelContext
    ) throws {
        try insertIfNeeded(
            VoxiverseActivity(
                activityType: "statusChanged",
                title: "Feature Request status changed",
                detail: "\(appName) · \(oldStatus.rawValue) → \(newStatus.rawValue)",
                date: Date.now,
                assetName: newStatus == .closed || newStatus == .shipped ? "checkwavy" : "clockwavy",
                relatedAppID: request.appID,
                relatedRequestID: request.id,
                dedupeKey: dedupeKey
            ),
            into: modelContext
        )
    }

    private static func insertIfNeeded(_ activity: VoxiverseActivity, into modelContext: ModelContext) throws {
        let key = activity.dedupeKey
        let descriptor = FetchDescriptor<VoxiverseActivity>(
            predicate: #Predicate { $0.dedupeKey == key }
        )
        guard try modelContext.fetch(descriptor).isEmpty else { return }
        modelContext.insert(activity)
    }
}
