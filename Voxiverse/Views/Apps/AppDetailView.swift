import SwiftUI

struct AppDetailView: View {
    let app: VoxiverseManagedApp
    let reports: [VoxiverseReport]
    let featureRequests: [VoxiverseFeatureRequest]

    private var canonicalAppID: String {
        VoxiverseAppIdentity.canonicalID(app.id)
    }

    private var appReports: [VoxiverseReport] {
        reports
            .filter { VoxiverseAppIdentity.canonicalID($0.appID) == canonicalAppID }
            .sorted { $0.submittedDate > $1.submittedDate }
    }

    private var appRequests: [VoxiverseFeatureRequest] {
        featureRequests
            .filter { VoxiverseAppIdentity.canonicalID($0.appID) == canonicalAppID }
            .sorted { $0.updatedDate > $1.updatedDate }
    }

    private var appOpenReportCount: Int {
        VoxiverseDashboardData.openReportCount(for: app.id, reports: reports)
    }

    private var betaFeedbackReports: [VoxiverseReport] {
        appReports.filter { $0.reportType == .betaFeedback }
    }

    private var latestSyncedVersion: String {
        firstAvailable(
            appReports.map(\.appVersion) + appRequests.map(\.appVersion)
        )
    }

    private var latestSyncedBuild: String {
        firstAvailable(
            appReports.map(\.buildNumber) + appRequests.map(\.buildNumber)
        )
    }

    private var latestSyncedBundleIdentifier: String {
        firstAvailable(appRequests.map(\.bundleIdentifier))
    }

    private var latestScreenName: String {
        firstAvailable(
            appReports.map(\.screenName) + appRequests.map(\.screenName)
        )
    }

    private var latestSyncedDate: String {
        let dates = appReports.map(\.submittedDate) + appRequests.map(\.updatedDate)
        guard let latestDate = dates.max() else { return "Not available" }
        return latestDate.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private var operationalStatus: String {
        if appOpenReportCount > 0 {
            return "\(appOpenReportCount) open"
        }
        if appRequests.contains(where: { $0.status == .new || $0.status == .considering || $0.status == .planned || $0.status == .inProgress }) {
            return "Requests active"
        }
        if !appReports.isEmpty || !appRequests.isEmpty {
            return "Synced"
        }
        return "Not available"
    }

    private var operationalStatusAccent: Color {
        if appOpenReportCount > 0 {
            return VoxiverseColor.secondaryAccent
        }
        if appRequests.contains(where: { $0.status == .new || $0.status == .considering || $0.status == .planned || $0.status == .inProgress }) {
            return VoxiverseColor.primaryAction
        }
        if !appReports.isEmpty || !appRequests.isEmpty {
            return VoxiverseColor.indicator
        }
        return VoxiverseColor.secondaryText
    }

    private var syncedActivitySummary: String {
        if appReports.isEmpty, appRequests.isEmpty {
            return "No synced reports or requests yet."
        }
        return "\(appReports.count) reports · \(appRequests.count) requests"
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VoxiverseHeader(title: app.name, subtitle: "App detail", closeButton: true)

                // First card — app header, purple frosted border.
                VoxiverseSurfaceCard {
                    HStack(spacing: 14) {
                        VoxiverseAppIcon(
                            assetName: app.iconAssetName,
                            size: 78,
                            cornerRadius: 18
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(app.name)
                                    .font(.system(size: 23, weight: .black, design: .rounded))
                                    .foregroundStyle(VoxiverseColor.primaryText)
                                frostedBadge(operationalStatus.capitalized, tint: operationalStatusAccent)
                                Spacer(minLength: 0)
                            }
                            Text(syncedActivitySummary)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryText)
                                .lineLimit(2)
                        }
                    }
                }
                .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                // Top summary tiles — colored frosted glass, Purple/Berry/Blue.
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        glassMetaTile("Version", latestSyncedVersion, tint: VoxiverseFrostedPalette.color(at: 0))
                        glassMetaTile("Build", latestSyncedBuild, tint: VoxiverseFrostedPalette.color(at: 1))
                    }
                    HStack(spacing: 10) {
                        glassMetaTile("Status", operationalStatus, tint: VoxiverseFrostedPalette.color(at: 2))
                        glassMetaTile("Open Reports", "\(appOpenReportCount)", tint: VoxiverseFrostedPalette.color(at: 3))
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                // Overview — berry frosted border.
                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Overview")
                    VoxiverseSurfaceCard {
                        VStack(spacing: 9) {
                            HStack(spacing: 9) {
                                glassMetaTile("App Name", app.name, tint: VoxiverseFrostedPalette.color(at: 0))
                                glassMetaTile("Version", latestSyncedVersion, tint: VoxiverseFrostedPalette.color(at: 1))
                            }
                            HStack(spacing: 9) {
                                glassMetaTile("Build", latestSyncedBuild, tint: VoxiverseFrostedPalette.color(at: 2))
                                glassMetaTile("Status", operationalStatus, tint: VoxiverseFrostedPalette.color(at: 3))
                            }
                            HStack(spacing: 9) {
                                glassMetaTile("Latest Screen", cleanedScreenName(latestScreenName), tint: VoxiverseFrostedPalette.color(at: 4))
                                glassMetaTile("Bundle ID", latestSyncedBundleIdentifier, tint: VoxiverseFrostedPalette.color(at: 5))
                            }
                        }
                    }
                    .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.berry, cornerRadius: 18)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                // Reports — blue frosted border, centered grid cards.
                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Reports", detail: "\(appReports.count) associated")
                    VoxiverseSurfaceCard {
                        if appReports.isEmpty {
                            Text("No reports are associated with this app yet.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryText)
                        } else {
                            reportsGrid()
                        }
                    }
                    .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.blue, cornerRadius: 18)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                featureRequestsSection

                // Changelog — berry frosted border (empty state).
                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Changelog")
                    VoxiverseSurfaceCard {
                        Text("No changelog entries are connected to \(app.name) yet.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(VoxiverseColor.secondaryText)
                            .lineSpacing(4)
                    }
                    .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.berry, cornerRadius: 18)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                // Beta Information — blue frosted border.
                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Beta Information")
                    VoxiverseSurfaceCard {
                        VStack(spacing: 9) {
                            HStack(spacing: 9) {
                                glassMetaTile("Beta Feedback", "\(betaFeedbackReports.count)", tint: VoxiverseFrostedPalette.color(at: 0))
                                glassMetaTile("Latest Sync", latestSyncedDate, tint: VoxiverseFrostedPalette.color(at: 1))
                            }
                            HStack(spacing: 9) {
                                glassMetaTile("Version", latestBetaValue(\.appVersion), tint: VoxiverseFrostedPalette.color(at: 2))
                                glassMetaTile("Build", latestBetaValue(\.buildNumber), tint: VoxiverseFrostedPalette.color(at: 3))
                            }
                        }
                    }
                    .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.blue, cornerRadius: 18)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                // Links — purple frosted border.
                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Links")
                    VoxiverseSurfaceCard {
                        VStack(spacing: 0) {
                            linkRow(assetName: "github", title: "GitHub", detail: "Repository link", url: app.githubURL)
                            Divider().overlay(VoxiverseColor.divider)
                            linkRow(assetName: "device", title: "TestFlight", detail: "Beta distribution link", url: app.testFlightURL)
                            Divider().overlay(VoxiverseColor.divider)
                            linkRow(assetName: "store", title: "App Store", detail: "Store listing link", url: app.appStoreURL)
                            Divider().overlay(VoxiverseColor.divider)
                            linkRow(assetName: "webcircle", title: "Website", detail: "Product website link", url: app.websiteURL)
                        }
                    }
                    .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Feature Requests (purple border when empty; per-card alternating borders otherwise)

    @ViewBuilder
    private var featureRequestsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            VoxiverseSectionHeader(title: "Feature Requests", detail: "\(appRequests.count) associated")

            if appRequests.isEmpty {
                VoxiverseSurfaceCard {
                    Text("No feature requests are associated with this app yet.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                }
                .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(appRequests.enumerated()), id: \.element.id) { index, request in
                        NavigationLink(value: VoxiverseRoute.featureRequestDetail(request.id)) {
                            requestRowCard(request)
                                .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.color(at: index), cornerRadius: 18)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
    }

    private func requestRowCard(_ request: VoxiverseFeatureRequest) -> some View {
        VoxiverseSurfaceCard {
            HStack(spacing: 10) {
                VoxiverseFrostedGlassIcon(assetName: "bulbxoxo", size: 22, tint: VoxiverseColor.secondaryAccent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(request.title)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(VoxiverseColor.primaryText)
                    Text("\(request.requestCount) requests · \(request.status.rawValue)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Reports grid (centered vertical cards)

    private func reportsGrid() -> some View {
        let items = appReports
        let rowStarts = Array(stride(from: 0, to: items.count, by: 2))
        return VStack(spacing: 9) {
            ForEach(rowStarts, id: \.self) { start in
                HStack(spacing: 9) {
                    reportCell(items[start], index: start)
                    if start + 1 < items.count {
                        reportCell(items[start + 1], index: start + 1)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func reportCell(_ report: VoxiverseReport, index: Int) -> some View {
        NavigationLink(value: VoxiverseRoute.reportDetail(report.id)) {
            reportGridCard(report)
                .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.color(at: index), cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    private func reportGridCard(_ report: VoxiverseReport) -> some View {
        VStack(spacing: 8) {
            VoxiverseAppIcon(assetName: app.iconAssetName, size: 45)

            Text(report.title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("\(report.reportType.rawValue) · \(report.priority.rawValue)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(VoxiverseColor.secondaryText)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                frostedBadge(report.status.rawValue, tint: statusColor(report))
                frostedBadge(report.submittedDate.formatted(.dateTime.month(.abbreviated).day()), tint: VoxiverseFrostedPalette.purple)
            }

            VoxiverseFrostedGlassIcon(assetName: "chevright", size: 16, tint: VoxiverseFrostedPalette.silver)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(VoxiverseColor.raisedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func frostedBadge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(VoxiverseFrostedGlassMaterial(tint: tint, cornerRadius: 9))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func statusColor(_ report: VoxiverseReport) -> Color {
        switch report.status {
        case .new: VoxiverseColor.secondaryAccent
        case .reviewing, .inProgress: VoxiverseColor.primaryAction
        case .resolved, .reviewed, .closed: VoxiverseColor.indicator
        case .actionNeeded: VoxiverseColor.secondaryAccent
        }
    }

    // MARK: - Tile / link helpers

    private func glassMetaTile(_ label: String, _ value: String, tint: Color) -> some View {
        VoxiverseFrostedGlassCard(tint: tint, cornerRadius: 13, contentPadding: 13, minHeight: 68) {
            VStack(alignment: .leading, spacing: 7) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.8))
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
    }

    /// Strips a "Container > Screen" path down to just the final screen name,
    /// e.g. "Settings > Beta Feedback" -> "Beta Feedback".
    private func cleanedScreenName(_ value: String) -> String {
        if let range = value.range(of: ">", options: .backwards) {
            let tail = value[range.upperBound...].trimmingCharacters(in: .whitespaces)
            if !tail.isEmpty { return tail }
        }
        return value
    }

    @ViewBuilder
    private func linkRow(assetName: String, title: String, detail: String, url: String) -> some View {
        if let destination = URL(string: url), !url.isEmpty {
            Link(destination: destination) {
                linkRowContent(assetName: assetName, title: title, detail: detail)
            }
            .buttonStyle(.plain)
        } else {
            linkRowContent(assetName: assetName, title: title, detail: detail)
        }
    }

    private func linkRowContent(assetName: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            VoxiverseFrostedGlassIcon(assetName: assetName, size: 21, tint: VoxiverseColor.indicator)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }
            Spacer()
            VoxiverseFrostedGlassIcon(assetName: "chevright", size: 20, tint: VoxiverseFrostedPalette.silver)
                .offset(y: -4)
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private func firstAvailable(_ values: [String]) -> String {
        values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Not available"
    }

    private func latestBetaValue(_ keyPath: KeyPath<VoxiverseReport, String>) -> String {
        firstAvailable(betaFeedbackReports.map { $0[keyPath: keyPath] })
    }
}
