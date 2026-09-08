import SwiftUI

struct AppDetailView: View {
    let app: VoxiverseManagedApp
    let reports: [VoxiverseReport]
    let featureRequests: [VoxiverseFeatureRequest]

    private var appReports: [VoxiverseReport] {
        reports.filter { $0.appID == app.id }
    }

    private var appRequests: [VoxiverseFeatureRequest] {
        featureRequests.filter { $0.appID == app.id }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VoxiverseHeader(title: app.name, subtitle: "App detail", closeButton: true)

                VoxiverseSurfaceCard {
                    HStack(spacing: 14) {
                        VoxiverseAppIcon(
                            assetName: app.iconAssetName,
                            size: 78,
                            cornerRadius: 18
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(app.name)
                                .font(.system(size: 23, weight: .bold, design: .rounded))
                                .foregroundStyle(VoxiverseColor.primaryText)
                            Text(app.description)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryText)
                                .lineLimit(2)
                            VoxiverseStatusBadge(title: app.status.title, accent: app.status == .beta ? VoxiverseColor.secondaryAccent : VoxiverseColor.indicator)
                        }
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    VoxiverseMetadataTile(label: "Version", value: app.version)
                    VoxiverseMetadataTile(label: "Build", value: app.buildNumber)
                    VoxiverseMetadataTile(label: "Status", value: app.status.title)
                    VoxiverseMetadataTile(label: "Open Reports", value: "\(app.openReportCount)")
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                appSection(title: "Overview") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                        VoxiverseMetadataTile(label: "App Name", value: app.name)
                        VoxiverseMetadataTile(label: "Version", value: app.version)
                        VoxiverseMetadataTile(label: "Build", value: app.buildNumber)
                        VoxiverseMetadataTile(label: "Status", value: app.status.title)
                        VoxiverseMetadataTile(label: "Platform", value: app.platform)
                        VoxiverseMetadataTile(label: "Bundle ID", value: app.bundleIdentifier)
                    }
                }

                appSection(title: "Reports", detail: "\(appReports.count) associated") {
                    if appReports.isEmpty {
                        Text("No reports are associated with this app yet.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(VoxiverseColor.secondaryText)
                    } else {
                        VStack(spacing: 9) {
                            ForEach(appReports, id: \.id) { report in
                                NavigationLink(value: VoxiverseRoute.reportDetail(report.id)) {
                                    VoxiverseReportCard(report: report, app: app)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                appSection(title: "Feature Requests", detail: "\(app.featureRequestCount) associated") {
                    if appRequests.isEmpty {
                        Text("Feature request detail will be connected here in a later pass.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(VoxiverseColor.secondaryText)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(appRequests, id: \.id) { request in
                                HStack(spacing: 10) {
                                    VoxiverseAssetIcon(assetName: "bulbxoxo", size: 19, tint: VoxiverseColor.secondaryAccent)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(request.title)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(VoxiverseColor.primaryText)
                                        Text("\(request.requestCount) requests · \(request.status.rawValue)")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(VoxiverseColor.secondaryText)
                                    }
                                }
                            }
                        }
                    }
                }

                appSection(title: "Changelog") {
                    Text("Build \(app.buildNumber) introduces a quieter review flow, clearer status presentation, and refinements across the core experience.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                        .lineSpacing(4)
                }

                appSection(title: "Beta Information") {
                    HStack(spacing: 12) {
                        VoxiverseAssetIcon(assetName: "sparkledevice", size: 23, tint: VoxiverseColor.indicator)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(app.betaBuildCount) beta builds in the current cycle")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(VoxiverseColor.primaryText)
                            Text(app.status == .beta ? "Collecting feedback from the current beta." : "Beta distribution is not active for this app.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryText)
                        }
                    }
                }

                appSection(title: "Links") {
                    VStack(spacing: 0) {
                        linkRow(assetName: "github", title: "GitHub", detail: "Repository link")
                        Divider().overlay(VoxiverseColor.divider)
                        linkRow(assetName: "device", title: "TestFlight", detail: "Beta distribution link")
                        Divider().overlay(VoxiverseColor.divider)
                        linkRow(assetName: "store", title: "App Store", detail: "Store listing link")
                        Divider().overlay(VoxiverseColor.divider)
                        linkRow(assetName: "webcircle", title: "Website", detail: "Product website link")
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
        .navigationBarBackButtonHidden(true)
    }

    private func appSection<Content: View>(title: String, detail: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            VoxiverseSectionHeader(title: title, detail: detail)
            VoxiverseSurfaceCard {
                content()
            }
        }
        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
    }

    private func linkRow(assetName: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            VoxiverseAssetIcon(assetName: assetName, size: 21, tint: VoxiverseColor.indicator)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }
            Spacer()
            VoxiverseAssetIcon(assetName: "chevright", size: 15, tint: VoxiverseColor.secondaryText)
        }
        .padding(.vertical, 11)
    }
}
