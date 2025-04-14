import SwiftUI

/// Design system colors for Findy app
enum FindyColors {
    // MARK: - Background Colors

    static let backgroundPrimary = Color("BackgroundPrimary")
//    static let backgroundPrimary = Color(.ultraThinMaterial)
    static let backgroundSecondary = Color("BackgroundSecondary")

    // MARK: - Brand Colors

    static let electricBlue = Color("ElectricBlue") // #0066FF - Bleu électrique principal
    static let neonCyan = Color("NeonCyan") // #00E1FF - Cyan lumineux
    static let neonBlue = Color("NeonBlue") // #2D5BFF - Bleu intermédiaire
    static let neonPurple = Color("NeonPurple") // #6E3BFF - Violet électrique
    static let deepPurple = Color("DeepPurple") // #4B0082 - Violet profond

    // MARK: - Text Colors

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)

    // MARK: - Gradients

    static let primaryGradient = LinearGradient(
        colors: [electricBlue, neonCyan, neonBlue, neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleGradient = LinearGradient(
        colors: [neonBlue, neonPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let glowGradient = RadialGradient(
        colors: [neonCyan.opacity(0.5), neonBlue.opacity(0.3), .clear],
        center: .center,
        startRadius: 0,
        endRadius: 100
    )

    // MARK: - Glow Colors

    static let blueGlow = electricBlue.opacity(0.5)
    static let cyanGlow = neonCyan.opacity(0.5)
    static let purpleGlow = neonPurple.opacity(0.5)

    // MARK: - Functional Colors

    static let success = Color("Success") // #00FF9F - Vert néon
    static let warning = Color("Warning") // #FFB800 - Orange néon
    static let error = Color("Error") // #FF3B3B - Rouge néon
}
