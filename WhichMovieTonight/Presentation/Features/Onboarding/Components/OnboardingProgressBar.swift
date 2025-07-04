import SwiftUI

struct OnboardingProgressBar: View {
    let progress: Double
    @State private var animationProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Progress bar with animated mesh gradient
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan,
                                Color.blue,
                                Color.purple,
                                Color.pink,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animationProgress, height: 8)
                    .animation(.easeInOut(duration: 0.8), value: animationProgress)

                // Animated sparkles
                HStack(spacing: 0) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(animationProgress > 0 ? 1.0 : 0.0)
                            .animation(
                                .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: animationProgress
                            )
                    }
                }
                .offset(x: geometry.size.width * animationProgress - 20)
            }
        }
        .frame(height: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animationProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: 0.8)) {
                animationProgress = newProgress
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingProgressBar(progress: 0.3)
        OnboardingProgressBar(progress: 0.6)
        OnboardingProgressBar(progress: 1.0)
    }
    .padding()
}
