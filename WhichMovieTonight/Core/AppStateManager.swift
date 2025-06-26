import FirebaseAuth
import SwiftUI

// MARK: - App State with Loading

enum AppState {
    case onboarding
    case authentication
    case authenticated
    case loading // New state for recommendation generation
}

// Removed duplicate enum - moved above with loading state

@MainActor
class AppStateManager: ObservableObject {
    @Published var currentState: AppState = .onboarding
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("userPreferences") private var userPreferencesData: Data = .init()

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    // MARK: - Recommendation Management

    private let recommendationService: RecommendationServiceProtocol
    @Published var dailyRecommendations: [Movie] = []
    @Published var isGeneratingRecommendations: Bool = false

    init(recommendationService: RecommendationServiceProtocol = RecommendationService()) {
        self.recommendationService = recommendationService
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
                // Initialize daily recommendations when authenticated
                Task {
                    await initializeDailyRecommendations()
                }
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
            "favoriteStreamingPlatforms",
            "userPreferences",
            // Add other keys as needed
        ]

        for key in keysToRemove {
            userDefaults.removeObject(forKey: key)
        }

        // Clear recommendations
        dailyRecommendations = []
    }

    // MARK: - Daily Recommendations Management

    /// Initialize app after authentication - check and generate recommendations if needed
    func initializeApp() async {
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No authenticated user for app initialization")
            return
        }

        await initializeDailyRecommendations()
    }

    /// Check and load/generate daily recommendations
    private func initializeDailyRecommendations() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID available for recommendations")
            return
        }

        do {
            // First, try to get cached recommendations
            if let cachedRecommendations = try await recommendationService.getCachedRecommendations(for: userId) {
                dailyRecommendations = cachedRecommendations
                print("✅ Loaded \(cachedRecommendations.count) cached recommendations")
                return
            }

            // Check if we need to generate new recommendations
            let shouldGenerate = try await recommendationService.shouldGenerateNewRecommendations(for: userId)

            if shouldGenerate {
                await generateDailyRecommendations()
            }

        } catch {
            print("❌ Error initializing recommendations: \(error)")
        }
    }

    /// Generate new daily recommendations with loading state
    func generateDailyRecommendations() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID available for recommendation generation")
            return
        }

        isGeneratingRecommendations = true
        currentState = .loading

        do {
            let newRecommendations = try await recommendationService.generateDailyRecommendations(for: userId)
            dailyRecommendations = newRecommendations
            currentState = .authenticated
            print("🎉 Generated \(newRecommendations.count) new recommendations")

        } catch {
            print("❌ Failed to generate recommendations: \(error)")
            currentState = .authenticated
            // TODO: Show error to user
        }

        isGeneratingRecommendations = false
    }

    /// Manual refresh of recommendations (for user action)
    func refreshRecommendations() async {
        await generateDailyRecommendations()
    }
}
