import SwiftUI

struct VoxiverseTabBar: View {
    @Binding var selection: VoxiverseTab

    // Compact pill. A fixed content height keeps the corner radius exactly half
    // the bar's total height, so the rounded rectangle reads as a true pill.
    private let contentHeight: CGFloat = 54
    private let verticalPadding: CGFloat = 6
    private var pillRadius: CGFloat { (contentHeight + verticalPadding * 2) / 2 }

    var body: some View {
        HStack(spacing: 2) {
            VoxiverseTabItem(tab: .home, selection: $selection)
            VoxiverseTabItem(tab: .apps, selection: $selection)
            VoxiverseCenterActionButton(isSelected: false) {}
            VoxiverseTabItem(tab: .reports, selection: $selection)
            VoxiverseTabItem(tab: .requests, selection: $selection)
        }
        .frame(height: contentHeight)
        .padding(.horizontal, 8)
        .padding(.vertical, verticalPadding)
        .background(VoxiverseColor.surface, in: RoundedRectangle(cornerRadius: pillRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: pillRadius, style: .continuous))
        .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.blue, cornerRadius: pillRadius, width: 2.5)
        .shadow(color: VoxiverseColor.background.opacity(0.72), radius: 14, y: 7)
    }

}

private struct VoxiverseTabItem: View {
    let tab: VoxiverseTab
    @Binding var selection: VoxiverseTab

    private var isSelected: Bool { selection == tab }

    // The selected accent cycles Purple → Berry → Blue → repeat across the tabs.
    private var selectedAccent: Color {
        switch tab {
        case .home: VoxiverseFrostedPalette.purple
        case .apps: VoxiverseFrostedPalette.berry
        case .reports: VoxiverseFrostedPalette.blue
        case .requests: VoxiverseFrostedPalette.purple
        case .centerAction: VoxiverseFrostedPalette.purple
        }
    }

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                VoxiverseAssetIcon(
                    assetName: tab.assetName,
                    size: 20,
                    tint: isSelected ? selectedAccent : VoxiverseColor.secondaryText
                )
                Text(tab.title)
                    .font(.system(
                        size: 10,
                        weight: .black,
                        design: .rounded
                    ))
                    .foregroundStyle(
                        isSelected ? VoxiverseColor.primaryText : VoxiverseColor.secondaryText
                    )
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? selectedAccent.opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct VoxiverseCenterActionButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                // Outer circle removed — the addwavy glyph itself now carries the
                // tri-color frosted-glass treatment, enlarged to hold the visual
                // weight the circle used to provide.
                VoxiverseFrostedGlassIcon(assetName: "addwavy", size: 36, tint: VoxiverseColor.primaryAction)
                    .opacity(isSelected ? 1 : 0.9)

                Text("Action")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Center action")
    }
}
