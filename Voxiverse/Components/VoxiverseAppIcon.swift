import SwiftUI

struct VoxiverseAppIcon: View {
    let assetName: String
    let size: CGFloat
    var cornerRadius: CGFloat? = nil

    private var resolvedCornerRadius: CGFloat {
        cornerRadius ?? size * 0.22
    }

    private var resolvedAssetName: String {
        switch assetName {
        case "crystalball": "sterium"
        case "clockwavy": "lurelia"
        case "openbook": "loomey"
        case "mooncream": "lunixia"
        case "codewindow": "voxterm"
        default: assetName
        }
    }

    var body: some View {
        Image(resolvedAssetName)
            .resizable()
            .renderingMode(.original)
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: resolvedCornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: resolvedCornerRadius,
                    style: .continuous
                )
                .stroke(VoxiverseColor.primaryText.opacity(0.1), lineWidth: 1)
            }
    }
}
