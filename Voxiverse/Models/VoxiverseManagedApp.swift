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

    // Placeholder links for now — set real per-app URLs in SampleData.swift
    // (or change these defaults) once available.
    var githubURL: String = "https://github.com"
    var testFlightURL: String = "https://testflight.apple.com"
    var appStoreURL: String = "https://apps.apple.com"
    var websiteURL: String = "https://example.com"

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
        updatedDate: Date,
        githubURL: String = "https://github.com",
        testFlightURL: String = "https://testflight.apple.com",
        appStoreURL: String = "https://apps.apple.com",
        websiteURL: String = "https://example.com"
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
        self.githubURL = githubURL
        self.testFlightURL = testFlightURL
        self.appStoreURL = appStoreURL
        self.websiteURL = websiteURL
    }
}

enum VoxiverseAppIdentity {
    static func canonicalID(_ value: String) -> String {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "asterium", "im.lystaria.asterium":
            return "sterium"
        case "lumey", "loomey", "im.lystaria.lumey", "im.lystaria.loomey":
            return "loomey"
        case "markly", "im.lystaria.markly":
            return "markly"
        default:
            return normalized
        }
    }
}

extension Array where Element == VoxiverseManagedApp {
    func matchingApp(id appID: String) -> VoxiverseManagedApp? {
        let canonicalID = VoxiverseAppIdentity.canonicalID(appID)
        return first { app in
            VoxiverseAppIdentity.canonicalID(app.id) == canonicalID ||
                VoxiverseAppIdentity.canonicalID(app.bundleIdentifier) == canonicalID
        }
    }
}
