import Foundation
import SwiftData

enum VoxiverseFeatureRequestStatus: String, CaseIterable, Codable, Hashable {
    case new = "New"
    case considering = "Considering"
    case planned = "Planned"
    case inProgress = "In Progress"
    case shipped = "Shipped"
    case declined = "Declined"
    case closed = "Closed"
}

@Model
final class VoxiverseFeatureRequest: Identifiable {
    var id: String = UUID().uuidString
    var appID: String = ""
    var title: String = ""
    var requestDescription: String = ""
    var category: String = ""
    var featureType: String = ""
    var featureImportance: String = ""
    var intendedAudience: String = ""
    var featureDescription: String = ""
    var imaginedWorkflow: String = ""
    var desiredLocation: String = ""
    var relatedExistingFeature: String = ""
    var problemAddressed: String = ""
    var desiredResult: String = ""
    var requiresSavedData: String = ""
    var needsNotifications: String = ""
    var needsSharing: String = ""
    var needsAI: String = ""
    var additionalDetails: String = ""
    var deviceModel: String = ""
    var iOSVersion: String = ""
    var appVersion: String = ""
    var buildNumber: String = ""
    var bundleIdentifier: String = ""
    var screenName: String = ""
    var locale: String = ""
    var timeZone: String = ""
    var statusRawValue: String = VoxiverseFeatureRequestStatus.new.rawValue
    var requestCount: Int = 0
    var createdDate: Date = Date.now
    var updatedDate: Date = Date.now
    var submitter: String = ""
    var internalNotes: String = ""
    var app: VoxiverseManagedApp?

    @Relationship(deleteRule: .cascade, inverse: \VoxiverseReportAttachment.featureRequest)
    var attachments: [VoxiverseReportAttachment]? = []

    var description: String { requestDescription }

    var status: VoxiverseFeatureRequestStatus {
        get { VoxiverseFeatureRequestStatus(rawValue: statusRawValue) ?? .new }
        set { statusRawValue = newValue.rawValue }
    }

    var allowedStatuses: [VoxiverseFeatureRequestStatus] {
        VoxiverseFeatureRequestStatus.allCases
    }

    init(
        id: String = UUID().uuidString,
        appID: String,
        title: String,
        description: String,
        category: String = "",
        featureType: String = "",
        featureImportance: String = "",
        intendedAudience: String = "",
        featureDescription: String = "",
        imaginedWorkflow: String = "",
        desiredLocation: String = "",
        relatedExistingFeature: String = "",
        problemAddressed: String = "",
        desiredResult: String = "",
        requiresSavedData: String = "",
        needsNotifications: String = "",
        needsSharing: String = "",
        needsAI: String = "",
        additionalDetails: String = "",
        deviceModel: String = "",
        iOSVersion: String = "",
        appVersion: String = "",
        buildNumber: String = "",
        bundleIdentifier: String = "",
        screenName: String = "",
        locale: String = "",
        timeZone: String = "",
        status: VoxiverseFeatureRequestStatus,
        requestCount: Int,
        createdDate: Date,
        updatedDate: Date,
        submitter: String,
        internalNotes: String,
        attachments: [VoxiverseReportAttachment] = []
    ) {
        self.id = id
        self.appID = appID
        self.title = title
        self.requestDescription = description
        self.category = category
        self.featureType = featureType
        self.featureImportance = featureImportance
        self.intendedAudience = intendedAudience
        self.featureDescription = featureDescription
        self.imaginedWorkflow = imaginedWorkflow
        self.desiredLocation = desiredLocation
        self.relatedExistingFeature = relatedExistingFeature
        self.problemAddressed = problemAddressed
        self.desiredResult = desiredResult
        self.requiresSavedData = requiresSavedData
        self.needsNotifications = needsNotifications
        self.needsSharing = needsSharing
        self.needsAI = needsAI
        self.additionalDetails = additionalDetails
        self.deviceModel = deviceModel
        self.iOSVersion = iOSVersion
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.bundleIdentifier = bundleIdentifier
        self.screenName = screenName
        self.locale = locale
        self.timeZone = timeZone
        self.statusRawValue = status.rawValue
        self.requestCount = requestCount
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.submitter = submitter
        self.internalNotes = internalNotes
        self.attachments = attachments
    }
}
