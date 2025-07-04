import SwiftUI

struct OnboardingCompleteView: View {
    @EnvironmentObject var stepManager: OnboardingStepManager
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var showCompletionAnimation = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Success animation and icon
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.2), .cyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showCompletionAnimation ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCompletionAnimation)
                }

                // Sparkles animation
                HStack(spacing: 16) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.yellow)
                            .opacity(showCompletionAnimation ? 1.0 : 0.0)
                            .animation(
                                .easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: showCompletionAnimation
                            )
                    }
                }
            }

            // Completion message
            VStack(spacing: 16) {
                Text("You're all set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Welcome to WMT! Your personalized movie recommendations are ready.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Summary of preferences
            VStack(spacing: 16) {
                Text("Your Preferences")
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(spacing: 12) {
                    PreferenceSummaryRow(
                        icon: "person.fill",
                        title: "Name",
                        value: userProfileService.displayName.isEmpty ? "Not set" : userProfileService.displayName
                    )

                    PreferenceSummaryRow(
                        icon: "list.bullet",
                        title: "Genres",
                        value: "\(userProfileService.favoriteGenres.count) selected"
                    )

                    PreferenceSummaryRow(
                        icon: "tv.fill",
                        title: "Platforms",
                        value: "\(userProfileService.favoriteStreamingPlatforms.count) selected"
                    )

                    if !userProfileService.favoriteActors.isEmpty {
                        PreferenceSummaryRow(
                            icon: "person.2.fill",
                            title: "Actors",
                            value: "\(userProfileService.favoriteActors.count) added"
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
            }

            Spacer()

            // Complete button
            Button(action: {
                Task {
                    await stepManager.completeOnboarding()
                    // After completion, notify AppStateManager to move to main app
                    appStateManager.completeOnboarding()
                }
            }) {
                HStack {
                    if stepManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Start Exploring")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(stepManager.isLoading)
            .padding(.horizontal)

            if let errorMessage = stepManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                showCompletionAnimation = true
            }
        }
    }

    private var userProfileService: UserProfileService {
        // Access UserProfileService through stepManager
        return stepManager.userProfileService
    }
}

// MARK: - Preference Summary Row Component

struct PreferenceSummaryRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.cyan)
                .frame(width: 20)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    OnboardingCompleteView()
        .environmentObject(OnboardingStepManager(userProfileService: UserProfileService()))
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
