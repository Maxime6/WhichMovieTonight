//
//  AISearchingView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct AISearchingView: View {
    @State private var animationPhase = 0.0
    @State private var textIndex = 0

    private let searchingTexts = [
        "L'IA analyse vos préférences...",
        "Recherche dans la base de données...",
        "Récupération des détails OMDB...",
        "Finalisation de la suggestion...",
    ]

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 40) {
                Spacer()
                animatedAIIcon
                loadingTextSection
                progressDots
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
    }

    private var backgroundGradient: some View {
        AnimatedMeshGradient()
            .mask(
                RoundedRectangle(cornerRadius: 55)
                    .stroke(lineWidth: 25)
                    .blur(radius: 10)
            )
            .ignoresSafeArea()
    }

    private var animatedAIIcon: some View {
        VStack(spacing: 24) {
            ZStack {
                rotatingRing
                pulsingCircle
                aiIcon
            }
        }
    }

    private var rotatingRing: some View {
        Circle()
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [.cyan, .purple, .pink, .cyan]),
                    center: .center
                ),
                lineWidth: 4
            )
            .frame(width: 120, height: 120)
            .rotationEffect(.degrees(animationPhase))
    }

    private var pulsingCircle: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 80, height: 80)
            .scaleEffect(1.0 + sin(animationPhase * .pi / 180) * 0.1)
    }

    private var aiIcon: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 32, weight: .medium))
            .foregroundStyle(.primary)
            .scaleEffect(1.0 + sin(animationPhase * .pi / 180) * 0.05)
    }

    private var loadingTextSection: some View {
        VStack(spacing: 16) {
            Text("IA en cours de recherche")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(searchingTexts[textIndex])
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.5), value: textIndex)
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< 4, id: \.self) { index in
                ProgressDot(index: index, animationPhase: animationPhase)
            }
        }
    }

    private func startAnimations() {
        // Rotation animation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }

        // Text cycling animation
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                textIndex = (textIndex + 1) % searchingTexts.count
            }
        }
    }
}

struct ProgressDot: View {
    let index: Int
    let animationPhase: Double

    var body: some View {
        Circle()
            .fill(.primary.opacity(0.3))
            .frame(width: 8, height: 8)
            .scaleEffect(
                sin(animationPhase * .pi / 180 + Double(index) * .pi / 2) > 0 ? 1.5 : 1.0
            )
            .animation(
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.15),
                value: animationPhase
            )
    }
}

#Preview {
    AISearchingView()
}
