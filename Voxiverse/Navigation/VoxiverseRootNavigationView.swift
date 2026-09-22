import SwiftUI

struct VoxiverseRootNavigationView: View {
    @EnvironmentObject private var deepLinkRouter: VoxiverseDeepLinkRouter

    let apps: [VoxiverseManagedApp]
    let reports: [VoxiverseReport]
    let featureRequests: [VoxiverseFeatureRequest]
    let conversations: [VoxiverseConversation]
    let activities: [VoxiverseActivity]

    @State private var selectedTab: VoxiverseTab = .home
    @State private var homePath: [VoxiverseRoute] = []
    @State private var appsPath: [VoxiverseRoute] = []
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
        .onAppear {
            openPendingReportConversation()
        }
        .onChange(of: deepLinkRouter.pendingReportConversationID) { _, _ in
            openPendingReportConversation()
        }
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .home:
            NavigationStack(path: $homePath) {
                HomeView(
                    apps: apps,
                    reports: reports,
                    featureRequests: featureRequests,
                    activities: activities
                )
                .navigationDestination(for: VoxiverseRoute.self) { route in
                    destination(for: route)
                }
            }
            .toolbar(.hidden, for: .navigationBar)

        case .apps:
            NavigationStack(path: $appsPath) {
                AppsView(conversations: conversations)
                    .navigationDestination(for: VoxiverseRoute.self) { route in
                        destination(for: route)
                    }
            }
            .toolbar(.hidden, for: .navigationBar)

        case .centerAction:
            EmptyView()

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
                RequestsView(apps: apps, requests: featureRequests)
                    .navigationDestination(for: VoxiverseRoute.self) { route in
                        destination(for: route)
                    }
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

        case .reportConversation(let reportID):
            if let report = reports.first(where: { $0.id == reportID }) {
                VoxiverseConversationDestination(
                    context: ReportConversationContext(
                        report: report,
                        app: apps.matchingApp(id: report.appID),
                        conversation: conversations.first { $0.sourceRecordID == report.id }
                    )
                )
            } else {
                missingDestination(title: "Report Not Found", assetName: "document")
            }

        case .featureRequestDetail(let requestID):
            if let request = featureRequests.first(where: { $0.id == requestID }) {
                FeatureRequestDetailView(request: request, apps: apps)
            } else {
                missingDestination(title: "Feature Request Not Found", assetName: "bulbxoxo")
            }

        case .featureRequestConversation(let requestID):
            if let request = featureRequests.first(where: { $0.id == requestID }) {
                VoxiverseConversationDestination(
                    context: ReportConversationContext(
                        request: request,
                        app: apps.matchingApp(id: request.appID),
                        conversation: conversations.first { $0.sourceRecordID == request.id }
                    )
                )
            } else {
                missingDestination(title: "Feature Request Not Found", assetName: "bulbxoxo")
            }
        }
    }

    private func openPendingReportConversation() {
        guard let reportID = deepLinkRouter.consumePendingReportConversationID() else { return }

        if let report = reports.first(where: { $0.reportID == reportID || $0.id == reportID }) {
            selectedTab = .reports
            reportsPath = [.reportConversation(report.id)]
            return
        }

        if let request = featureRequests.first(where: { $0.id == reportID }) {
            selectedTab = .requests
            requestsPath = [.featureRequestConversation(request.id)]
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

private struct VoxiverseConversationDestination: View {
    @Environment(\.dismiss) private var dismiss

    let context: ReportConversationContext

    var body: some View {
        VoxiverseReportConversationView(context: context) {
            dismiss()
        }
        .navigationBarBackButtonHidden(true)
    }
}
