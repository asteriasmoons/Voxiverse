import SwiftUI

struct AppsView: View {
    let apps: [VoxiverseManagedApp]
    let reports: [VoxiverseReport]

    private var activeAppCount: Int {
        apps.filter { $0.status == .active }.count
    }

    private var betaAppCount: Int {
        apps.filter { $0.status == .beta }.count
    }

    private var openReportCount: Int {
        VoxiverseDashboardData.openReportCount(reports)
    }

    // Compact snapshot tile using the approved glass material, preserving the
    // existing Snapshot typography/layout (label + value).
    private func snapshotTile(label: String, value: String, tint: Color) -> some View {
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

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VoxiverseHeader(title: "Apps", subtitle: "Everything you've built.")

                VoxiverseSurfaceCard {
                    HStack(alignment: .center, spacing: 14) {
                        // The icon glyph itself carries the frosted-glass material —
                        // no container box and no border around the icon.
                        VoxiverseFrostedGlassIcon(
                            assetName: "appsphone",
                            size: 44,
                            tint: VoxiverseFrostedPalette.purple
                        )

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Your App Home Is Ready")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(VoxiverseColor.primaryText)

                            Text("The management workspace will live here. App details are available from Home.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                VStack(alignment: .leading, spacing: 12) {
                    VoxiverseSectionHeader(title: "Ecosystem Snapshot")
                    VoxiverseSurfaceCard {
                        VStack(spacing: 9) {
                            HStack(spacing: 9) {
                                snapshotTile(label: "Apps", value: "\(apps.count)", tint: VoxiverseFrostedPalette.purple)
                                snapshotTile(label: "Active", value: "\(activeAppCount)", tint: VoxiverseFrostedPalette.berry)
                            }
                            HStack(spacing: 9) {
                                snapshotTile(label: "In Beta", value: "\(betaAppCount)", tint: VoxiverseFrostedPalette.blue)
                                snapshotTile(label: "Open Reports", value: "\(openReportCount)", tint: VoxiverseFrostedPalette.purple)
                            }
                        }
                    }
                    .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.berry, cornerRadius: 18)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
    }
}
