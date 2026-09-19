import SwiftUI

// MARK: - Tri-color frosted glass
//
// A tri-color variant of the Voxiverse frosted-glass family. The three palette
// colors (Purple | Berry | Blue, the `VoxiverseFrostedPalette.cycle` order) are
// arranged in a HORIZONTAL ROW as three equal vertical sections. Each section is
// its own solid slab of the approved frosted-glass material, hard-clipped to its
// third so the colors are fully contained — NO gradient, NO blending between
// sections.
//
// Three public pieces mirror the single-tint family, one per use:
//   • `VoxiverseTriFrostedBorder` / `.voxiverseTriFrostedBorder()` — a perimeter.
//   • `VoxiverseTriFrostedGlassIcon` — the material masked into an icon glyph.
//   • `VoxiverseTriFrostedGlassCard` — the material as a card container.
//
// Nothing here changes the existing single-tint components; each section simply
// reuses them at one of the three shared `VoxiverseFrostedPalette` colors.

/// The three palette colors in their canonical left-to-right order.
private enum VoxiverseTriPalette {
    static let purple = VoxiverseFrostedPalette.purple
    static let berry = VoxiverseFrostedPalette.berry
    static let blue = VoxiverseFrostedPalette.blue

    /// Hard-edged Purple | Berry | Blue bands as a ShapeStyle (for strokes).
    /// Repeating each color at the segment boundary gives crisp transitions with
    /// no blend between the three thirds.
    static func hardBands(opacity: Double) -> LinearGradient {
        let p = purple.opacity(opacity)
        let b = berry.opacity(opacity)
        let l = blue.opacity(opacity)
        return LinearGradient(
            stops: [
                .init(color: p, location: 0),
                .init(color: p, location: 1.0 / 3.0),
                .init(color: b, location: 1.0 / 3.0),
                .init(color: b, location: 2.0 / 3.0),
                .init(color: l, location: 2.0 / 3.0),
                .init(color: l, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Material (card / fill scale)

/// The tri-color frosted-glass MATERIAL, content-free. Three equal vertical
/// sections, each the approved `VoxiverseFrostedGlassMaterial` at one palette
/// color, hard-clipped so nothing bleeds across a boundary. The outer rounded
/// corners are applied once to the whole slab.
struct VoxiverseTriFrostedGlassMaterial: View {
    var cornerRadius: CGFloat = 17

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 0) {
            section(VoxiverseTriPalette.purple)
            section(VoxiverseTriPalette.berry)
            section(VoxiverseTriPalette.blue)
        }
        .clipShape(shape)
    }

    // One vertical third: the single-color material with square corners so the
    // three sections butt together with a crisp seam.
    private func section(_ tint: Color) -> some View {
        VoxiverseFrostedGlassMaterial(tint: tint, cornerRadius: 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Card container

/// Reusable tri-color frosted-glass CONTAINER: the tri-section material plus
/// container styling (padding, sizing, depth, and a restrained colored edge
/// glow). Mirrors `VoxiverseFrostedGlassCard`.
///
///     VoxiverseTriFrostedGlassCard {
///         // whatever belongs inside this card
///     }
struct VoxiverseTriFrostedGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 17
    var contentPadding: CGFloat = 15
    var minHeight: CGFloat? = nil
    var alignment: Alignment = .leading
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(contentPadding)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: alignment)
            .background(VoxiverseTriFrostedGlassMaterial(cornerRadius: cornerRadius))
            // Depth, plus a restrained edge glow drawn from both ends of the
            // palette so the halo stays balanced across the three sections.
            .shadow(color: VoxiverseColor.background.opacity(0.5), radius: 8, y: 5)
            .shadow(color: VoxiverseTriPalette.purple.opacity(0.22), radius: 6)
            .shadow(color: VoxiverseTriPalette.blue.opacity(0.22), radius: 6)
    }
}

// MARK: - Icon fill

/// Icon-scale tri-color material: three equal vertical sections, each the
/// approved `VoxiverseFrostedGlassIconMaterial` at one palette color, so a
/// masked glyph shows Purple | Berry | Blue in hard vertical thirds with no
/// blending. Mirrors `VoxiverseFrostedGlassIconMaterial`.
struct VoxiverseTriFrostedGlassIconMaterial: View {
    var body: some View {
        HStack(spacing: 0) {
            VoxiverseFrostedGlassIconMaterial(tint: VoxiverseTriPalette.purple)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VoxiverseFrostedGlassIconMaterial(tint: VoxiverseTriPalette.berry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VoxiverseFrostedGlassIconMaterial(tint: VoxiverseTriPalette.blue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Applies the icon-scale tri-color frosted-glass material directly to an icon's
/// own silhouette — no backing container. The material is masked by the glyph,
/// so the icon itself becomes the three-section tri-color glass. Mirrors
/// `VoxiverseFrostedGlassIcon`.
struct VoxiverseTriFrostedGlassIcon: View {
    let assetName: String
    let size: CGFloat

    var body: some View {
        VoxiverseTriFrostedGlassIconMaterial()
            .frame(width: size, height: size)
            .mask(
                Image(assetName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: size, height: size)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Border

/// A tri-color frosted PERIMETER — the same construction as `VoxiverseFrostedBorder`
/// (soft blurred rim clipped to the shape, crisp structural edge, luminous catch)
/// but stroked with hard Purple | Berry | Blue bands (no blend). Apply it with
/// the `.voxiverseTriFrostedBorder(cornerRadius:)` modifier.
struct VoxiverseTriFrostedBorder: View {
    var cornerRadius: CGFloat = 16
    var width: CGFloat = 1.5

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        ZStack {
            // Soft frosted band diffusion along the inner edge, clipped so it
            // stays a narrow perimeter frost and never blooms outward.
            shape
                .stroke(VoxiverseTriPalette.hardBands(opacity: 0.5), lineWidth: width * 3.5)
                .blur(radius: 4.5)
                .clipShape(shape)

            // Crisp structural three-band edge (inset, stays in bounds).
            shape
                .strokeBorder(VoxiverseTriPalette.hardBands(opacity: 0.85), lineWidth: width)

            // Subtle luminous catch so the rim reads as frosted glass rather than
            // a flat stroke.
            shape
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        }
        .compositingGroup()
        // Very tight outward halo (kept faint and short-reach, balanced from the
        // palette center) so the edge isn't razor-cut.
        .shadow(color: VoxiverseTriPalette.berry.opacity(0.13), radius: 1.5)
        .allowsHitTesting(false)
    }
}

extension View {
    /// Apply the reusable tri-color frosted perimeter, preserving `cornerRadius`.
    func voxiverseTriFrostedBorder(cornerRadius: CGFloat = 16, width: CGFloat = 1.5) -> some View {
        overlay(
            VoxiverseTriFrostedBorder(cornerRadius: cornerRadius, width: width)
        )
    }

    /// Conditionally apply the tri-color frosted perimeter (no-op when `condition`
    /// is false), so callers can scope the border to a specific context.
    @ViewBuilder
    func voxiverseTriFrostedBorder(cornerRadius: CGFloat = 16, width: CGFloat = 1.5, when condition: Bool) -> some View {
        if condition {
            voxiverseTriFrostedBorder(cornerRadius: cornerRadius, width: width)
        } else {
            self
        }
    }
}
