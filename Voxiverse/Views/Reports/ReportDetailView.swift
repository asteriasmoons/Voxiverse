import SwiftUI
import UIKit

struct ReportDetailView: View {
    let report: VoxiverseReport
    let apps: [VoxiverseManagedApp]
    @State private var selectedAttachment: VoxiverseReportAttachment?

    private var app: VoxiverseManagedApp? {
        apps.first(where: { $0.id == report.appID })
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
        }
        .background(VoxiverseColor.background)
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.16), value: selectedAttachment?.id)
    }

    private var reportContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 23) {
                VoxiverseHeader(title: report.reportID, subtitle: "Report detail", closeButton: true)

                VStack(alignment: .leading, spacing: 12) {
                    Text(report.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(VoxiverseColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        VoxiverseStatusBadge(title: report.status.rawValue, accent: statusColor)
                        VoxiverseStatusBadge(title: report.priority.rawValue, accent: priorityColor)
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                VStack(alignment: .leading, spacing: 11) {
                    VoxiverseSectionHeader(title: "Report Metadata")
                    VoxiverseSurfaceCard {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                            VoxiverseMetadataTile(label: "App", value: app?.name ?? "Unknown App")
                            VoxiverseMetadataTile(label: "Reporter", value: report.reporter)
                            VoxiverseMetadataTile(label: "Report Type", value: report.reportType.rawValue)
                            VoxiverseMetadataTile(label: "Submitted", value: report.submittedDate.formatted(.dateTime.month(.abbreviated).day().year()))
                        }
                    }
                }
                .padding(.horizontal, VoxiverseSpacing.pageHorizontal)

                detailSection(title: "Description") {
                    Text(report.description)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                        .lineSpacing(4)
                }

                detailSection(title: "Expected Behavior") {
                    Text(report.expectedBehavior)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                        .lineSpacing(4)
                }

                detailSection(title: "Steps to Reproduce") {
                    VStack(alignment: .leading, spacing: 11) {
                        ForEach(Array(report.stepsToReproduce.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(VoxiverseColor.primaryText)
                                    .frame(width: 24, height: 24)
                                    .background(stepAccent(for: index))
                                    .clipShape(Circle())
                                Text(step)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(VoxiverseColor.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                detailSection(title: "Attachments") {
                    if let attachments = report.attachments, !attachments.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(attachments, id: \.id) { attachment in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        selectedAttachment = attachment
                                    }
                                } label: {
                                    HStack(spacing: 11) {
                                        VoxiverseAssetIcon(assetName: attachment.assetName, size: 21, tint: VoxiverseColor.indicator)
                                            .frame(width: 28)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(attachment.name)
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundStyle(VoxiverseColor.primaryText)
                                            Text(attachment.detail)
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                                .foregroundStyle(VoxiverseColor.secondaryText)
                                        }
                                        Spacer()
                                        VoxiverseAssetIcon(assetName: "chevright", size: 15, tint: VoxiverseColor.secondaryText)
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.vertical, 9)
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

                detailSection(title: "App Diagnostics") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                        VoxiverseMetadataTile(label: "Device", value: report.deviceModel)
                        VoxiverseMetadataTile(label: "iOS Version", value: report.iOSVersion)
                        VoxiverseMetadataTile(label: "App Version", value: report.appVersion)
                        VoxiverseMetadataTile(label: "Build", value: report.buildNumber)
                        VoxiverseMetadataTile(label: "Timestamp", value: report.submittedDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        VoxiverseMetadataTile(label: "Screen", value: report.screenName)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            VoxiverseSectionHeader(title: title)
            VoxiverseSurfaceCard {
                content()
            }
        }
        .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
    }

    private var statusColor: Color {
        switch report.status {
        case .new: VoxiverseColor.secondaryAccent
        case .inProgress: VoxiverseColor.primaryAction
        case .resolved, .closed: VoxiverseColor.indicator
        }
    }

    private var priorityColor: Color {
        switch report.priority {
        case .low: VoxiverseColor.indicator
        case .medium: VoxiverseColor.primaryAction
        case .high, .critical: VoxiverseColor.secondaryAccent
        }
    }

    private func stepAccent(for index: Int) -> Color {
        switch index % 3 {
        case 0: VoxiverseColor.primaryAction
        case 1: VoxiverseColor.secondaryAccent
        default: VoxiverseColor.indicator
        }
    }
}

private struct VoxiverseAttachmentPreviewOverlay: View {
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
                            .font(.system(size: 31, weight: .bold, design: .rounded))
                            .foregroundStyle(VoxiverseColor.primaryText)
                        Text(attachment.name)
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
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(VoxiverseColor.primaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(attachment.detail)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(VoxiverseColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, VoxiverseSpacing.pageHorizontal)
            .padding(.top, 22)
        }
    }
}
