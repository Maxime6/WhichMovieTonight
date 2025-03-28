import SwiftUI

// MARK: - Neon Glow Modifier

struct NeonGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius * 0.5)
    }
}

// MARK: - Glass Background Modifier

struct GlassBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: FindyLayout.cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: FindyLayout.cornerRadius)
                            .stroke(FindyColors.textPrimary.opacity(0.1), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - View Extensions

extension View {
    func neonGlow(
        color: Color = FindyColors.neonBlue,
        radius: CGFloat = FindyEffects.neonGlow
    ) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius))
    }

    func glassBackground() -> some View {
        modifier(GlassBackgroundModifier())
    }
}
