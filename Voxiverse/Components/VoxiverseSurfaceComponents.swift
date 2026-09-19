import SwiftUI

struct VoxiverseSurfaceCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VoxiverseColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(VoxiverseColor.divider, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: VoxiverseColor.background.opacity(0.54), radius: 12, y: 6)
    }
}

struct VoxiverseStatCard: View {
    let label: String
    let value: String
    let accent: VoxiverseMetricAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Rectangle()
                .fill(accent.color)
                .frame(width: 24, height: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryText)
            Text(label)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.secondaryText)
                .lineLimit(2)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .background(VoxiverseColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(accent.color.opacity(0.32), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .shadow(color: accent.color.opacity(0.08), radius: 10, y: 5)
    }
}

struct VoxiverseStatusBadge: View {
    let title: String
    var accent: Color = VoxiverseColor.indicator

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(accent.opacity(0.14))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(accent.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

struct VoxiverseSectionHeader: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryText)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(VoxiverseColor.secondaryText)
            }
        }
    }
}

struct VoxiverseMetadataTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(VoxiverseColor.secondaryText)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(VoxiverseColor.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 68, maxHeight: 68, alignment: .leading)
        .background(VoxiverseColor.raisedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}
