import Foundation
import SwiftData

enum VoxiverseReportType: String, CaseIterable, Codable, Hashable {
    case bugReport = "Bug Report"
    case betaFeedback = "Beta Feedback"
    case generalFeedback = "General Feedback"
}

enum VoxiversePriority: String, CaseIterable, Codable, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

enum VoxiverseReportStatus: String, CaseIterable, Codable, Hashable {
    case new = "New"
    case inProgress = "In Progress"
    case resolved = "Resolved"
    case closed = "Closed"
}

@Model
final class VoxiverseReport: Identifiable {
    var id: String = UUID().uuidString
    var reportID: String = ""
    var appID: String = ""
    var title: String = ""
    var reportDescription: String = ""
    var expectedBehavior: String = ""
    var stepsToReproduce: [String] = []
    var reportTypeRawValue: String = VoxiverseReportType.bugReport.rawValue
    var priorityRawValue: String = VoxiversePriority.medium.rawValue
    var statusRawValue: String = VoxiverseReportStatus.new.rawValue
    var submittedDate: Date = Date.now
    var reporter: String = ""
    var deviceModel: String = ""
    var iOSVersion: String = ""
    var appVersion: String = ""
    var buildNumber: String = ""
    var screenName: String = ""
    var internalNotes: String = ""
    var app: VoxiverseManagedApp?

    @Relationship(deleteRule: .cascade, inverse: \VoxiverseReportAttachment.report)
    var attachments: [VoxiverseReportAttachment]? = []

    var description: String { reportDescription }

    var reportType: VoxiverseReportType {
        get { VoxiverseReportType(rawValue: reportTypeRawValue) ?? .bugReport }
        set { reportTypeRawValue = newValue.rawValue }
    }

    var priority: VoxiversePriority {
        get { VoxiversePriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    var status: VoxiverseReportStatus {
        get { VoxiverseReportStatus(rawValue: statusRawValue) ?? .new }
        set { statusRawValue = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        reportID: String,
        appID: String,
        title: String,
        description: String,
        expectedBehavior: String,
        stepsToReproduce: [String],
        reportType: VoxiverseReportType,
        priority: VoxiversePriority,
        status: VoxiverseReportStatus,
        submittedDate: Date,
        reporter: String,
        deviceModel: String,
        iOSVersion: String,
        appVersion: String,
        buildNumber: String,
        screenName: String,
        internalNotes: String,
        attachments: [VoxiverseReportAttachment]
    ) {
        self.id = id
        self.reportID = reportID
        self.appID = appID
        self.title = title
        self.reportDescription = description
        self.expectedBehavior = expectedBehavior
        self.stepsToReproduce = stepsToReproduce
        self.reportTypeRawValue = reportType.rawValue
        self.priorityRawValue = priority.rawValue
        self.statusRawValue = status.rawValue
        self.submittedDate = submittedDate
        self.reporter = reporter
        self.deviceModel = deviceModel
        self.iOSVersion = iOSVersion
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.screenName = screenName
        self.internalNotes = internalNotes
        self.attachments = attachments
    }
}
