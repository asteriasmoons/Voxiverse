//
//  ContentView.swift
//  Voxiverse
//
//  Created by Asteria Moon on 9/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoxiverseManagedApp.sortOrder)
    private var persistedApps: [VoxiverseManagedApp]

    @Query(sort: \VoxiverseReport.submittedDate, order: .reverse)
    private var persistedReports: [VoxiverseReport]

    @Query(sort: \VoxiverseFeatureRequest.updatedDate, order: .reverse)
    private var persistedFeatureRequests: [VoxiverseFeatureRequest]

    @Query(sort: \VoxiverseActivity.date, order: .reverse)
    private var persistedActivities: [VoxiverseActivity]

    @Query(sort: \VoxiverseConversation.lastActivityAt, order: .reverse)
    private var persistedConversations: [VoxiverseConversation]

    init() {}

    var body: some View {
        VoxiverseRootNavigationView(
            apps: apps,
            reports: reports,
            featureRequests: featureRequests,
            conversations: persistedConversations,
            activities: persistedActivities
        )
        .task {
            VoxiverseSampleData.seedIfNeeded(in: modelContext)
            removeLegacySampleData()
            removeDuplicateApps()
            await VoxiverseCloudKitReportSync.refresh(into: modelContext)

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { break }
                await VoxiverseCloudKitReportSync.refresh(into: modelContext)
            }
        }
    }

    private var apps: [VoxiverseManagedApp] {
        var seen: Set<String> = []
        return persistedApps.filter { app in
            guard !isRemovedApp(app) else { return false }
            return seen.insert(canonicalAppKey(app)).inserted
        }
    }

    private var reports: [VoxiverseReport] {
        persistedReports
    }

    private var featureRequests: [VoxiverseFeatureRequest] {
        persistedFeatureRequests
    }

    @MainActor
    private func removeLegacySampleData() {
        let sampleIDs: Set<String> = ["VX-1042", "VX-1039", "VX-1037", "VX-1028", "VX-1019"]
        let sampleRequestIDs: Set<String> = ["request-sterium-tags", "request-lurelia-shared", "request-loomey-highlights"]
        let removedAppIDs: Set<String> = ["asterium", "dotti", "markli"]
        let removedBundleIDs: Set<String> = ["im.lystaria.asterium", "im.lystaria.dotti", "im.lystaria.markli"]

        let appDescriptor = FetchDescriptor<VoxiverseManagedApp>()
        if let storedApps = try? modelContext.fetch(appDescriptor) {
            for app in storedApps {
                let id = app.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let bundleID = app.bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if removedAppIDs.contains(id) || removedBundleIDs.contains(bundleID) {
                    modelContext.delete(app)
                }
            }
        }

        let descriptor = FetchDescriptor<VoxiverseReport>()
        if let storedReports = try? modelContext.fetch(descriptor) {
            for report in storedReports where sampleIDs.contains(report.reportID) {
                modelContext.delete(report)
            }
        }

        let requestDescriptor = FetchDescriptor<VoxiverseFeatureRequest>()
        if let storedRequests = try? modelContext.fetch(requestDescriptor) {
            for request in storedRequests where sampleRequestIDs.contains(request.id) {
                modelContext.delete(request)
            }
        }

        try? modelContext.save()
    }

    private func isRemovedApp(_ app: VoxiverseManagedApp) -> Bool {
        let removedAppIDs: Set<String> = ["asterium", "dotti", "markli"]
        let removedBundleIDs: Set<String> = ["im.lystaria.asterium", "im.lystaria.dotti", "im.lystaria.markli"]
        let id = app.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let bundleID = app.bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return removedAppIDs.contains(id) || removedBundleIDs.contains(bundleID)
    }

    @MainActor
    private func removeDuplicateApps() {
        guard let storedApps = try? modelContext.fetch(FetchDescriptor<VoxiverseManagedApp>()) else {
            return
        }

        for group in Dictionary(grouping: storedApps, by: canonicalAppKey).values where group.count > 1 {
            let ordered = group.sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.updatedDate > rhs.updatedDate
            }
            guard let keeper = ordered.first else { continue }

            for duplicate in ordered.dropFirst() {
                for report in duplicate.reports ?? [] {
                    report.app = keeper
                }
                for request in duplicate.featureRequests ?? [] {
                    request.app = keeper
                }
                modelContext.delete(duplicate)
            }
        }

        try? modelContext.save()
    }

    private func canonicalAppKey(_ app: VoxiverseManagedApp) -> String {
        let id = VoxiverseAppIdentity.canonicalID(app.id)
        if !id.isEmpty { return id }

        let bundleID = VoxiverseAppIdentity.canonicalID(app.bundleIdentifier)
        if !bundleID.isEmpty { return bundleID }

        return app.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

}

#Preview {
    ContentView()
        .environmentObject(VoxiverseDeepLinkRouter())
        .modelContainer(for: [
            VoxiverseManagedApp.self,
            VoxiverseReport.self,
            VoxiverseFeatureRequest.self,
            VoxiverseReportAttachment.self,
            VoxiverseActivity.self,
            VoxiverseConversation.self
        ], inMemory: true)
}
