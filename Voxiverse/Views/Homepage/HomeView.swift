import SwiftUI

struct HomeView: View {
    let apps: [VoxiverseManagedApp]
    let reports: [VoxiverseReport]
    let featureRequests: [VoxiverseFeatureRequest]
    let activities: [VoxiverseActivity]

    private var openReports: Int {
        VoxiverseDashboardData.openReportCount(reports)
    }

    private var betaApps: Int {
        apps.filter { $0.status == .beta }.count
    }

    private var featureRequestCount: Int {
        featureRequests.count
    }

    private var attentionItems: [VoxiverseAttentionItem] {
        VoxiverseDashboardData.needsAttention(
            reports: reports,
            requests: featureRequests,
            apps: apps
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: VoxiverseSpacing.section) {
                VoxiverseHeader(
                    title: "Voxiverse",
                    subtitle: "Everything you build, in one place."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    VoxiverseFrostedStatCard(label: "Open Reports", value: "\(openReports)", baseColor: VoxiverseColor.primaryAction)      // #8875b5
                    VoxiverseFrostedStatCard(label: "Feature Requests", value: "\(featureRequestCount)", baseColor: VoxiverseColor.secondaryAccent) // #a1236f
                    VoxiverseFrostedStatCard(label: "Apps in Beta", value: "\(betaApps)", baseColor: VoxiverseColor.indicator)             // #7187b8
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                VStack(alignment: .leading, spacing: 12) {
                    VoxiverseSectionHeader(title: "Your Apps", detail: "\(apps.count) total")
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(apps.enumerated()), id: \.offset) { index, app in
                                NavigationLink(value: VoxiverseRoute.appDetail(app.id)) {
                                    VoxiverseAppCard(app: app, reports: reports)
                                        .voxiverseFrostedBorder(
                                            tint: VoxiverseFrostedPalette.color(at: index),
                                            cornerRadius: 20
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    VoxiverseSectionHeader(title: "Needs Attention")
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                    if attentionItems.isEmpty {
                        VoxiverseEmptyState(
                            assetName: "checkwavy",
                            title: "Nothing Needs Attention",
                            subtitle: "Your ecosystem is in a good place right now."
                        )
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                    } else {
                        VStack(spacing: 9) {
                            ForEach(Array(attentionItems.enumerated()), id: \.element.id) { index, item in
                                let tint = VoxiverseFrostedPalette.color(at: index)
                                if let reportID = item.reportID {
                                    NavigationLink(value: VoxiverseRoute.reportDetail(reportID)) {
                                        attentionCard(item, tint: tint)
                                    }
                                    .buttonStyle(.plain)
                                } else if item.requestID != nil {
                                    NavigationLink(value: VoxiverseRoute.appDetail(item.appID)) {
                                        attentionCard(item, tint: tint)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    attentionCard(item, tint: tint)
                                }
                            }
                        }
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    VoxiverseSectionHeader(title: "Recent Activity", detail: "Latest")
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                    if activities.isEmpty {
                        VoxiverseEmptyState(
                            assetName: "clockwavy",
                            title: "No Recent Activity",
                            subtitle: "New reports, requests, and status changes will appear here."
                        )
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                    } else {
                        VoxiverseSurfaceCard {
                            VStack(spacing: 0) {
                                ForEach(Array(activities.prefix(10).enumerated()), id: \.element.id) { index, activity in
                                    activityLink(activity)
                                    if index < min(activities.count, 10) - 1 {
                                        Divider().overlay(VoxiverseColor.divider)
                                    }
                                }
                            }
                        }
                        .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
    }

    @ViewBuilder
    private func activityLink(_ activity: VoxiverseActivity) -> some View {
        if !activity.relatedReportID.isEmpty {
            NavigationLink(value: VoxiverseRoute.reportDetail(activity.relatedReportID)) {
                VoxiverseActivityRow(activity: activity)
            }
            .buttonStyle(.plain)
        } else if !activity.relatedAppID.isEmpty {
            NavigationLink(value: VoxiverseRoute.appDetail(activity.relatedAppID)) {
                VoxiverseActivityRow(activity: activity)
            }
            .buttonStyle(.plain)
        } else {
            VoxiverseActivityRow(activity: activity)
        }
    }

    private func attentionCard(_ item: VoxiverseAttentionItem, tint: Color) -> some View {
        HStack(spacing: 12) {
            // The icon glyph itself carries the frosted-glass material — no
            // container, card, or backing shape.
            VoxiverseFrostedGlassIcon(assetName: item.assetName, size: 30, tint: tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .lineLimit(1)
                Text(item.detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }
            Spacer()
            VoxiverseAssetIcon(assetName: "chevright", size: 15, tint: VoxiverseColor.secondaryText)
        }
        .padding(12)
        .background(VoxiverseColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .voxiverseFrostedBorder(tint: tint, cornerRadius: 15)
    }
}

struct VoxiverseActivityRow: View {
    let activity: VoxiverseActivity

    // Deterministic glass tint by activity type so a given type stays
    // visually recognizable: Report/Bug = Blue, Feature Request = Berry Pink,
    // Beta Feedback = Purple. Status-change activities fall back to Purple
    // unless the underlying type is a feature request.
    private var glassTint: Color {
        if !activity.relatedRequestID.isEmpty {
            return VoxiverseFrostedPalette.berry
        }
        switch activity.assetName {
        case "bug", "document":
            return VoxiverseFrostedPalette.blue
        case "chatstar":
            return VoxiverseFrostedPalette.purple
        default:
            return VoxiverseFrostedPalette.purple
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VoxiverseFrostedGlassIcon(assetName: activity.assetName, size: 26, tint: glassTint)
            VStack(alignment: .leading, spacing: 3) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                Text(activity.detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }
            Spacer()
            Text(activity.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(VoxiverseColor.secondaryText)
        }
        .padding(.vertical, 11)
    }
}
