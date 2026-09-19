import SwiftUI

struct VoxiverseAssetIcon: View {
    let assetName: String
    var size: CGFloat = 22
    var tint: Color = VoxiverseColor.primaryText

    var body: some View {
        Image(assetName)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }
}

struct VoxiverseIconButton: View {
    let assetName: String
    let label: String
    var tint: Color = VoxiverseColor.primaryText
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // Container removed — just the icon; larger glyph + 46×46 hit target so the close control reads clearly.
            VoxiverseAssetIcon(assetName: assetName, size: 30, tint: tint)
                .frame(width: 46, height: 46)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct VoxiversePrimaryButton: View {
    let title: String
    let assetName: String?
    let action: () -> Void

    init(_ title: String, assetName: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.assetName = assetName
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let assetName {
                    VoxiverseAssetIcon(assetName: assetName, size: 17, tint: VoxiverseColor.primaryText)
                }
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .foregroundStyle(VoxiverseColor.primaryText)
            .padding(.horizontal, 16)
            .frame(minHeight: 46)
            .frame(maxWidth: .infinity)
            .background(VoxiverseColor.primaryAction)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(VoxiverseColor.primaryText.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: VoxiverseColor.primaryAction.opacity(0.18), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}

struct VoxiverseSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryAction)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .frame(maxWidth: .infinity)
                .background(VoxiverseColor.raisedSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(VoxiverseColor.primaryAction.opacity(0.42), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
