import FirebaseAuth
import Foundation

@MainActor
class AppStateManager: ObservableObject {
    @Published var appState: AppState = .launch

    private let userProfileService = UserProfileService()

    // MARK: - App States

    enum AppState {
        case launch
        case needsOnboarding
        case needsAuthentication
        case authenticated
    }

    // MARK: - Initialization

    func initializeApp() async {
        // Check authentication
        if let currentUser = Auth.auth().currentUser {
            // Load user preferences from Firebase to check if onboarding is completed
            await userProfileService.loadUserPreferences(userId: currentUser.uid)
            let preferences = userProfileService.getUserPreferences()

            if !preferences.favoriteGenres.isEmpty && !preferences.favoriteStreamingPlatforms.isEmpty {
                appState = .authenticated
            } else {
                appState = .needsOnboarding
            }
        } else {
            appState = .needsAuthentication
        }
    }

    // MARK: - Authentication Handling

    func handleSuccessfulAuthentication() async {
        guard let currentUser = Auth.auth().currentUser else {
            appState = .needsAuthentication
            return
        }

        // Load user preferences from Firebase
        await userProfileService.loadUserPreferences(userId: currentUser.uid)
        let preferences = userProfileService.getUserPreferences()

        if !preferences.favoriteGenres.isEmpty && !preferences.favoriteStreamingPlatforms.isEmpty {
            appState = .authenticated
        } else {
            appState = .needsOnboarding
        }
    }

    func handleSignOut() {
        appState = .needsAuthentication
    }

    func handleAccountDeletion() {
        appState = .needsAuthentication
    }

    func completeOnboarding() {
        appState = .authenticated
    }
}
