import SwiftUI

struct LaunchScreen: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Clean background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // App logo
                Image("WMTLogoV1") // Using existing logo from Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // App name with elegant animation
                VStack(spacing: 8) {
                    Text("Which Movie Tonight")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .opacity(logoOpacity)

                    Text("Your personal movie assistant")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(logoOpacity)
                }

                // Subtle loading indicator
                HStack(spacing: 8) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .scaleEffect(logoOpacity)
                            .animation(
                                .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: logoOpacity
                            )
                    }
                }
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // No more gradient rotation animation needed
        }
    }
}

#Preview {
    LaunchScreen()
}
