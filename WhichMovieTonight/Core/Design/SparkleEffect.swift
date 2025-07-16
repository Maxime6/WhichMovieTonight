//
//  SparkleEffect.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import SwiftUI

struct SparkleEffect: View {
    @State private var isAnimating = false
    let sparkleCount: Int
    let radius: CGFloat
    let delay: Double

    init(sparkleCount: Int = 6, radius: CGFloat = 30, delay: Double = 0.0) {
        self.sparkleCount = sparkleCount
        self.radius = radius
        self.delay = delay
    }

    var body: some View {
        ZStack {
            ForEach(0 ..< sparkleCount, id: \.self) { index in
                SparkleAnimation(delay: delay + Double(index) * 0.1)
                    .offset(
                        x: cos(Double(index) * 2 * .pi / Double(sparkleCount)) * radius,
                        y: sin(Double(index) * 2 * .pi / Double(sparkleCount)) * radius
                    )
            }
        }
        .onAppear {
            withAnimation(DesignSystem.springAnimation.delay(delay)) {
                isAnimating = true
            }
        }
    }
}

struct SparkleButton: View {
    let action: () -> Void
    let icon: String
    let title: String
    @State private var showSparkles = false

    var body: some View {
        Button(action: {
            showSparkles = true
            action()

            // Hide sparkles after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showSparkles = false
            }
        }) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .foregroundStyle(DesignSystem.primaryGradient)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                            .stroke(DesignSystem.primaryGradient, lineWidth: 1)
                            .blur(radius: 0.5)
                    )
            )
            .subtleShadow()
        }
        .overlay(
            SparkleEffect(sparkleCount: 8, radius: 40)
                .opacity(showSparkles ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: showSparkles)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        SparkleEffect()
            .frame(width: 100, height: 100)

        SparkleButton(action: {}, icon: "sparkles", title: "Generate")
    }
    .padding()
}
