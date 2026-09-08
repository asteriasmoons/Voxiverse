import SwiftUI

struct HomeView: View {
    let apps: [VoxiverseManagedApp]
    let reports: [VoxiverseReport]
    let attentionItems: [VoxiverseAttentionItem]
    let activities: [VoxiverseActivity]

    private var openReports: Int {
        reports.filter { $0.status == .new || $0.status == .inProgress }.count
    }

    private var betaApps: Int {
        apps.filter { $0.status == .beta }.count
    }

    private var featureRequestCount: Int {
        apps.reduce(0) { $0 + $1.featureRequestCount }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: VoxiverseSpacing.section) {
                VoxiverseHeader(
                    title: "Voxiverse",
                    subtitle: "Everything you build, in one place."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    VoxiverseStatCard(label: "Open Reports", value: "\(openReports)", accent: .primary)
                    VoxiverseStatCard(label: "Feature Requests", value: "\(featureRequestCount)", accent: .secondary)
                    VoxiverseStatCard(label: "Apps in Beta", value: "\(betaApps)", accent: .indicator)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                VStack(alignment: .leading, spacing: 12) {
                    VoxiverseSectionHeader(title: "Your Apps", detail: "\(apps.count) total")
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(apps, id: \.id) { app in
                                NavigationLink(value: VoxiverseRoute.appDetail(app.id)) {
                                    VoxiverseAppCard(app: app)
                                }
                                .buttonStyle(.plain)
                            }
                        }
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
                            ForEach(attentionItems) { item in
                                if let reportID = item.reportID {
                                    NavigationLink(value: VoxiverseRoute.reportDetail(reportID)) {
                                        attentionCard(item)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    attentionCard(item)
                                }
                            }
                        }
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    VoxiverseSectionHeader(title: "Recent Activity", detail: "Latest")
                        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                    VoxiverseSurfaceCard {
                        VStack(spacing: 0) {
                            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                                VoxiverseActivityRow(activity: activity)
                                if index < activities.count - 1 {
                                    Divider().overlay(VoxiverseColor.divider)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
    }

    private func attentionCard(_ item: VoxiverseAttentionItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(item.accent.color.opacity(0.14))
                VoxiverseAssetIcon(assetName: item.assetName, size: 22, tint: item.accent.color)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
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
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(VoxiverseColor.divider, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

struct VoxiverseActivityRow: View {
    let activity: VoxiverseActivity

    var body: some View {
        HStack(spacing: 12) {
            VoxiverseAssetIcon(assetName: activity.assetName, size: 20, tint: VoxiverseColor.indicator)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
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
