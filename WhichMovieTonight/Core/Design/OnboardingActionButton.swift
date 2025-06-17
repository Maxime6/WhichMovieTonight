import SwiftUI

struct OnboardingActionButton: View {
    var title: String
    var isDisabled: Bool = false
    var action: () -> Void
    @State var counter: Int = 0
    @State var origin: CGPoint = .zero

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
//                        .overlay {
//                            RoundedRectangle(cornerRadius: 16)
//                                .stroke(.white, lineWidth: 3)
//                                .blur(radius: 2)
//                                .blendMode(.overlay)
//                        }
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
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(.blue.opacity(0.5), lineWidth: 1)
//        )
//        .shadow(color: .cyan.opacity(0.15), radius: 20, x: 0, y: 20)
//        .shadow(color: .purple.opacity(0.1), radius: 15, x: 0, y: 15)
        .foregroundColor(.primary)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(.cyan.opacity(0.5), lineWidth: 1)
//        )
        .disabled(isDisabled)
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
    VStack(spacing: 20) {
        OnboardingActionButton(title: "Suivant", action: {})
        OnboardingActionButton(title: "Commencer", isDisabled: true, action: {})
    }
    .padding()
}
