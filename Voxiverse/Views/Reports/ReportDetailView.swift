import SwiftUI
import UIKit
import SwiftData

struct ReportDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let report: VoxiverseReport
    let apps: [VoxiverseManagedApp]
    @State private var selectedAttachment: VoxiverseReportAttachment?
    @State private var selectedStatus: String
    @State private var expandedDropdownID: String?
    @State private var isUpdatingStatus = false
    @State private var statusError: String?
    @State private var showConversation = false
    @State private var conversationState: ReportConversationState = .notStarted
    @State private var conversationUnreadCount = 0

    init(report: VoxiverseReport, apps: [VoxiverseManagedApp], openConversationOnAppear: Bool = false) {
        self.report = report
        self.apps = apps
        _selectedStatus = State(initialValue: report.status.rawValue)
        _showConversation = State(initialValue: openConversationOnAppear)
    }

    private var app: VoxiverseManagedApp? {
        apps.matchingApp(id: report.appID)
    }


    var body: some View {
        ZStack {
            reportContent

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

    private var reportContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 23) {
                VoxiverseHeader(title: report.reportID, subtitle: "Report detail", closeButton: true)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Text(report.title)
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
                        frostedBadge(report.status.rawValue, tint: statusColor)
                        frostedBadge(report.priority.rawValue, tint: priorityColor)
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Report Metadata")
                    VoxiverseSurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(spacing: 9) {
                                HStack(spacing: 9) {
                                    metaTile("App", app?.name ?? "Unknown App", index: 0)
                                    metaTile("Reporter", report.reporter, index: 1)
                                }
                                HStack(spacing: 9) {
                                    metaTile("Report Type", report.reportType.rawValue, index: 2)
                                    metaTile("Submitted", report.submittedDate.formatted(.dateTime.month(.abbreviated).day().year()), index: 3)
                                }
                            }

                            VoxiverseDropdown(
                                id: "report-status",
                                title: "Status",
                                options: report.allowedStatuses.map(\.rawValue),
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
                    .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                if report.reportType == .betaFeedback {
                    betaFeedbackSections
                } else {
                    bugReportSections
                }

                detailSection(title: "Attachments", borderTint: VoxiverseFrostedPalette.berry) {
                    if let attachments = report.attachments, !attachments.isEmpty {
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
                        Text("No attachments were included with this report.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(VoxiverseColor.secondaryText)
                    }
                }

                detailSection(title: "App Diagnostics", borderTint: VoxiverseFrostedPalette.blue) {
                    VStack(spacing: 9) {
                        HStack(spacing: 9) {
                            metaTile("Device", report.deviceModel, index: 0)
                            metaTile("iOS Version", report.iOSVersion, index: 1)
                        }
                        HStack(spacing: 9) {
                            metaTile("App Version", report.appVersion, index: 2)
                            metaTile("Build", report.buildNumber, index: 3)
                        }
                        HStack(spacing: 9) {
                            metaTile("Timestamp", report.submittedDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()), index: 4)
                            metaTile("Screen", report.reportType == .betaFeedback ? "Beta Feedback" : report.screenName, index: 5)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var conversationContext: ReportConversationContext {
        ReportConversationContext(report: report, app: app)
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

    @MainActor
    private func statusSelectionChanged(_ rawValue: String) {
        guard
            let newStatus = report.allowedStatuses.first(where: { $0.rawValue == rawValue }),
            newStatus != report.status
        else { return }

        isUpdatingStatus = true
        Task {
            do {
                try await VoxiverseCloudKitReportSync.updateStatus(newStatus, for: report, in: modelContext)
                statusError = nil
            } catch {
                selectedStatus = report.status.rawValue
                statusError = error.localizedDescription
            }
            isUpdatingStatus = false
        }
    }

    @ViewBuilder
    private var betaFeedbackSections: some View {
        detailSection(title: "Feedback Details", borderTint: VoxiverseFrostedPalette.berry) {
            HStack(spacing: 9) {
                glassMetaTile(label: "Area", value: report.category, tint: VoxiverseFrostedPalette.purple)
                glassMetaTile(label: "Experience", value: report.overallExperience, tint: VoxiverseFrostedPalette.berry)
            }
        }

        feedbackTextSection(title: "What Did You Test?", text: report.testedWhat.isEmpty ? report.description : report.testedWhat, borderTint: VoxiverseFrostedPalette.blue)
        feedbackTextSection(title: "What Worked Well?", text: report.workedWell, borderTint: VoxiverseFrostedPalette.purple)
        feedbackTextSection(title: "What Could Be Better?", text: report.couldBeBetter, borderTint: VoxiverseFrostedPalette.berry)
        feedbackTextSection(title: "Anything Unexpected?", text: report.anythingUnexpected, borderTint: VoxiverseFrostedPalette.blue)
        feedbackTextSection(title: "Additional Thoughts", text: report.internalNotes, borderTint: VoxiverseFrostedPalette.purple)
    }

    private var bugReportSections: some View {
        Group {
            detailSection(title: "Description", borderTint: VoxiverseFrostedPalette.berry) {
                Text(report.description)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
                    .lineSpacing(4)
            }

            detailSection(title: "Expected Behavior", borderTint: VoxiverseFrostedPalette.blue) {
                Text(report.expectedBehavior)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
                    .lineSpacing(4)
            }

            detailSection(title: "Steps to Reproduce", borderTint: VoxiverseFrostedPalette.purple) {
                VStack(alignment: .leading, spacing: 11) {
                    ForEach(Array(report.stepsToReproduce.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Color.white)
                                .frame(width: 24, height: 24)
                                .background(
                                    VoxiverseFrostedGlassMaterial(
                                        tint: VoxiverseFrostedPalette.color(at: index),
                                        cornerRadius: 12
                                    )
                                )
                                .clipShape(Circle())
                            Text(step)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func feedbackTextSection(title: String, text: String, borderTint: Color) -> some View {
        detailSection(title: title, borderTint: borderTint) {
            Text(text.isEmpty ? "No response was provided." : text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(text.isEmpty ? VoxiverseColor.secondaryText.opacity(0.7) : VoxiverseColor.secondaryText)
                .lineSpacing(4)
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

    // MARK: - Beta Feedback theming helpers

    /// A metadata tile that becomes a frosted glass tile in the Beta Feedback
    /// layout (alternating Purple/Berry/Blue), and stays the plain tile
    /// otherwise so bug reports are unchanged.
    private func metaTile(_ label: String, _ value: String, index: Int) -> some View {
        glassMetaTile(label: label, value: value, tint: VoxiverseFrostedPalette.color(at: index))
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

    /// Attachment row: Beta Feedback moves the (berry) file icon above the
    /// chevright and matches their sizes; other report types keep the original.
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
        switch report.status {
        case .new: VoxiverseColor.secondaryAccent
        case .reviewing, .inProgress: VoxiverseColor.primaryAction
        case .resolved, .reviewed, .closed: VoxiverseColor.indicator
        case .actionNeeded: VoxiverseColor.secondaryAccent
        }
    }

    private var priorityColor: Color {
        switch report.priority {
        case .low: VoxiverseColor.indicator
        case .medium: VoxiverseColor.primaryAction
        case .high, .critical: VoxiverseColor.secondaryAccent
        }
    }

}

struct VoxiverseAttachmentPreviewOverlay: View {
    let attachment: VoxiverseReportAttachment
    let onClose: () -> Void

    private var previewImage: UIImage? {
        guard let fileURL = attachment.localFileURL else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    private var hasLocalFile: Bool {
        guard let fileURL = attachment.localFileURL else { return false }
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VoxiverseColor.background.opacity(0.96)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Attachment")
                            .font(.system(size: 31, weight: .black, design: .rounded))
                            .foregroundStyle(VoxiverseColor.primaryText)
                        Text(attachment.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(VoxiverseColor.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    VoxiverseIconButton(assetName: "xmarkwavy", label: "Close", action: onClose)
                }

                VoxiverseSurfaceCard {
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .background(VoxiverseColor.raisedSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            VoxiverseAssetIcon(assetName: attachment.assetName, size: 34, tint: VoxiverseColor.indicator)
                                .frame(width: 54, height: 54)
                                .background(VoxiverseColor.raisedSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Text(hasLocalFile ? "This attachment is saved, but Voxiverse cannot preview this file type yet." : "This attachment file is not available on this device yet.")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(VoxiverseColor.primaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(attachment.detail)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple, cornerRadius: 18)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
            .padding(.top, 22)
        }
    }
}
