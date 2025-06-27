import FirebaseAuth
import Foundation

@MainActor
class AppStateManager: ObservableObject {
    @Published var appState: AppState = .launch

    private let userPreferencesService = UserPreferencesService()

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
        if Auth.auth().currentUser != nil {
            // Check if user completed onboarding
            let preferences = userPreferencesService.getUserPreferences()

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

    func handleSuccessfulAuthentication() {
        let preferences = userPreferencesService.getUserPreferences()

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
