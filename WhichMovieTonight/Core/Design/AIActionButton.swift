//
//  AIActionButton.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 30/04/2025.
//

import SwiftUI

struct AIActionButton: View {
    var title: String = "Suggest a Movie"
    var icon: String = "sparkles"
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                if isLoading {
                    LoadingIndicator()
                } else {
                    Image(systemName: "sparkles")
                }

                Text(title)
            }
            .padding()
            .frame(width: 250)
        }
        .background(
            ZStack {
                if !isDisabled {
                    AnimatedMeshGradient()
                        .mask {
                            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                                .stroke(lineWidth: 16)
                                .blur(radius: 8)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                                .stroke(.white, lineWidth: 3)
                                .blur(radius: 2)
                                .blendMode(.overlay)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                                .stroke(.white, lineWidth: 1)
                                .blur(radius: 1)
                                .blendMode(.overlay)
                        }
                }
            }
        )
        .cornerRadius(DesignSystem.largeRadius)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                .stroke(DesignSystem.primaryCyan.opacity(0.5), lineWidth: 1)
        )
        .primaryShadow()
        .foregroundColor(.primary)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                .stroke(DesignSystem.primaryCyan.opacity(0.5), lineWidth: 1)
        )
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .onTapGesture {
            if !isDisabled {
                triggerHaptic()
            }
        }
    }

//    private func setButtonText() -> String {
//        if isLoading {
//            "AI is searching"
//        } else {
//            ""
//        }
//    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    VStack {
        AIActionButton(action: {})
//        AIActionButton(is: .selectingGenres, action: {})
        AIActionButton(isDisabled: true, action: {})
    }
    .padding()
}

struct LoadingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(.primary, lineWidth: 2)
            .frame(width: 16, height: 16)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}
