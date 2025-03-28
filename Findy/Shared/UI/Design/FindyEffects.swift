import SwiftUI

/// Visual effects constants for Findy app
enum FindyEffects {
    // MARK: - Blur Effects

    static let backgroundBlur: CGFloat = 20.0
    static let cardBlur: CGFloat = 15.0

    // MARK: - Glow Effects

    static let neonGlow: CGFloat = 15.0
    static let softGlow: CGFloat = 8.0

    // MARK: - Opacity Values

    static let cardOpacity: CGFloat = 0.15
    static let overlayOpacity: CGFloat = 0.08

    // MARK: - Animation Constants

    static let buttonPressAnimation = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let cardAppearAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let glowPulseAnimation = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
}
