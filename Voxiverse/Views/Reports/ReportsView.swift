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
            let appName = apps.first(where: { $0.id == report.appID })?.name ?? ""
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
                    VoxiverseStatCard(label: "New", value: "\(count(for: .new))", accent: .secondary)
                    VoxiverseStatCard(label: "In Progress", value: "\(count(for: .inProgress))", accent: .primary)
                    VoxiverseStatCard(label: "Resolved", value: "\(count(for: .resolved))", accent: .indicator)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Find a Report")
                    VoxiverseSearchField(text: $searchText, placeholder: "Search reports or apps")

                    VStack(spacing: 10) {
                        VoxiverseDropdown(id: "app", title: "App", options: appOptions, selection: $selectedApp, expandedID: $expandedDropdownID)
                        VoxiverseDropdown(id: "type", title: "Report Type", options: typeOptions, selection: $selectedType, expandedID: $expandedDropdownID)
                        VoxiverseDropdown(id: "sort", title: "Sort", options: ["Newest", "Oldest", "Priority"], selection: $selectedSort, expandedID: $expandedDropdownID)
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
                            ForEach(filteredReports, id: \.id) { report in
                                NavigationLink(value: VoxiverseRoute.reportDetail(report.id)) {
                                    VoxiverseReportCard(report: report, app: apps.first(where: { $0.id == report.appID }))
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

    private func count(for status: VoxiverseReportStatus) -> Int {
        reports.filter { $0.status == status }.count
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
