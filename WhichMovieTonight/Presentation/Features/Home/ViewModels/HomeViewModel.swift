//
//  HomeViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentRecommendations: [UserMovie] = []
    @Published var selectedMovieForTonight: Movie?
    @Published var selectedMovieForTonightUserMovie: UserMovie? = nil
    @Published var isGeneratingRecommendations = false
    @Published var userName: String = "Movie Lover"

    // UI State
    @Published var showToast: Bool = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    // MARK: - Dependencies (Unified)

    private let recommendationService: RecommendationServiceProtocol
    private let userMovieService: UserMovieServiceProtocol
    private let userProfileService: UserProfileService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        userMovieService: UserMovieServiceProtocol,
        userProfileService: UserProfileService
    ) {
        self.userMovieService = userMovieService
        self.userProfileService = userProfileService
        recommendationService = RecommendationService(userProfileService: userProfileService)

        Task {
            await initializeData()
        }
    }

    // MARK: - Computed Properties

    var welcomeMessage: String {
        let firstName = userProfileService.displayName.isEmpty ? userName : userProfileService.displayName
        return "Hi \(firstName)"
    }

    var welcomeSubtitle: String {
        return "Ready for new discoveries?"
    }

    // MARK: - Public Methods

    /// Initialize all data for HomeView
    func initializeData() async {
        await loadUserDisplayName()
        await loadSelectedMovieForTonight()
        await loadOrGenerateRecommendations()
    }

    /// Load or generate recommendations with daily reset logic
    private func loadOrGenerateRecommendations() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID available")
            return
        }

        do {
            // Try to load existing recommendations
            let existingRecommendations = try await recommendationService.loadCurrentRecommendations(for: userId)

            if !existingRecommendations.isEmpty {
                // Check if we need to generate new daily picks
                if await shouldGenerateNewDailyPicks(for: userId) {
                    await generateRecommendations()
                } else {
                    // Use existing recommendations from today
                    await MainActor.run {
                        currentRecommendations = existingRecommendations
                    }
                }
            } else {
                // No existing recommendations - generate new ones
                await generateRecommendations()
            }
        } catch {
            print("❌ Error loading recommendations: \(error)")
            if error.localizedDescription.contains("offline") {
                showOfflineMessage()
            } else {
                errorMessage = "Failed to load recommendations. Please try again."
            }
        }
    }

    /// Check if we should generate new daily picks based on date and time
    private func shouldGenerateNewDailyPicks(for userId: String) async -> Bool {
        do {
            // Get current picks with their generation dates
            let currentPicks = try await userMovieService.getCurrentPicks(userId: userId)

            guard !currentPicks.isEmpty else {
                return true // No current picks - should generate
            }

            // Find the most recent generation date
            let mostRecentDate = currentPicks.compactMap { $0.currentPicksSince }.max()

            guard let lastGenerationDate = mostRecentDate else {
                return true // No valid date found - should generate
            }

            return isDifferentDay(from: lastGenerationDate, threshold: 5)

        } catch {
            print("⚠️ Error checking daily picks date: \(error)")
            return false // Don't generate on error - use existing picks
        }
    }

    /// Check if current time is in a different day from given date, considering 5am threshold
    private func isDifferentDay(from date: Date, threshold: Int = 5) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Get current hour
        let currentHour = calendar.component(.hour, from: now)

        // If it's before 5am, consider it as still "yesterday" for recommendation purposes
        let effectiveNow: Date
        if currentHour < threshold {
            // Subtract one day to keep yesterday's recommendations
            effectiveNow = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        } else {
            effectiveNow = now
        }

        // Check if the dates are in different days
        return !calendar.isDate(effectiveNow, inSameDayAs: date)
    }

    /// Generate new recommendations (initial or refresh)
    func generateRecommendations() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID available for generation")
            return
        }

        isGeneratingRecommendations = true

        do {
            let newRecommendations = try await recommendationService.generateNewRecommendations(for: userId)
            await MainActor.run {
                currentRecommendations = newRecommendations
            }
        } catch {
            print("❌ Failed to generate recommendations: \(error)")
            if error.localizedDescription.contains("offline") {
                showOfflineMessage()
            } else {
                errorMessage = "Unable to generate recommendations. Please try again."
            }
        }

        isGeneratingRecommendations = false
    }

    /// Manual refresh recommendations
    func refreshRecommendations() async {
        print("🔄 Manual refresh triggered")
        await generateRecommendations()
    }

    // MARK: - Selected Movie For Tonight Management

    /// Select a movie for tonight using UserMovieService
    func selectMovieForTonight(_ movie: Movie) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        do {
            try await userMovieService.setTonightSelection(userId: userId, movieId: movie.id)
            selectedMovieForTonight = movie

            // Load the UserMovie object for the selected movie
            if let userMovie = try await userMovieService.getUserMovie(userId: userId, movieId: movie.id) {
                selectedMovieForTonightUserMovie = userMovie
            }

            showToastMessage("Selected for tonight: \(movie.title)")
        } catch {
            print("❌ Error selecting movie for tonight: \(error)")
            errorMessage = "Failed to select movie. Please try again."
        }
    }

    /// Deselect current movie for tonight
    func deselectMovieForTonight() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        do {
            try await userMovieService.clearTonightSelection(userId: userId)
            selectedMovieForTonight = nil
            selectedMovieForTonightUserMovie = nil
            showToastMessage("Movie deselected")
        } catch {
            print("❌ Error deselecting movie: \(error)")
            errorMessage = "Failed to deselect movie. Please try again."
        }
    }

    // MARK: - Private Methods

    private func loadUserDisplayName() async {
        if let currentUser = Auth.auth().currentUser {
            // Load user profile data
            await userProfileService.loadUserPreferences(userId: currentUser.uid)

            // Use profile display name if available, otherwise fallback to Firebase Auth
            let displayName = userProfileService.displayName.isEmpty ?
                (currentUser.displayName ?? currentUser.email?.components(separatedBy: "@").first ?? "Movie Lover") :
                userProfileService.displayName

            await MainActor.run {
                userName = displayName
            }
        }
    }

    private func loadSelectedMovieForTonight() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            if let userMovie = try await userMovieService.getTonightSelection(userId: userId) {
                selectedMovieForTonight = userMovie.movie
                selectedMovieForTonightUserMovie = userMovie
                print("📱 Loaded selected movie for tonight: \(userMovie.movie.title)")
            }
        } catch {
            print("❌ Error loading selected movie: \(error)")
            if error.localizedDescription.contains("offline") {
                print("📱 App is offline - selected movie will load when connection is restored")
            }
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showToast = false
            self.toastMessage = nil
        }
    }

    private func showOfflineMessage() {
        errorMessage = "No internet connection. Please check your connection and try again."
    }
}
