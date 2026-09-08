import SwiftUI

struct AppsView: View {
    let apps: [VoxiverseManagedApp]

    private var activeAppCount: Int {
        apps.filter { $0.status == .active }.count
    }

    private var betaAppCount: Int {
        apps.filter { $0.status == .beta }.count
    }

    private var openReportCount: Int {
        apps.reduce(0) { $0 + $1.openReportCount }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VoxiverseHeader(title: "Apps", subtitle: "Everything you've built.")

                VoxiverseSurfaceCard {
                    HStack(alignment: .center, spacing: 14) {
                        VoxiverseAssetIcon(
                            assetName: "appsphone",
                            size: 30,
                            tint: VoxiverseColor.primaryAction
                        )
                        .frame(width: 58, height: 58)
                        .background(VoxiverseColor.raisedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Your App Home Is Ready")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(VoxiverseColor.primaryText)

                            Text("The management workspace will live here. App details are available from Home.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                VStack(alignment: .leading, spacing: 12) {
                    VoxiverseSectionHeader(title: "Ecosystem Snapshot")
                    VoxiverseSurfaceCard {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 9
                        ) {
                            VoxiverseMetadataTile(label: "Apps", value: "\(apps.count)")
                            VoxiverseMetadataTile(label: "Active", value: "\(activeAppCount)")
                            VoxiverseMetadataTile(label: "In Beta", value: "\(betaAppCount)")
                            VoxiverseMetadataTile(label: "Open Reports", value: "\(openReportCount)")
                        }
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
    }
}
