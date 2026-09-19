import SwiftUI
import SwiftData
import UIKit

struct FeatureRequestDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let request: VoxiverseFeatureRequest
    let apps: [VoxiverseManagedApp]
    @State private var selectedAttachment: VoxiverseReportAttachment?
    @State private var selectedStatus: String
    @State private var expandedDropdownID: String?
    @State private var isUpdatingStatus = false
    @State private var statusError: String?
    @State private var showConversation = false
    @State private var conversationState: ReportConversationState = .notStarted
    @State private var conversationUnreadCount = 0

    init(request: VoxiverseFeatureRequest, apps: [VoxiverseManagedApp], openConversationOnAppear: Bool = false) {
        self.request = request
        self.apps = apps
        _selectedStatus = State(initialValue: request.status.rawValue)
        _showConversation = State(initialValue: openConversationOnAppear)
    }

    private var app: VoxiverseManagedApp? {
        apps.matchingApp(id: request.appID)
    }

    var body: some View {
        ZStack {
            requestContent

            if let selectedAttachment {
                VoxiverseAttachmentPreviewOverlay(attachment: selectedAttachment) {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        self.selectedAttachment = nil
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }

            if showConversation {
                VoxiverseReportConversationView(context: conversationContext) {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        showConversation = false
                    }
                    refreshConversationSummary()
                }
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .background(VoxiverseColor.background)
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.16), value: selectedAttachment?.id)
        .animation(.easeInOut(duration: 0.16), value: showConversation)
        .onChange(of: selectedStatus) { _, newValue in
            statusSelectionChanged(newValue)
        }
        .task {
            await refreshConversationSummaryAsync()
        }
    }

    private var requestContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 23) {
                VoxiverseHeader(title: request.id, subtitle: "Feature request detail", closeButton: true)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Text(request.title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(VoxiverseColor.primaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        ReportConversationIconButton(
                            state: conversationState,
                            unreadCount: conversationUnreadCount,
                            frosted: true
                        ) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                showConversation = true
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        frostedBadge(request.status.rawValue, tint: statusColor)
                        if !request.featureImportance.isEmpty {
                            frostedBadge(request.featureImportance, tint: VoxiverseColor.secondaryAccent)
                        }
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                detailSection(title: "Request Metadata", borderTint: VoxiverseFrostedPalette.purple) {
                    VStack(alignment: .leading, spacing: 12) {
                        glassTileGrid(presentTiles([
                            ("App", app?.name ?? "Unknown App"),
                            ("Submitted", request.createdDate.formatted(.dateTime.month(.abbreviated).day().year())),
                            ("Area", request.category),
                            ("Feature Type", request.featureType),
                            ("Importance", request.featureImportance),
                            ("Audience", request.intendedAudience),
                            ("Location", request.desiredLocation),
                            ("Report ID", request.id)
                        ]))

                        VoxiverseDropdown(
                            id: "feature-request-status",
                            title: "Status",
                            options: request.allowedStatuses.map(\.rawValue),
                            selection: $selectedStatus,
                            expandedID: $expandedDropdownID,
                            tint: VoxiverseFrostedPalette.purple,
                            usesFrostedGlass: true,
                            boldOptions: true
                        )
                        .opacity(isUpdatingStatus ? 0.6 : 1)
                        .allowsHitTesting(!isUpdatingStatus)

                        if let statusError {
                            Text(statusError)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryAccent)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                textSection(title: "What Should It Do?", text: request.featureDescription.isEmpty ? request.description : request.featureDescription, borderTint: VoxiverseFrostedPalette.berry)
                textSection(title: "How Should It Work?", text: request.imaginedWorkflow, borderTint: VoxiverseFrostedPalette.blue)

                if !request.relatedExistingFeature.isEmpty && request.relatedExistingFeature != "None" {
                    detailSection(title: "Related Existing Feature", borderTint: VoxiverseFrostedPalette.purple) {
                        Text(request.relatedExistingFeature)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(VoxiverseColor.primaryText)
                    }
                }

                textSection(title: "Problem or Limitation", text: request.problemAddressed, borderTint: VoxiverseFrostedPalette.berry)
                textSection(title: "Desired Result", text: request.desiredResult, borderTint: VoxiverseFrostedPalette.blue)

                detailSection(title: "Requirements", borderTint: VoxiverseFrostedPalette.purple) {
                    glassTileGrid(presentTiles([
                        ("Saved Data", request.requiresSavedData),
                        ("Notifications", request.needsNotifications),
                        ("Sharing", request.needsSharing),
                        ("AI", request.needsAI)
                    ]))
                }

                textSection(title: "Additional Details", text: request.additionalDetails, borderTint: VoxiverseFrostedPalette.berry)

                attachmentSection
                diagnosticsSection
            }
            .padding(.bottom, 24)
        }
    }

    private var conversationContext: ReportConversationContext {
        ReportConversationContext(request: request, app: app)
    }

    private func refreshConversationSummary() {
        Task {
            await refreshConversationSummaryAsync()
        }
    }

    private func refreshConversationSummaryAsync() async {
        let summary = await VoxiverseReportConversationService.fetchSummary(context: conversationContext)
        conversationState = summary.state
        conversationUnreadCount = summary.staffUnreadCount
    }

    private var attachmentSection: some View {
        detailSection(title: "Reference Images", borderTint: VoxiverseFrostedPalette.blue) {
            if let attachments = request.attachments, !attachments.isEmpty {
                VStack(spacing: 0) {
                    ForEach(attachments, id: \.id) { attachment in
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                selectedAttachment = attachment
                            }
                        } label: {
                            attachmentRow(attachment)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("No reference images were included with this request.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }
        }
    }

    private var diagnosticsSection: some View {
        detailSection(title: "App Diagnostics", borderTint: VoxiverseFrostedPalette.purple) {
            glassTileGrid(presentTiles([
                ("Device", request.deviceModel == "iPhone17,4" ? "iPhone 16 Plus" : request.deviceModel),
                ("iOS Version", request.iOSVersion),
                ("App Version", request.appVersion),
                ("Build", request.buildNumber),
                ("Screen", screenDisplayName),
                ("Submitter", request.submitter)
            ]))
        }
    }

    private func textSection(title: String, text: String, borderTint: Color) -> some View {
        detailSection(title: title, borderTint: borderTint) {
            Text(text.isEmpty ? "No response was provided." : text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(text.isEmpty ? VoxiverseColor.secondaryText.opacity(0.7) : VoxiverseColor.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func detailSection<Content: View>(title: String, borderTint: Color? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            VoxiverseSectionHeader(title: title)
            VoxiverseSurfaceCard {
                content()
            }
            .voxiverseFrostedBorder(tint: borderTint ?? Color.clear, cornerRadius: 18, when: borderTint != nil)
        }
        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
    }

    // MARK: - Frosted theming helpers

    /// Keep only the tiles whose value is non-empty (preserves the previous
    /// "show if present" behavior) so the alternating colors follow the tiles
    /// that are actually visible.
    private func presentTiles(_ pairs: [(String, String)]) -> [(String, String)] {
        pairs.filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// A two-column grid of frosted glass tiles, colored Purple/Berry/Blue by
    /// visible position.
    private func glassTileGrid(_ items: [(String, String)]) -> some View {
        // Eager two-column layout (VStack of HStacks) rather than LazyVGrid, so
        // the first row is never lazily dropped on body recomputation. Same
        // 2-up positions, spacing, and Purple/Berry/Blue-by-position coloring.
        let rowStarts = Array(stride(from: 0, to: items.count, by: 2))
        return VStack(spacing: 9) {
            ForEach(rowStarts, id: \.self) { start in
                HStack(spacing: 9) {
                    glassMetaTile(label: items[start].0, value: items[start].1, tint: VoxiverseFrostedPalette.color(at: start))
                    if start + 1 < items.count {
                        glassMetaTile(label: items[start + 1].0, value: items[start + 1].1, tint: VoxiverseFrostedPalette.color(at: start + 1))
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    /// Compact frosted glass tile preserving the metadata typography/sizing.
    private func glassMetaTile(label: String, value: String, tint: Color) -> some View {
        VoxiverseFrostedGlassCard(tint: tint, cornerRadius: 13, contentPadding: 13, minHeight: 68) {
            VStack(alignment: .leading, spacing: 7) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.8))
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
    }

    /// Reference-image row matching the other detail views: berry file icon
    /// stacked above the chevron, both the same size, no leading icon.
    private func attachmentRow(_ attachment: VoxiverseReportAttachment) -> some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 3) {
                Text(attachment.displayName)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                Text(attachment.detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }

            Spacer()

            VStack(spacing: 8) {
                VoxiverseFrostedGlassIcon(assetName: attachment.assetName, size: 21, tint: VoxiverseFrostedPalette.berry)
                VoxiverseFrostedGlassIcon(assetName: "chevright", size: 21, tint: VoxiverseFrostedPalette.silver)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 9)
    }

    private var screenDisplayName: String {
        let value = request.screenName.trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "Settings > Feature Request" || value == "Settings > Feature Requests" {
            return "Feature Requests"
        }
        return value
    }

    @MainActor
    private func statusSelectionChanged(_ rawValue: String) {
        guard
            let newStatus = request.allowedStatuses.first(where: { $0.rawValue == rawValue }),
            newStatus != request.status
        else { return }

        isUpdatingStatus = true
        Task {
            do {
                try await VoxiverseCloudKitReportSync.updateStatus(newStatus, for: request, in: modelContext)
                statusError = nil
            } catch {
                selectedStatus = request.status.rawValue
                statusError = error.localizedDescription
            }
            isUpdatingStatus = false
        }
    }

    /// Status pill frosted like the App Detail View title-card badge:
    /// white label over `VoxiverseFrostedGlassMaterial` tinted by the badge
    /// color. The shared `VoxiverseStatusBadge` is left unchanged.
    private func frostedBadge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(VoxiverseFrostedGlassMaterial(tint: tint, cornerRadius: 9))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var statusColor: Color {
        switch request.status {
        case .new, .considering:
            VoxiverseColor.secondaryAccent
        case .planned, .inProgress:
            VoxiverseColor.primaryAction
        case .shipped, .declined, .closed:
            VoxiverseColor.indicator
        }
    }
}
