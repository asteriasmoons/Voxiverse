import SwiftData
import SwiftUI

struct AppsView: View {
    @Environment(\.modelContext) private var modelContext

    let conversations: [VoxiverseConversation]

    private var pinnedConversations: [VoxiverseConversation] {
        sorted(conversations.filter(\.isPinned))
    }

    private var unpinnedConversations: [VoxiverseConversation] {
        sorted(conversations.filter { !$0.isPinned })
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VoxiverseHeader(
                    title: "Conversations",
                    subtitle: "Private report conversations across your apps."
                )

                if !pinnedConversations.isEmpty {
                    conversationSection(
                        title: "Pinned",
                        items: pinnedConversations,
                        emptyText: ""
                    )
                }

                conversationSection(
                    title: "All Chats",
                    items: unpinnedConversations,
                    emptyText: "No conversations yet"
                )
            }
            .padding(.bottom, 24)
        }
        .background(VoxiverseColor.background)
    }

    @ViewBuilder
    private func conversationSection(
        title: String,
        items: [VoxiverseConversation],
        emptyText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            VoxiverseSectionHeader(title: title, detail: "\(items.count)")

            if items.isEmpty {
                HStack(spacing: 9) {
                    VoxiverseAssetIcon(
                        assetName: title == "Pinned" ? "pin" : "chatstar",
                        size: 18,
                        tint: VoxiverseColor.secondaryText
                    )
                    Text(emptyText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 2)
                .frame(height: 32)
            } else {
                LazyVStack(spacing: 9) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, conversation in
                        conversationRow(
                            conversation,
                            tint: VoxiverseFrostedPalette.color(at: index)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
    }

    private func conversationRow(_ conversation: VoxiverseConversation, tint: Color) -> some View {
        HStack(spacing: 10) {
            NavigationLink(value: route(for: conversation)) {
                HStack(spacing: 11) {
                    ZStack {
                        Circle()
                            .fill(VoxiverseColor.background.opacity(0.3))

                        VoxiverseFrostedGlassIcon(
                            assetName: reportTypeAssetName(for: conversation.reportType),
                            size: 27,
                            tint: tint
                        )
                    }
                    .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(conversation.reportTitle)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)

                        Text("\(conversation.reportType)  •  \(conversation.reportID)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(conversation.appName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.88))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                conversation.isPinned.toggle()
                try? modelContext.save()
            } label: {
                VoxiverseFrostedGlassIcon(
                    assetName: conversation.isPinned ? "pin" : "pin",
                    size: 22,
                    tint: tint
                )
                .frame(width: 36, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(conversation.isPinned ? "Unpin conversation" : "Pin conversation")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(VoxiverseFrostedGlassMaterial(tint: tint, cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: tint.opacity(0.24), radius: 5)
    }

    private func sorted(_ items: [VoxiverseConversation]) -> [VoxiverseConversation] {
        items.sorted { lhs, rhs in
            let lhsType = reportTypeRank(lhs.reportType)
            let rhsType = reportTypeRank(rhs.reportType)
            if lhsType != rhsType { return lhsType < rhsType }

            let appComparison = lhs.appName.localizedCaseInsensitiveCompare(rhs.appName)
            if appComparison != .orderedSame { return appComparison == .orderedAscending }

            if lhs.lastActivityAt != rhs.lastActivityAt {
                return lhs.lastActivityAt > rhs.lastActivityAt
            }
            return lhs.reportTitle.localizedCaseInsensitiveCompare(rhs.reportTitle) == .orderedAscending
        }
    }

    private func route(for conversation: VoxiverseConversation) -> VoxiverseRoute {
        switch conversation.sourceKind {
        case .report:
            .reportConversation(conversation.sourceRecordID)
        case .featureRequest:
            .featureRequestConversation(conversation.sourceRecordID)
        }
    }

    private func reportTypeRank(_ type: String) -> Int {
        switch type {
        case VoxiverseReportType.bugReport.rawValue: 0
        case VoxiverseReportType.featureRequest.rawValue: 1
        case VoxiverseReportType.betaFeedback.rawValue: 2
        case VoxiverseReportType.generalFeedback.rawValue: 3
        default: 4
        }
    }

    private func reportTypeAssetName(for type: String) -> String {
        switch type {
        case VoxiverseReportType.bugReport.rawValue:
            "bug"
        case VoxiverseReportType.featureRequest.rawValue:
            "bulbxoxo"
        case VoxiverseReportType.betaFeedback.rawValue:
            "chatstar"
        default:
            "document"
        }
    }
}
