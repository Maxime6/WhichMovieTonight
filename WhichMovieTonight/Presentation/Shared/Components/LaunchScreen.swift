import SwiftUI

struct LaunchScreen: View {
    @EnvironmentObject private var appStateManager: AppStateManager
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
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
