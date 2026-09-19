import SwiftUI

struct ReportsView: View {
    let apps: [VoxiverseManagedApp]
    let reports: [VoxiverseReport]

    @State private var searchText = ""
    @State private var selectedApp = "All Apps"
    @State private var selectedType = "All Reports"
    @State private var selectedSort = "Newest"
    @State private var expandedDropdownID: String?

    private var appOptions: [String] {
        ["All Apps"] + apps.map(\.name)
    }

    private var typeOptions: [String] {
        ["All Reports"] + VoxiverseReportType.allCases.map(\.rawValue)
    }

    private var filteredReports: [VoxiverseReport] {
        let matching = reports.filter { report in
            let appName = apps.matchingApp(id: report.appID)?.name ?? ""
            let matchesApp = selectedApp == "All Apps" || appName == selectedApp
            let matchesType = selectedType == "All Reports" || report.reportType.rawValue == selectedType
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty || report.title.localizedCaseInsensitiveContains(query) || appName.localizedCaseInsensitiveContains(query)
            return matchesApp && matchesType && matchesSearch
        }

        switch selectedSort {
        case "Oldest":
            return matching.sorted { $0.submittedDate < $1.submittedDate }
        case "Priority":
            return matching.sorted { priorityRank($0.priority) > priorityRank($1.priority) }
        default:
            return matching.sorted { $0.submittedDate > $1.submittedDate }
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VoxiverseHeader(title: "Reports", subtitle: "Everything that needs your attention.")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    VoxiverseFrostedStatCard(label: "New", value: "\(newReportCount)", baseColor: VoxiverseFrostedPalette.purple)
                    VoxiverseFrostedStatCard(label: "In Progress", value: "\(inProgressBugCount)", baseColor: VoxiverseFrostedPalette.berry)
                    VoxiverseFrostedStatCard(label: "Resolved", value: "\(resolvedBugCount)", baseColor: VoxiverseFrostedPalette.blue)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Find a Report")
                    VoxiverseSearchField(text: $searchText, placeholder: "Search reports or apps")
                        .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 15)

                    VStack(spacing: 10) {
                        VoxiverseDropdown(id: "app", title: "App", options: appOptions, selection: $selectedApp, expandedID: $expandedDropdownID, tint: VoxiverseFrostedPalette.purple, usesFrostedGlass: true)
                        VoxiverseDropdown(id: "type", title: "Report Type", options: typeOptions, selection: $selectedType, expandedID: $expandedDropdownID, tint: VoxiverseFrostedPalette.berry, usesFrostedGlass: true)
                        VoxiverseDropdown(id: "sort", title: "Sort", options: ["Newest", "Oldest", "Priority"], selection: $selectedSort, expandedID: $expandedDropdownID, tint: VoxiverseFrostedPalette.blue, usesFrostedGlass: true)
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Report List", detail: "\(filteredReports.count) shown")

                    if filteredReports.isEmpty {
                        VoxiverseEmptyState(
                            assetName: "document",
                            title: "No Reports",
                            subtitle: "Try a different search or filter selection."
                        )
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(filteredReports.enumerated()), id: \.element.id) { index, report in
                                NavigationLink(value: VoxiverseRoute.reportDetail(report.id)) {
                                    VoxiverseReportCard(
                                        report: report,
                                        app: apps.matchingApp(id: report.appID),
                                        usesInlineAppHeader: true
                                    )
                                    .voxiverseFrostedBorder(
                                        tint: VoxiverseFrostedPalette.color(at: index),
                                        cornerRadius: 17
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
    }

    private var newReportCount: Int {
        reports.filter { $0.status == .new }.count
    }

    private var inProgressBugCount: Int {
        reports.filter { $0.reportType == .bugReport && $0.status == .inProgress }.count
    }

    private var resolvedBugCount: Int {
        reports.filter { $0.reportType == .bugReport && $0.status == .resolved }.count
    }

    private func priorityRank(_ priority: VoxiversePriority) -> Int {
        switch priority {
        case .low: 0
        case .medium: 1
        case .high: 2
        case .critical: 3
        }
    }
}
