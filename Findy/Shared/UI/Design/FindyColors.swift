import SwiftUI

/// Design system colors for Findy app
enum FindyColors {
    // MARK: - Background Colors

    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")

    // MARK: - Neon Colors

    static let neonBlue = Color("NeonBlue")
    static let neonPurple = Color("NeonPurple")

    // MARK: - Text Colors

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)

    // MARK: - Gradients

    static let neonGradient = LinearGradient(
        colors: [neonBlue, neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Glow Colors

    static let blueGlow = neonBlue.opacity(0.5)
    static let purpleGlow = neonPurple.opacity(0.5)
}
