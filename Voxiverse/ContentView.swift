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

    init() {}

    var body: some View {
        VoxiverseRootNavigationView(
            apps: apps,
            reports: reports,
            featureRequests: featureRequests
        )
        .task {
            VoxiverseSampleData.seedIfNeeded(in: modelContext)
            removeSampleReports()
            await VoxiverseCloudKitReportSync.refresh(into: modelContext)

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { break }
                await VoxiverseCloudKitReportSync.refresh(into: modelContext)
            }
        }
    }

    private var apps: [VoxiverseManagedApp] {
        persistedApps.isEmpty ? VoxiverseSampleData.apps : persistedApps
    }

    private var reports: [VoxiverseReport] {
        persistedReports
    }

    private var featureRequests: [VoxiverseFeatureRequest] {
        persistedFeatureRequests.isEmpty ? VoxiverseSampleData.featureRequests : persistedFeatureRequests
    }

    @MainActor
    private func removeSampleReports() {
        let sampleIDs: Set<String> = ["VX-1042", "VX-1039", "VX-1037", "VX-1028", "VX-1019"]
        let descriptor = FetchDescriptor<VoxiverseReport>()
        guard let stored = try? modelContext.fetch(descriptor) else { return }

        for report in stored where sampleIDs.contains(report.reportID) {
            modelContext.delete(report)
        }

        try? modelContext.save()
    }

}

#Preview {
    ContentView()
        .modelContainer(for: [
            VoxiverseManagedApp.self,
            VoxiverseReport.self,
            VoxiverseFeatureRequest.self,
            VoxiverseReportAttachment.self
        ], inMemory: true)
}
