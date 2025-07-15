import SwiftUI

struct LaunchScreen: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0.0
    @State private var subtitleOffset: CGFloat = 20
    @State private var subtitleOpacity: Double = 0.0
    @State private var hasInitialized: Bool = false

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

                // App name with elegant animated text reveal
                VStack(spacing: 8) {
                    Text("Which Movie Tonight")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyan, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Text("Your personal movie assistant")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .offset(y: subtitleOffset)
                        .opacity(subtitleOpacity)
                }

                // Subtle loading indicator with cyan theme
                HStack(spacing: 8) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
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
            // Staggered animation sequence for elegant reveal
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Animate title with slight delay
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                titleOffset = 0
                titleOpacity = 1.0
            }

            // Animate subtitle with additional delay
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
                subtitleOffset = 0
                subtitleOpacity = 1.0
            }

            // Initialize app after launch screen animation
            Task {
                await initializeAppIfNeeded()
            }
        }
    }

    // MARK: - App Initialization

    /// Initialize app (recommendations) if user is authenticated
    private func initializeAppIfNeeded() async {
        // Wait for animation to complete and ensure LaunchScreen is visible
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        guard !hasInitialized else { return }
        hasInitialized = true

        // Initialize recommendations if user is authenticated
        await appStateManager.initializeApp()
    }
}

#Preview {
    LaunchScreen()
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
