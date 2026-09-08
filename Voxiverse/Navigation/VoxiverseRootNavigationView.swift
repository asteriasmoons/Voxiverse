import SwiftUI

struct VoxiverseRootNavigationView: View {
    let apps: [VoxiverseManagedApp]
    let reports: [VoxiverseReport]
    let featureRequests: [VoxiverseFeatureRequest]

    @State private var selectedTab: VoxiverseTab = .home
    @State private var homePath: [VoxiverseRoute] = []
    @State private var appsPath: [VoxiverseRoute] = []
    @State private var centerActionPath: [VoxiverseRoute] = []
    @State private var reportsPath: [VoxiverseRoute] = []
    @State private var requestsPath: [VoxiverseRoute] = []

    var body: some View {
        VStack(spacing: 0) {
            selectedTabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VoxiverseTabBar(selection: $selectedTab)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .background(VoxiverseColor.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .home:
            NavigationStack(path: $homePath) {
                HomeView(
                    apps: apps,
                    reports: reports,
                    attentionItems: VoxiverseSampleData.attentionItems,
                    activities: VoxiverseSampleData.activities
                )
                .navigationDestination(for: VoxiverseRoute.self) { route in
                    destination(for: route)
                }
            }
            .toolbar(.hidden, for: .navigationBar)

        case .apps:
            NavigationStack(path: $appsPath) {
                AppsView(apps: apps)
                    .navigationDestination(for: VoxiverseRoute.self) { route in
                        destination(for: route)
                    }
            }
            .toolbar(.hidden, for: .navigationBar)

        case .centerAction:
            NavigationStack(path: $centerActionPath) {
                CenterActionView()
            }
            .toolbar(.hidden, for: .navigationBar)

        case .reports:
            NavigationStack(path: $reportsPath) {
                ReportsView(apps: apps, reports: reports)
                    .navigationDestination(for: VoxiverseRoute.self) { route in
                        destination(for: route)
                    }
            }
            .toolbar(.hidden, for: .navigationBar)

        case .requests:
            NavigationStack(path: $requestsPath) {
                RequestsView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func destination(for route: VoxiverseRoute) -> some View {
        switch route {
        case .appDetail(let appID):
            if let app = apps.first(where: { $0.id == appID }) {
                AppDetailView(
                    app: app,
                    reports: reports,
                    featureRequests: featureRequests
                )
            } else {
                missingDestination(title: "App Not Found", assetName: "appsphone")
            }

        case .reportDetail(let reportID):
            if let report = reports.first(where: { $0.id == reportID }) {
                ReportDetailView(report: report, apps: apps)
            } else {
                missingDestination(title: "Report Not Found", assetName: "document")
            }
        }
    }

    private func missingDestination(title: String, assetName: String) -> some View {
        VStack(spacing: 0) {
            VoxiverseHeader(title: title, subtitle: "This item is no longer available.", closeButton: true)
            VoxiverseEmptyState(
                assetName: assetName,
                title: title,
                subtitle: "Return to the previous screen and choose another item."
            )
            .padding(VoxiverseSpacing.pageHorizontal)
            Spacer()
        }
        .background(VoxiverseColor.background)
        .navigationBarBackButtonHidden(true)
    }
}
