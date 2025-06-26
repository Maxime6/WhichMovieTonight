import SwiftUI

struct OnboardingActionButton: View {
    var title: String
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
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
                                .stroke(.white, lineWidth: 1)
                                .blur(radius: 1)
                                .blendMode(.overlay)
                        }
                }
            }
        )
        .cornerRadius(16)
        .foregroundColor(.primary)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .onTapGesture {
            if !isDisabled {
                triggerHaptic()
            }
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingActionButton(title: "Suivant", action: {})
        OnboardingActionButton(title: "Commencer", isDisabled: true, action: {})
    }
    .padding()
}
