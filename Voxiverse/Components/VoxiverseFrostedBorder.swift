import SwiftUI

/// The three canonical Voxiverse frosted-glass tints and the global alternating
/// sequence used across the design system: Purple → Berry Pink → Blue → repeat.
enum VoxiverseFrostedPalette {
    static let purple = VoxiverseColor.primaryAction   // #8875b5
    static let berry = VoxiverseColor.secondaryAccent  // #a1236f
    static let blue = VoxiverseColor.indicator         // #7187b8
    static let silver = Color(red: 0.74, green: 0.75, blue: 0.79)  // neutral silver-gray

    static let cycle: [Color] = [purple, berry, blue]

    /// Color for a given list position, following the repeating sequence.
    static func color(at index: Int) -> Color {
        cycle[((index % cycle.count) + cycle.count) % cycle.count]
    }
}

/// A reusable frosted colored PERIMETER that belongs to the same design family
/// as `VoxiverseFrostedGlassCard`, but leaves the element's interior untouched
/// (Treatment B). It combines a crisp structural colored edge with a small
/// amount of soft, blurred colored frost hugging the perimeter.
///
/// The soft diffusion is clipped to the shape so it stays a narrow frosted rim
/// and does NOT bloom outward into surrounding content. Apply it with the
/// `.voxiverseFrostedBorder(tint:cornerRadius:)` modifier, which preserves the
/// element's own corner radius.
///
///     someCard.voxiverseFrostedBorder(tint: VoxiverseFrostedPalette.purple,
///                                     cornerRadius: 18)
struct VoxiverseFrostedBorder: View {
    let tint: Color
    var cornerRadius: CGFloat = 16
    var width: CGFloat = 1.5

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        ZStack {
            // Soft frosted colored diffusion along the inner edge: a wider
            // stroke, blurred, then clipped to the shape so it stays a narrow
            // perimeter frost and never blooms outward into content.
            shape
                .stroke(tint.opacity(0.5), lineWidth: width * 3.5)
                .blur(radius: 4.5)
                .clipShape(shape)

            // Crisp-enough structural colored edge (inset, stays in bounds).
            shape
                .strokeBorder(tint.opacity(0.85), lineWidth: width)

            // Subtle luminous catch so the rim reads as frosted glass rather
            // than a flat stroke.
            shape
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), tint.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        }
        .compositingGroup()
        // Very tight outward halo so the edge isn't razor-cut. Kept faint and
        // short-reach so the color stays concentrated at the perimeter and does
        // not radiate a glow when many bordered cards are stacked.
        .shadow(color: tint.opacity(0.14), radius: 1.5)
        .allowsHitTesting(false)
    }
}

extension View {
    /// Apply the reusable frosted colored perimeter, preserving `cornerRadius`.
    func voxiverseFrostedBorder(tint: Color, cornerRadius: CGFloat = 16, width: CGFloat = 1.5) -> some View {
        overlay(
            VoxiverseFrostedBorder(tint: tint, cornerRadius: cornerRadius, width: width)
        )
    }

    /// Conditionally apply the frosted perimeter (no-op when `condition` is
    /// false), so callers can scope the border to a specific context.
    @ViewBuilder
    func voxiverseFrostedBorder(tint: Color, cornerRadius: CGFloat = 16, width: CGFloat = 1.5, when condition: Bool) -> some View {
        if condition {
            voxiverseFrostedBorder(tint: tint, cornerRadius: cornerRadius, width: width)
        } else {
            self
        }
    }
}
