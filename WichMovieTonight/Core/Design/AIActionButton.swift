//
//  AIActionButton.swift
//  WichMovieTonight
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
    @State var counter: Int = 0
    @State var origin: CGPoint = .zero
    
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
                
                Text(isLoading ? "Searching Movie" : "Which Movie Tonight ?")
            }
            .padding()
            .frame(width: 250)
        }
        .background(
            ZStack {
                if !isDisabled {
                    AnimatedMeshGradient()
                        .mask {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(lineWidth: 16)
                                .blur(radius: 8)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white, lineWidth: 3)
                                .blur(radius: 2)
                                .blendMode(.overlay)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white, lineWidth: 1)
                                .blur(radius: 1)
                                .blendMode(.overlay)
                        }
                }
            }
        )
        .cornerRadius(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .cyan.opacity(0.15), radius: 20, x: 0, y: 20)
        .shadow(color: .purple.opacity(0.1), radius: 15, x: 0, y: 15)
        .foregroundColor(.primary)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.cyan.opacity(0.5), lineWidth: 1)
        )
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .onPressingChanged { point in
            if !isDisabled {
                if let point {
                    origin = point
                    counter += 1
                }
                
                triggerHaptic()
            }
        }
        .modifier(RippleEffect(at: origin, trigger: counter))
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    VStack {
        AIActionButton(action: {})
        AIActionButton(isLoading: true, action: {})
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
