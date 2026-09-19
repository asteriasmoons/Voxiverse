import Foundation
import SwiftData

enum VoxiverseSampleData {
    private static let now = Date()
    private static let seedKey = "VoxiverseAppCatalogSeeded"

    // The app catalog is local management data. Operational reports, requests,
    // attention items, and activity are loaded from SwiftData/CloudKit instead.
    static let apps: [VoxiverseManagedApp] = [
        VoxiverseManagedApp(
            id: "sterium",
            name: "Sterium",
            description: "A calm space for visual thinking.",
            version: "1.8.0",
            buildNumber: "184",
            status: .active,
            bundleIdentifier: "im.lystaria.Sterium",
            platform: "iPhone & iPad",
            iconAssetName: "sterium",
            openReportCount: 0,
            featureRequestCount: 0,
            betaBuildCount: 0,
            sortOrder: 0,
            createdDate: now.addingTimeInterval(-2_100_000),
            updatedDate: now.addingTimeInterval(-18_000)
        ),
        VoxiverseManagedApp(
            id: "lurelia",
            name: "Lurelia",
            description: "Routines and gentle momentum.",
            version: "2.4.1",
            buildNumber: "241",
            status: .beta,
            bundleIdentifier: "im.lystaria.Lurelia",
            platform: "iPhone",
            iconAssetName: "lurelia",
            openReportCount: 0,
            featureRequestCount: 0,
            betaBuildCount: 0,
            sortOrder: 1,
            createdDate: now.addingTimeInterval(-1_700_000),
            updatedDate: now.addingTimeInterval(-44_000)
        ),
        VoxiverseManagedApp(
            id: "loomey",
            name: "Loomey",
            description: "A softer way to keep a reading life.",
            version: "1.3.2",
            buildNumber: "132",
            status: .beta,
            bundleIdentifier: "im.lystaria.Loomey",
            platform: "iPhone & iPad",
            iconAssetName: "loomey",
            openReportCount: 0,
            featureRequestCount: 0,
            betaBuildCount: 0,
            sortOrder: 2,
            createdDate: now.addingTimeInterval(-1_300_000),
            updatedDate: now.addingTimeInterval(-76_000)
        ),
        VoxiverseManagedApp(
            id: "markly",
            name: "Markly",
            description: "A focused space for saving and reading the web.",
            version: "1.0",
            buildNumber: "1",
            status: .beta,
            bundleIdentifier: "im.lystaria.Markly",
            platform: "iPhone",
            iconAssetName: "markly",
            openReportCount: 0,
            featureRequestCount: 0,
            betaBuildCount: 0,
            sortOrder: 3,
            createdDate: now.addingTimeInterval(-1_000_000),
            updatedDate: now.addingTimeInterval(-60_000)
        ),
        VoxiverseManagedApp(
            id: "lunixia",
            name: "Lunixia",
            description: "Health routines that feel human.",
            version: "3.0.0",
            buildNumber: "300",
            status: .development,
            bundleIdentifier: "im.lystaria.Lunixia",
            platform: "iPhone & Watch",
            iconAssetName: "lunixia",
            openReportCount: 0,
            featureRequestCount: 0,
            betaBuildCount: 0,
            sortOrder: 4,
            createdDate: now.addingTimeInterval(-760_000),
            updatedDate: now.addingTimeInterval(-152_000)
        ),
        VoxiverseManagedApp(
            id: "voxterm",
            name: "VoxTerm",
            description: "Focused tools for remote work.",
            version: "0.9.4",
            buildNumber: "94",
            status: .beta,
            bundleIdentifier: "im.lystaria.VoxTerm",
            platform: "iPhone & iPad",
            iconAssetName: "voxterm",
            openReportCount: 0,
            featureRequestCount: 0,
            betaBuildCount: 0,
            sortOrder: 5,
            createdDate: now.addingTimeInterval(-620_000),
            updatedDate: now.addingTimeInterval(-210_000)
        )
    ]

    @MainActor
    static func seedIfNeeded(in modelContext: ModelContext) {
        guard let storedApps = try? modelContext.fetch(FetchDescriptor<VoxiverseManagedApp>()) else { return }

        var didInsertMissingApp = false
        for app in apps where storedApps.matchingApp(id: app.id) == nil {
            modelContext.insert(app)
            didInsertMissingApp = true
        }

        guard didInsertMissingApp || !UserDefaults.standard.bool(forKey: seedKey) else { return }

        do {
            if didInsertMissingApp {
                try modelContext.save()
            }
            UserDefaults.standard.set(true, forKey: seedKey)
        } catch {
            // Leave the guard unset so a later launch can retry after a transient store error.
        }
    }
}
