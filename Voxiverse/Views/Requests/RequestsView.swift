import SwiftUI

struct RequestsView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VoxiverseHeader(title: "Requests", subtitle: "Ideas waiting to become something.")
                VoxiverseEmptyState(
                    assetName: "inbox",
                    title: "No Requests Yet",
                    subtitle: "Feature ideas will have a home here when the Requests experience is ready."
                )
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
    }
}
