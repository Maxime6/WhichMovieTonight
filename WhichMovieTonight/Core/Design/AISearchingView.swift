//
//  AISearchingView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct AISearchingView: View {
    let message: String
    let isSearchQuery: Bool
    let onCancel: (() -> Void)?

    @State private var animationPhase: CGFloat = 0

    init(message: String, isSearchQuery: Bool = false, onCancel: (() -> Void)? = nil) {
        self.message = message
        self.isSearchQuery = isSearchQuery
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            // Animated mesh gradient background
            AnimatedMeshGradient()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // AI Icon with animation
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(DesignSystem.primaryCyan.opacity(0.3), lineWidth: 2)
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(DesignSystem.primaryGradient)
                        .scaleEffect(1.0 + 0.1 * sin(animationPhase))
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                }

                // Loading text
                VStack(spacing: 16) {
                    Text(message)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Animated dots
                    HStack(spacing: 8) {
                        ForEach(0 ..< 3) { index in
                            Circle()
                                .fill(DesignSystem.primaryCyan)
                                .frame(width: 8, height: 8)
                                .scaleEffect(1.0 + 0.3 * sin(animationPhase + Double(index) * 0.5))
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: animationPhase)
                        }
                    }
                }

                Spacer()

                // Cancel button (only for search queries)
                if isSearchQuery, let onCancel = onCancel {
                    Button(action: onCancel) {
                        Text("Cancel Search")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(DesignSystem.mediumRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            // Start animation
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }
}

#Preview {
    AISearchingView(
        message: "Searching for the perfect movie...",
        isSearchQuery: true,
        onCancel: { print("Cancel tapped") }
    )
}
