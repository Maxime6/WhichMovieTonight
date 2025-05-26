import FirebaseAuth
import SwiftUI

enum AppState {
    case onboarding
    case authentication
    case authenticated
}

@MainActor
class AppStateManager: ObservableObject {
    @Published var currentState: AppState = .onboarding
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("userPreferences") private var userPreferencesData: Data = .init()

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthStateListener()
        determineInitialState()
    }

    deinit {
        if let authStateHandler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(authStateHandler)
        }
    }

    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user: user)
            }
        }
    }

    private func determineInitialState() {
        if !hasSeenOnboarding {
            currentState = .onboarding
        } else if Auth.auth().currentUser != nil {
            currentState = .authenticated
        } else {
            currentState = .authentication
        }
    }

    private func handleAuthStateChange(user: User?) {
        if user != nil {
            // User is authenticated
            if hasSeenOnboarding {
                currentState = .authenticated
            } else {
                // This shouldn't happen in normal flow, but handle it gracefully
                currentState = .onboarding
            }
        } else {
            // User is not authenticated
            if hasSeenOnboarding {
                currentState = .authentication
            } else {
                currentState = .onboarding
            }
        }
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        currentState = .authentication
    }

    func handleSuccessfulAuthentication() {
        currentState = .authenticated
    }

    func handleSignOut() {
        currentState = .authentication
    }

    func handleAccountDeletion() {
        // Reset all user data
        hasSeenOnboarding = false
        userPreferencesData = Data()

        // Clear other AppStorage values if needed
        clearAllUserData()

        currentState = .onboarding
    }

    private func clearAllUserData() {
        // Clear all AppStorage keys related to user data
        let userDefaults = UserDefaults.standard

        // Add all your AppStorage keys here
        let keysToRemove = [
            "favoriteGenres",
            "favoriteActors",
            "userPreferences",
            // Add other keys as needed
        ]

        for key in keysToRemove {
            userDefaults.removeObject(forKey: key)
        }
    }
}
