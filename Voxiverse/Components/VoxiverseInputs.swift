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

    private var isExpanded: Bool { expandedID == id }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(VoxiverseColor.secondaryText)

            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    expandedID = isExpanded ? nil : id
                }
            } label: {
                HStack(spacing: 10) {
                    Text(selection)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(VoxiverseColor.primaryText)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    VoxiverseAssetIcon(
                        assetName: isExpanded ? "chevup" : "chevdown",
                        size: 16,
                        tint: VoxiverseColor.primaryAction
                    )
                }
                .padding(.horizontal, 13)
                .frame(minHeight: 46)
                .background(VoxiverseColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isExpanded ? VoxiverseColor.primaryAction : VoxiverseColor.divider,
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                                            weight: option == selection ? .bold : .medium,
                                            design: .rounded
                                        ))
                                        .foregroundStyle(
                                            option == selection
                                                ? VoxiverseColor.primaryText
                                                : VoxiverseColor.secondaryText
                                        )
                                    Spacer()
                                    if option == selection {
                                        VoxiverseAssetIcon(
                                            assetName: "checkwavy",
                                            size: 15,
                                            tint: VoxiverseColor.primaryAction
                                        )
                                    }
                                }
                                .padding(.horizontal, 13)
                                .frame(minHeight: 42)
                                .background(
                                    option == selection
                                        ? VoxiverseColor.raisedSurface
                                        : VoxiverseColor.surface
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 180)
                .background(VoxiverseColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(VoxiverseColor.primaryAction.opacity(0.34), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: VoxiverseColor.background.opacity(0.72), radius: 12, y: 8)
                .zIndex(5)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .zIndex(isExpanded ? 5 : 0)
    }
}
