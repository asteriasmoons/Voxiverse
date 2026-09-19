import Foundation
import SwiftData

enum VoxiverseReportType: String, CaseIterable, Codable, Hashable {
    case bugReport = "Bug Report"
    case betaFeedback = "Beta Feedback"
    case generalFeedback = "General Feedback"
    case featureRequest = "Feature Request"
}

enum VoxiversePriority: String, CaseIterable, Codable, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

enum VoxiverseReportStatus: String, CaseIterable, Codable, Hashable {
    case new = "New"
    case reviewing = "Reviewing"
    case inProgress = "In Progress"
    case resolved = "Resolved"
    case reviewed = "Reviewed"
    case actionNeeded = "Action Needed"
    case closed = "Closed"
}

@Model
final class VoxiverseReport: Identifiable {
    var id: String = UUID().uuidString
    var reportID: String = ""
    var appID: String = ""
    var title: String = ""
    var reportDescription: String = ""
    var category: String = ""
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
    var overallExperience: String = ""
    var testedWhat: String = ""
    var workedWell: String = ""
    var couldBeBetter: String = ""
    var anythingUnexpected: String = ""
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

    var allowedStatuses: [VoxiverseReportStatus] {
        reportType == .betaFeedback
            ? [.new, .reviewed, .actionNeeded, .closed]
            : [.new, .reviewing, .inProgress, .resolved, .closed]
    }

    var countsAsOpen: Bool {
        switch reportType {
        case .bugReport:
            [.new, .reviewing, .inProgress].contains(status)
        case .betaFeedback:
            [.new, .actionNeeded].contains(status)
        case .generalFeedback, .featureRequest:
            false
        }
    }

    var requiresAttention: Bool {
        switch reportType {
        case .bugReport:
            status == .new || status == .reviewing ||
                ((priority == .high || priority == .critical) && status != .resolved && status != .closed)
        case .betaFeedback:
            status == .new || status == .actionNeeded
        case .generalFeedback, .featureRequest:
            false
        }
    }

    init(
        id: String = UUID().uuidString,
        reportID: String,
        appID: String,
        title: String,
        description: String,
        category: String = "",
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
        overallExperience: String = "",
        testedWhat: String = "",
        workedWell: String = "",
        couldBeBetter: String = "",
        anythingUnexpected: String = "",
        attachments: [VoxiverseReportAttachment]
    ) {
        self.id = id
        self.reportID = reportID
        self.appID = appID
        self.title = title
        self.reportDescription = description
        self.category = category
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
        self.overallExperience = overallExperience
        self.testedWhat = testedWhat
        self.workedWell = workedWell
        self.couldBeBetter = couldBeBetter
        self.anythingUnexpected = anythingUnexpected
        self.attachments = attachments
    }
}
