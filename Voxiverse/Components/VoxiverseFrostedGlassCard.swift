import SwiftUI

/// The approved Voxiverse frosted-glass MATERIAL, with no content — the single
/// source of truth for the look. It is exactly the recipe tuned on the Home
/// statistic tiles: a blurred internal color field, native Liquid Glass on top,
/// and irregular surface frost, all clipped to a rounded rectangle. Use it as a
/// `.background(...)` behind any content, or via `VoxiverseFrostedGlassCard`.
struct VoxiverseFrostedGlassMaterial: View {
    /// The colored dye suspended within the glass.
    let tint: Color
    var cornerRadius: CGFloat = 17

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        ZStack {
            // The internal colored frosted field the glass diffuses.
            coloredField

            // Native translucent glass on top, lightly tinted.
            Color.clear
                .glassEffect(.regular.tint(tint.opacity(0.22)), in: shape)

            // Soft, irregular milky frost sitting at the surface of the glass:
            // a few heavily blurred low-opacity clouds that make some regions
            // read cloudier/milkier while others stay clearer — the uneven
            // optical density of real frosted glass. No crisp shapes, no
            // full-card wash.
            frostClouds
        }
        // Clip EVERYTHING to the rounded rect so the frost/color/blur ends at
        // the edge instead of spilling outward.
        .clipShape(shape)
    }

    private var coloredField: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Translucent color body — dye in glass, not a solid fill.
                tint.opacity(0.5)

                // Milky light region (upper-left): slightly lighter, frostier.
                Ellipse()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: w * 1.15, height: h * 1.05)
                    .offset(x: -w * 0.28, y: -h * 0.4)

                // Rich, saturated pocket of the pure tint (lower-center):
                // keeps the color clearly readable and slightly denser there.
                Ellipse()
                    .fill(tint)
                    .frame(width: w * 1.0, height: h * 0.95)
                    .offset(x: w * 0.04, y: h * 0.26)

                // Soft depth (lower-right) using the app's dark environment
                // color: slightly darker, more diffused there.
                Ellipse()
                    .fill(VoxiverseColor.background.opacity(0.4))
                    .frame(width: w * 0.9, height: h * 0.85)
                    .offset(x: w * 0.36, y: h * 0.4)
            }
            // Heavy blur → cloudy pigment; oversized + scaled so it fills the
            // area fully and is then clipped cleanly at the rounded edge.
            .blur(radius: 28)
            .frame(width: w, height: h)
            .scaleEffect(1.15)
        }
    }

    // Surface frost: irregular milky diffusion, clipped with the rest of the
    // material to the shape. Kept low-opacity and softly blurred so the tint
    // stays clearly recognizable through it.
    private var frostClouds: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Milky cloud drifting through the center-left.
                Ellipse()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: w * 0.95, height: h * 0.7)
                    .offset(x: -w * 0.16, y: -h * 0.08)
                    .blur(radius: 26)

                // A softer milky pocket lower-right, leaving clearer glass
                // between it and the cloud above.
                Ellipse()
                    .fill(Color.white.opacity(0.11))
                    .frame(width: w * 0.7, height: h * 0.6)
                    .offset(x: w * 0.3, y: h * 0.2)
                    .blur(radius: 24)

                // A faint upper haze to keep the diffusion uneven, not paired.
                Ellipse()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: w * 0.6, height: h * 0.5)
                    .offset(x: w * 0.12, y: -h * 0.32)
                    .blur(radius: 22)
            }
            .frame(width: w, height: h)
        }
    }
}

/// Reusable frosted colored-glass CONTAINER (Treatment A): the approved
/// `VoxiverseFrostedGlassMaterial` plus container styling (padding, sizing,
/// depth, and the restrained ~6pt colored edge glow). Tint-configurable and
/// content-agnostic.
///
///     VoxiverseFrostedGlassCard(tint: someColor) {
///         // whatever belongs inside this card
///     }
struct VoxiverseFrostedGlassCard<Content: View>: View {
    /// The colored dye suspended within the glass.
    let tint: Color
    /// Corner radius of the glass slab. Defaults to the Home tile value.
    var cornerRadius: CGFloat = 17
    /// Inner padding around the content. Defaults to the Home tile value.
    var contentPadding: CGFloat = 15
    /// Optional minimum height; `nil` lets the content size the card.
    var minHeight: CGFloat? = nil
    /// Content alignment within the card. Defaults to the Home tile value.
    var alignment: Alignment = .leading
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(contentPadding)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: alignment)
            .background(VoxiverseFrostedGlassMaterial(tint: tint, cornerRadius: cornerRadius))
            // Depth, plus a very restrained colored edge glow (~6pt) — no bloom.
            .shadow(color: VoxiverseColor.background.opacity(0.5), radius: 8, y: 5)
            .shadow(color: tint.opacity(0.32), radius: 6)
    }
}


/// An ICON-SCALE variant of the frosted-glass material. It shares the design
/// language, palette, translucency, and frost identity of the canonical
/// `VoxiverseFrostedGlassMaterial`, but its internal variation is a single
/// broad, continuous, low-contrast gradient across the WHOLE frame rather than
/// large localized ellipse blobs. That matters when the material is masked into
/// a tiny irregular glyph: a full-frame gradient shows smooth shading anywhere
/// the glyph samples it, so nothing looks like a bright/cloudy patch chopped off
/// at the icon's edge. The canonical card recipe is intentionally left
/// unchanged.
struct VoxiverseFrostedGlassIconMaterial: View {
    let tint: Color

    var body: some View {
        ZStack {
            // Translucent colored body so the glyph clearly reads as its tint.
            tint.opacity(0.85)

            // Native glass for real translucency + frost identity. At icon
            // scale its specular/edge highlights would otherwise show as tiny
            // bright-white spots along the glyph, so the glass layer is: tinted
            // more strongly (so any specular is colored, not white), softened
            // with a small blur (so no highlight has a hard edge), and held at
            // low opacity (so its contribution stays a gentle frost). Frost and
            // translucency remain; the abrupt white spots do not.
            Color.clear
                .glassEffect(.regular.tint(tint.opacity(0.22)), in: Rectangle())
                .blur(radius: 1.2)
                .opacity(0.32)

            // Broad, continuous, low-contrast shading spanning the entire frame:
            // a whisper of diffuse light easing from the top-left into soft
            // depth at the bottom-right. Because it is continuous edge-to-edge,
            // any masked glyph region shows smooth dimensional shading instead
            // of an abruptly clipped patch.
            LinearGradient(
                colors: [
                    Color.white.opacity(0.24),
                    Color.white.opacity(0.05),
                    VoxiverseColor.background.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// Applies the icon-scale frosted-glass material DIRECTLY to an icon's own
/// silhouette — there is no backing container, card, or shape. The material is
/// masked by the icon glyph, so the icon itself becomes the tinted, frosted,
/// translucent glass surface while keeping its recognizable shape.
struct VoxiverseFrostedGlassIcon: View {
    let assetName: String
    let size: CGFloat
    let tint: Color

    var body: some View {
        VoxiverseFrostedGlassIconMaterial(tint: tint)
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
