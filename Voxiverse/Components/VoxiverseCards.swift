import SwiftUI

struct VoxiverseAppCard: View {
    let app: VoxiverseManagedApp
    let reports: [VoxiverseReport]

    private var openReportCount: Int {
        VoxiverseDashboardData.openReportCount(for: app.id, reports: reports)
    }

    var body: some View {
        VStack(spacing: 8) {
            // The app icon breathes on its own — no separate container box.
            VoxiverseAppIcon(assetName: app.iconAssetName, size: 46)

            Text(app.name)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(openReportCount > 0 ? "\(openReportCount) open" : "Synced")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    openReportCount > 0
                        ? VoxiverseColor.secondaryAccent
                        : VoxiverseColor.secondaryText
                )
                .lineLimit(1)
        }
        .padding(11)
        .frame(width: 112, height: 112)
        // Dark Voxiverse card interior — the frosted colored perimeter is
        // applied by the caller (Treatment B).
        .background(VoxiverseColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct VoxiverseReportCard: View {
    let report: VoxiverseReport
    let app: VoxiverseManagedApp?
    var usesInlineAppHeader: Bool = false

    var body: some View {
        if usesInlineAppHeader {
            inlineAppHeaderCard
        } else {
            sideIconCard
        }
    }

    private var sideIconCard: some View {
        HStack(spacing: 12) {
            VoxiverseAppIcon(
                assetName: app?.iconAssetName ?? "appsphone",
                size: 48
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(app?.name ?? "Unknown App")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryAction)
                Text(report.title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .lineLimit(2)
                Text("\(report.reportType.rawValue) · \(report.priority.rawValue)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
                HStack(spacing: 8) {
                    VoxiverseStatusBadge(title: report.status.rawValue, accent: statusColor)
                    Text(report.submittedDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                }
            }

            Spacer(minLength: 0)
            VoxiverseAssetIcon(
                assetName: "chevright",
                size: 16,
                tint: VoxiverseColor.secondaryText
            )
        }
        .reportCardSurface()
    }

    private var inlineAppHeaderCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                VoxiverseAppIcon(
                    assetName: app?.iconAssetName ?? "appsphone",
                    size: 24,
                    cornerRadius: 6
                )

                Text(app?.name ?? "Unknown App")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryAction)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(report.title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .lineLimit(2)

                Text("\(report.reportType.rawValue) · \(report.priority.rawValue)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }

            HStack(spacing: 8) {
                frostedStatusBadge
                Text(report.submittedDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)

                Spacer(minLength: 8)

                VoxiverseAssetIcon(
                    assetName: "chevright",
                    size: 16,
                    tint: VoxiverseColor.secondaryText
                )
            }
        }
        .reportCardSurface()
    }

    /// Report List status pill, frosted exactly like the App Detail View
    /// title-card badge: white label over `VoxiverseFrostedGlassMaterial`
    /// tinted by the status color. Scoped to `VoxiverseReportCard`; the
    /// shared `VoxiverseStatusBadge` is unchanged.
    private var frostedStatusBadge: some View {
        Text(report.status.rawValue)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(VoxiverseFrostedGlassMaterial(tint: statusColor, cornerRadius: 9))
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
}

struct VoxiverseEmptyState: View {
    let assetName: String
    let title: String
    let subtitle: String?
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VoxiverseSurfaceCard {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(VoxiverseColor.raisedSurface)
                    VoxiverseAssetIcon(
                        assetName: assetName,
                        size: 42,
                        tint: VoxiverseColor.primaryAction
                    )
                }
                .frame(width: 76, height: 76)

                Text(title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                        .multilineTextAlignment(.center)
                }
                if let actionTitle, let action {
                    VoxiversePrimaryButton(actionTitle, action: action)
                        .frame(maxWidth: 230)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private extension View {
    func reportCardSurface() -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VoxiverseColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(VoxiverseColor.divider, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}
