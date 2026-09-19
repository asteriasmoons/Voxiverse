import SwiftUI

struct VoxiverseHeader: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let subtitle: String
    var closeButton: Bool = false
    var trailingAssetName: String? = nil
    var trailingLabel: String = "More options"
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }

            Spacer(minLength: 8)

            if closeButton {
                VoxiverseIconButton(
                    assetName: "xmarkwavy",
                    label: "Close"
                ) {
                    dismiss()
                }
            } else if let trailingAssetName, let trailingAction {
                VoxiverseIconButton(
                    assetName: trailingAssetName,
                    label: trailingLabel,
                    action: trailingAction
                )
            }
        }
        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }
}
