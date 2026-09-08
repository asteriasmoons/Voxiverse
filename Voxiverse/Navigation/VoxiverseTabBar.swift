import SwiftUI

struct VoxiverseTabBar: View {
    @Binding var selection: VoxiverseTab

    var body: some View {
        HStack(spacing: 4) {
            VoxiverseTabItem(tab: .home, selection: $selection)
            VoxiverseTabItem(tab: .apps, selection: $selection)
            VoxiverseCenterActionButton(isSelected: selection == .centerAction) {
                select(.centerAction)
            }
            VoxiverseTabItem(tab: .reports, selection: $selection)
            VoxiverseTabItem(tab: .requests, selection: $selection)
        }
        .padding(7)
        .background(VoxiverseColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(VoxiverseColor.divider, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: VoxiverseColor.background.opacity(0.72), radius: 14, y: 7)
    }

    private func select(_ tab: VoxiverseTab) {
        withAnimation(.easeOut(duration: 0.18)) {
            selection = tab
        }
    }
}

private struct VoxiverseTabItem: View {
    let tab: VoxiverseTab
    @Binding var selection: VoxiverseTab

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
                    tint: selection == tab
                        ? VoxiverseColor.primaryAction
                        : VoxiverseColor.secondaryText
                )
                Text(tab.title)
                    .font(.system(
                        size: 10,
                        weight: selection == tab ? .bold : .semibold,
                        design: .rounded
                    ))
                    .foregroundStyle(
                        selection == tab
                            ? VoxiverseColor.primaryText
                            : VoxiverseColor.secondaryText
                    )
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                selection == tab
                    ? VoxiverseColor.raisedSurface
                    : Color.clear
            )
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
                ZStack {
                    Circle()
                        .fill(VoxiverseColor.primaryAction)
                    VoxiverseAssetIcon(
                        assetName: "addwavy",
                        size: 22,
                        tint: VoxiverseColor.primaryText
                    )
                }
                .frame(width: 42, height: 42)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? VoxiverseColor.primaryText.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )

                Text("Action")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Center action")
    }
}
