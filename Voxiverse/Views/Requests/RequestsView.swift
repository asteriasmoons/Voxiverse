import SwiftUI

struct RequestsView: View {
    let apps: [VoxiverseManagedApp]
    let requests: [VoxiverseFeatureRequest]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VoxiverseHeader(title: "Requests", subtitle: "Ideas waiting to become something.")

                if requests.isEmpty {
                    VoxiverseEmptyState(
                        assetName: "inbox",
                        title: "No Requests Yet",
                        subtitle: "Real feature requests will appear here when they arrive."
                    )
                    .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
                } else {
                    VStack(alignment: .leading, spacing: 11) {
                        VoxiverseSectionHeader(title: "Request List", detail: "\(requests.count) shown")
                        VStack(spacing: 9) {
                            ForEach(Array(requests.enumerated()), id: \.element.id) { index, request in
                                NavigationLink(value: VoxiverseRoute.featureRequestDetail(request.id)) {
                                    requestCard(request, tint: VoxiverseFrostedPalette.color(at: index))
                                }
                                .buttonStyle(.plain)
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

    private func requestCard(_ request: VoxiverseFeatureRequest, tint: Color) -> some View {
        VoxiverseSurfaceCard {
            HStack(spacing: 12) {
                // The icon glyph itself carries the frosted-glass material — no
                // container, card, or backing shape.
                VoxiverseFrostedGlassIcon(assetName: "bulbxoxo", size: 30, tint: tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.title)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(VoxiverseColor.primaryText)
                        .lineLimit(2)
                    Text("\(apps.matchingApp(id: request.appID)?.name ?? "Unknown App") · \(request.status.rawValue)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                }

                Spacer(minLength: 0)
                VoxiverseAssetIcon(assetName: "chevright", size: 15, tint: VoxiverseColor.secondaryText)
            }
        }
        .voxiverseFrostedBorder(tint: tint, cornerRadius: 18)
    }
}
