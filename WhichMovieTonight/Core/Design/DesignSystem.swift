//
//  DesignSystem.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import SwiftUI

enum DesignSystem {
    // MARK: - Colors

    static let primaryCyan = Color.cyan
    static let primaryPurple = Color.purple
    static let accentBlue = Color.blue

    // MARK: - Gradients

    static let primaryGradient = LinearGradient(
        colors: [primaryCyan, accentBlue, primaryPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let verticalGradient = LinearGradient(
        colors: [primaryCyan, primaryPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleGradient = LinearGradient(
        colors: [primaryCyan.opacity(0.3), primaryPurple.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shadows

    static let primaryShadow = Shadow(
        color: primaryCyan.opacity(0.2),
        radius: 12,
        x: 0,
        y: 6
    )

    static let subtleShadow = Shadow(
        color: primaryPurple.opacity(0.1),
        radius: 8,
        x: 0,
        y: 4
    )

    // MARK: - Animations

    static let springAnimation = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let easeInOutAnimation = Animation.easeInOut(duration: 0.3)

    // MARK: - Corner Radius

    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    static let extraLargeRadius: CGFloat = 20
}

// MARK: - Shadow Helper

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions

extension View {
    func primaryGradientBackground() -> some View {
        background(DesignSystem.primaryGradient)
    }

    func subtleGradientBackground() -> some View {
        background(DesignSystem.subtleGradient)
    }

    func primaryShadow() -> some View {
        shadow(
            color: DesignSystem.primaryShadow.color,
            radius: DesignSystem.primaryShadow.radius,
            x: DesignSystem.primaryShadow.x,
            y: DesignSystem.primaryShadow.y
        )
    }

    func subtleShadow() -> some View {
        shadow(
            color: DesignSystem.subtleShadow.color,
            radius: DesignSystem.subtleShadow.radius,
            x: DesignSystem.subtleShadow.x,
            y: DesignSystem.subtleShadow.y
        )
    }

    func gradientBorder() -> some View {
        overlay(
            RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                .stroke(DesignSystem.primaryGradient, lineWidth: 1)
        )
    }

    func animatedGradientBorder() -> some View {
        overlay(
            AnimatedMeshGradient()
                .mask(
                    RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                        .stroke(lineWidth: 2)
                )
                .frame(height: 2)
        )
    }
}

// MARK: - Sparkle Animation

struct SparkleAnimation: View {
    @State private var isAnimating = false
    let delay: Double

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.yellow)
            .opacity(isAnimating ? 1.0 : 0.3)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .animation(
                .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
