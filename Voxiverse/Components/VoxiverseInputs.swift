import SwiftUI

struct VoxiverseSearchField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            VoxiverseAssetIcon(
                assetName: "searchwavy",
                size: 20,
                tint: isFocused ? VoxiverseColor.primaryAction : VoxiverseColor.secondaryText
            )

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundStyle(VoxiverseColor.secondaryText)
            )
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(VoxiverseColor.primaryText)
            .focused($isFocused)
            .textInputAutocapitalization(.never)
            .textFieldStyle(.plain)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    VoxiverseAssetIcon(
                        assetName: "xmarkwavy",
                        size: 16,
                        tint: VoxiverseColor.secondaryText
                    )
                    .frame(width: 30, height: 30)
                    .background(VoxiverseColor.raisedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 50)
        .background(VoxiverseColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(
                    isFocused ? VoxiverseColor.primaryAction : VoxiverseColor.divider,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .animation(.easeOut(duration: 0.16), value: isFocused)
    }
}

struct VoxiverseDropdown: View {
    let id: String
    let title: String
    let options: [String]
    @Binding var selection: String
    @Binding var expandedID: String?
    /// Tint used only when `usesFrostedGlass` is true.
    var tint: Color = VoxiverseColor.primaryAction
    /// Opt-in: render the closed control and expanded menu with the approved
    /// frosted-glass material. Default false preserves the original appearance
    /// everywhere this component is already used.
    var usesFrostedGlass: Bool = false
    /// When true, unselected options render bold (selected stays heavy).
    var boldOptions: Bool = false

    private var isExpanded: Bool { expandedID == id }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.secondaryText)

            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    expandedID = isExpanded ? nil : id
                }
            } label: {
                HStack(spacing: 10) {
                    Text(selection)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(usesFrostedGlass ? Color.white : VoxiverseColor.primaryText)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    VoxiverseAssetIcon(
                        assetName: isExpanded ? "chevup" : "chevdown",
                        size: 16,
                        tint: usesFrostedGlass ? Color.white : VoxiverseColor.primaryAction
                    )
                }
                .padding(.horizontal, 13)
                .frame(minHeight: 46)
                .modifier(
                    VoxiverseDropdownSurface(
                        cornerRadius: 14,
                        isHighlighted: isExpanded,
                        tint: tint,
                        usesFrostedGlass: usesFrostedGlass
                    )
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                selection = option
                                withAnimation(.easeOut(duration: 0.18)) {
                                    expandedID = nil
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Text(option)
                                        .font(.system(
                                            size: 14,
                                            weight: option == selection ? .black : (boldOptions ? .bold : .medium),
                                            design: .rounded
                                        ))
                                        .foregroundStyle(optionTextColor(isSelected: option == selection))
                                    Spacer()
                                    if option == selection {
                                        VoxiverseAssetIcon(
                                            assetName: "checkwavy",
                                            size: 15,
                                            tint: usesFrostedGlass ? Color.white : VoxiverseColor.primaryAction
                                        )
                                    }
                                }
                                .padding(.horizontal, 13)
                                .frame(minHeight: 42)
                                .background(optionRowBackground(isSelected: option == selection))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 180)
                .modifier(
                    VoxiverseDropdownMenuSurface(
                        cornerRadius: 14,
                        tint: tint,
                        usesFrostedGlass: usesFrostedGlass
                    )
                )
                .shadow(color: VoxiverseColor.background.opacity(0.72), radius: 12, y: 8)
                .zIndex(5)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .zIndex(isExpanded ? 5 : 0)
    }

    @ViewBuilder
    private func optionRowBackground(isSelected: Bool) -> some View {
        if usesFrostedGlass {
            if isSelected {
                Color.white.opacity(0.16)
            } else {
                Color.clear
            }
        } else {
            if isSelected {
                VoxiverseColor.raisedSurface
            } else {
                VoxiverseColor.surface
            }
        }
    }

    private func optionTextColor(isSelected: Bool) -> Color {
        if usesFrostedGlass {
            return isSelected ? Color.white : Color.white.opacity(0.72)
        } else {
            return isSelected ? VoxiverseColor.primaryText : VoxiverseColor.secondaryText
        }
    }
}

/// Background for a dropdown's closed control: frosted glass when opted in,
/// otherwise the original dark surface + stroke (unchanged default).
private struct VoxiverseDropdownSurface: ViewModifier {
    let cornerRadius: CGFloat
    let isHighlighted: Bool
    let tint: Color
    let usesFrostedGlass: Bool

    func body(content: Content) -> some View {
        if usesFrostedGlass {
            content
                .background(VoxiverseFrostedGlassMaterial(tint: tint, cornerRadius: cornerRadius))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
                .background(VoxiverseColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            isHighlighted ? VoxiverseColor.primaryAction : VoxiverseColor.divider,
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

/// Background for a dropdown's expanded menu: the same frosted glass when opted
/// in, otherwise the original dark surface + stroke (unchanged default).
private struct VoxiverseDropdownMenuSurface: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let usesFrostedGlass: Bool

    func body(content: Content) -> some View {
        if usesFrostedGlass {
            content
                .background(VoxiverseFrostedGlassMaterial(tint: tint, cornerRadius: cornerRadius))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
                .background(VoxiverseColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(VoxiverseColor.primaryAction.opacity(0.34), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
