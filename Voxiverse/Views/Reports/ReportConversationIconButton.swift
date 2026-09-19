//
//  ReportConversationIconButton.swift
//  Voxiverse
//

import SwiftUI

struct ReportConversationIconButton: View {
    let state: ReportConversationState
    let unreadCount: Int
    /// When true, the chat glyph itself renders as frosted glass (matching the
    /// app's frosted-icon language) instead of the flat boxed icon.
    var frosted: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                iconContent

                if unreadCount > 0 || state == .invited {
                    Circle()
                        .fill(VoxiverseColor.secondaryAccent)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(VoxiverseColor.background, lineWidth: 2))
                        .offset(x: 3, y: -3)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open private conversation")
        .accessibilityHint(accessibilityHint)
    }

    @ViewBuilder
    private var iconContent: some View {
        if frosted {
            // The chat glyph itself becomes frosted glass — no flat box.
            VoxiverseFrostedGlassIcon(
                assetName: "chatsparkle",
                size: 26,
                tint: unreadCount > 0 ? VoxiverseFrostedPalette.berry : VoxiverseFrostedPalette.purple
            )
            .frame(width: 42, height: 42)
            .contentShape(Rectangle())
        } else {
            VoxiverseAssetIcon(
                assetName: "chatsparkle",
                size: 20,
                tint: unreadCount > 0 ? VoxiverseColor.secondaryAccent : VoxiverseColor.primaryAction
            )
            .frame(width: 42, height: 42)
            .background(VoxiverseColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }

    private var borderColor: Color {
        unreadCount > 0 || state == .invited
            ? VoxiverseColor.secondaryAccent.opacity(0.72)
            : VoxiverseColor.divider
    }

    private var accessibilityHint: String {
        if unreadCount > 0 {
            return "\(unreadCount) unread reporter message\(unreadCount == 1 ? "" : "s")"
        }
        switch state {
        case .notStarted:
            return "Sending the first message will invite the reporter."
        case .invited:
            return "The reporter has been invited."
        case .accepted:
            return "Open the accepted private report conversation."
        case .declined:
            return "The reporter declined this conversation."
        }
    }
}
