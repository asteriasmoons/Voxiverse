import Foundation
import SwiftData

enum VoxiverseAppStatus: String, CaseIterable, Codable, Hashable {
    case active
    case beta
    case development
    case archived

    var title: String { rawValue.capitalized }
}

@Model
final class VoxiverseManagedApp: Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var appDescription: String = ""
    var version: String = ""
    var buildNumber: String = ""
    var statusRawValue: String = VoxiverseAppStatus.active.rawValue
    var bundleIdentifier: String = ""
    var platform: String = ""
    var iconAssetName: String = "appsphone"
    var openReportCount: Int = 0
    var featureRequestCount: Int = 0
    var betaBuildCount: Int = 0
    var sortOrder: Int = 0
    var createdDate: Date = Date.now
    var updatedDate: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \VoxiverseReport.app)
    var reports: [VoxiverseReport]? = []

    @Relationship(deleteRule: .nullify, inverse: \VoxiverseFeatureRequest.app)
    var featureRequests: [VoxiverseFeatureRequest]? = []

    var description: String { appDescription }

    var status: VoxiverseAppStatus {
        get { VoxiverseAppStatus(rawValue: statusRawValue) ?? .active }
        set { statusRawValue = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        version: String,
        buildNumber: String,
        status: VoxiverseAppStatus,
        bundleIdentifier: String,
        platform: String,
        iconAssetName: String,
        openReportCount: Int,
        featureRequestCount: Int,
        betaBuildCount: Int,
        sortOrder: Int,
        createdDate: Date,
        updatedDate: Date
    ) {
        self.id = id
        self.name = name
        self.appDescription = description
        self.version = version
        self.buildNumber = buildNumber
        self.statusRawValue = status.rawValue
        self.bundleIdentifier = bundleIdentifier
        self.platform = platform
        self.iconAssetName = iconAssetName
        self.openReportCount = openReportCount
        self.featureRequestCount = featureRequestCount
        self.betaBuildCount = betaBuildCount
        self.sortOrder = sortOrder
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }
}
