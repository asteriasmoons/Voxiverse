import SwiftUI

struct VoxiverseAppCard: View {
    let app: VoxiverseManagedApp

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VoxiverseAppIcon(assetName: app.iconAssetName, size: 54)
                Spacer()
                VoxiverseAssetIcon(
                    assetName: "chevright",
                    size: 15,
                    tint: VoxiverseColor.secondaryText
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryText)
                Text("v\(app.version) · Build \(app.buildNumber)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }

            HStack(spacing: 7) {
                VoxiverseStatusBadge(
                    title: app.status.title,
                    accent: app.status == .beta
                        ? VoxiverseColor.secondaryAccent
                        : VoxiverseColor.indicator
                )
                if app.openReportCount > 0 {
                    Text("\(app.openReportCount) open")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(VoxiverseColor.secondaryText)
                }
            }
        }
        .padding(14)
        .frame(width: 190, alignment: .leading)
        .frame(minHeight: 192, alignment: .leading)
        .background(VoxiverseColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(VoxiverseColor.divider, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct VoxiverseReportCard: View {
    let report: VoxiverseReport
    let app: VoxiverseManagedApp?

    var body: some View {
        HStack(spacing: 12) {
            VoxiverseAppIcon(
                assetName: app?.iconAssetName ?? "appsphone",
                size: 48
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(app?.name ?? "Unknown App")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.primaryAction)
                Text(report.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VoxiverseColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(VoxiverseColor.divider, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private var statusColor: Color {
        switch report.status {
        case .new: VoxiverseColor.secondaryAccent
        case .inProgress: VoxiverseColor.primaryAction
        case .resolved, .closed: VoxiverseColor.indicator
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
                    .font(.system(size: 19, weight: .bold, design: .rounded))
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
