import SwiftUI

struct CenterActionView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VoxiverseHeader(
                    title: "Center Action",
                    subtitle: "A shared place for what comes next."
                )
                VoxiverseEmptyState(
                    assetName: "addwavy",
                    title: "Action Center Reserved",
                    subtitle: "This central action is prepared for a future creation flow."
                )
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
    }
}
