import SwiftUI

struct AIThinkingIndicator: View {
    @State private var isAnimating = false
    @State private var currentDotIndex = 0
    @State private var brainPulse = false
    @State private var sparkleOffset: CGFloat = 0

    private let messages = [
        "Hmm, what should you watch tonight... 🤔",
        "I'm digging through my movie database... 🔍",
        "Ah! I've got some ideas you might love! ✨",
        "Let me fine-tune these suggestions... 🎬",
        "Almost done, making sure these match your taste! 👌",
    ]

    @State private var currentMessageIndex = 0

    var body: some View {
        VStack(spacing: 24) {
            // Brain with sparkles animation
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DesignSystem.primaryCyan.opacity(0.3), DesignSystem.primaryPurple.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(brainPulse ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: brainPulse)

                // Brain icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(DesignSystem.verticalGradient)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                // Sparkles around the brain
                ForEach(0 ..< 6, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.yellow)
                        .offset(
                            x: cos(Double(index) * 60 * .pi / 180 + sparkleOffset) * 45,
                            y: sin(Double(index) * 60 * .pi / 180 + sparkleOffset) * 45
                        )
                        .opacity(isAnimating ? 1.0 : 0.3)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                }
            }

            // Friendly message
            VStack(spacing: 8) {
                Text(messages[currentMessageIndex])
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.5), value: currentMessageIndex)

                // Animated dots
                HStack(spacing: 4) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Circle()
                            .fill(DesignSystem.primaryCyan)
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentDotIndex == index ? 1.2 : 0.8)
                            .opacity(currentDotIndex == index ? 1.0 : 0.5)
                            .animation(.easeInOut(duration: 0.4), value: currentDotIndex)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Start brain pulse
        brainPulse = true

        // Start rotation animation
        isAnimating = true

        // Animate sparkles rotation
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            sparkleOffset = 2 * .pi
        }

        // Animate dots
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            currentDotIndex = (currentDotIndex + 1) % 3
        }

        // Change messages every 3 seconds
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
            }
        }
    }
}

#Preview {
    AIThinkingIndicator()
        .padding()
        .background(Color(.systemBackground))
}
