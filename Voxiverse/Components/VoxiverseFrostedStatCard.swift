import SwiftUI

/// The Home statistic tile: white indicator mark, statistic value, and label,
/// rendered inside a reusable `VoxiverseFrostedGlassCard`. The frosted-glass
/// material now lives entirely in that container — this type only supplies the
/// stat content and the tint, so the tiles look exactly as before.
///
/// Used only by the three Home statistic tiles.
struct VoxiverseFrostedStatCard: View {
    let label: String
    let value: String
    /// The base material color. Home passes the exact theme accents:
    /// Open Reports #8875b5, Feature Requests #a1236f, Apps in Beta #7187b8.
    let baseColor: Color

    var body: some View {
        VoxiverseFrostedGlassCard(tint: baseColor, minHeight: 122) {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 24, height: 4)

                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 4, y: 1)

                Text(label)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.45), radius: 3, y: 1)
                    .lineLimit(2)
            }
        }
    }
}
