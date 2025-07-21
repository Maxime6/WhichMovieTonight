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
    @Published var isGeneratingRecommendations = false
    @Published var userName: String = "Movie Lover"

    // AI Search State
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var searchResult: Movie?
    @Published var showSearchResult: Bool = false
    @Published var searchValidationMessage: String?

    // UI State
    @Published var showToast: Bool = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    // MARK: - Dependencies (Unified)

    private let userMovieService: UserMovieServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(userMovieService: UserMovieServiceProtocol) {
        self.userMovieService = userMovieService
    }

    // MARK: - Computed Properties

    func welcomeMessage(userProfileService: UserProfileService) -> String {
        let firstName = userProfileService.displayName.isEmpty ? userName : userProfileService.displayName
        return "Hi \(firstName)"
    }

    var welcomeSubtitle: String {
        return "Ready for new discoveries?"
    }

    // MARK: - Public Methods

    /// Initialize all data for HomeView
    func initializeData(userProfileService: UserProfileService) async {
        await loadUserDisplayName(userProfileService: userProfileService)
        await loadOrGenerateRecommendations(userProfileService: userProfileService)
    }

    /// Load or generate recommendations with daily reset logic
    private func loadOrGenerateRecommendations(userProfileService: UserProfileService) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID available")
            return
        }

        do {
            // Create recommendation service with userProfileService
            let recommendationService = RecommendationService(userProfileService: userProfileService)

            // Try to load existing recommendations
            let existingRecommendations = try await recommendationService.loadCurrentRecommendations(for: userId)

            if !existingRecommendations.isEmpty {
                // Check if we need to generate new daily picks
                if await shouldGenerateNewDailyPicks(for: userId) {
                    await generateRecommendations(userProfileService: userProfileService)
                } else {
                    // Use existing recommendations from today
                    await MainActor.run {
                        currentRecommendations = existingRecommendations
                    }
                }
            } else {
                // No existing recommendations - generate new ones
                await generateRecommendations(userProfileService: userProfileService)
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
    func generateRecommendations(userProfileService: UserProfileService) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID available for generation")
            return
        }

        isGeneratingRecommendations = true

        do {
            let recommendationService = RecommendationService(userProfileService: userProfileService)
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
    func refreshRecommendations(userProfileService: UserProfileService) async {
        print("🔄 Manual refresh triggered")
        await generateRecommendations(userProfileService: userProfileService)
    }

    // MARK: - AI Search Management

    /// Perform AI search for a movie
    func performAISearch(userProfileService: UserProfileService) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        // Validate search input
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            searchValidationMessage = "Please describe what you want to watch..."
            return
        }

        let words = trimmedQuery.components(separatedBy: .whitespaces)
        if words.count < 2 {
            searchValidationMessage = "Be more specific! Try describing the mood, genre, or actors you're looking for..."
            return
        }

        // Clear validation message
        searchValidationMessage = nil
        isSearching = true

        do {
            // Get user interactions for AI context
            let userInteractions = try await getUserInteractionsForAI(userId: userId)

            // Get exclusion list
            let exclusionList = try await getExclusionList(for: userId)

            // Perform AI search
            let openAIService = OpenAIService()
            let movie = try await openAIService.searchSpecificMovie(
                query: trimmedQuery,
                userInteractions: userInteractions,
                favoriteActors: userProfileService.favoriteActors,
                favoriteGenres: userProfileService.favoriteGenres,
                recentSuggestions: exclusionList
            )

            // Enrich with OMDB data
            let enrichedMovie = try await enrichMovieWithOMDB(movie, userId: userId)

            // Ensure minimum 2 seconds of loading
            try await Task.sleep(nanoseconds: 2_000_000_000)

            await MainActor.run {
                searchResult = enrichedMovie
                showSearchResult = true
                isSearching = false
            }

        } catch {
            await MainActor.run {
                isSearching = false
                if error.localizedDescription.contains("timeout") {
                    errorMessage = "Search is taking longer than expected. Please try again."
                } else if error.localizedDescription.contains("badServerResponse") {
                    errorMessage = "I couldn't find a movie matching your request. Try being more specific."
                } else {
                    errorMessage = "Connection issue. Please try again."
                }
            }
        }
    }

    /// Add movie to watchlist
    func addToWatchlist(_ movie: Movie) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        do {
            try await userMovieService.addToWatchlist(userId: userId, movieId: movie.id)
            showToastMessage("Added to watchlist: \(movie.title)")
        } catch {
            print("❌ Error adding to watchlist: \(error)")
            errorMessage = "Failed to add to watchlist. Please try again."
        }
    }

    // MARK: - Private Methods

    private func loadUserDisplayName(userProfileService: UserProfileService) async {
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

    private func getUserInteractionsForAI(userId: String) async throws -> UserMovieInteractions? {
        let userMovies = try await userMovieService.getUserMovies(userId: userId, filter: nil)

        // Convert UserMovies to legacy UserMovieInteractions format
        var interactions: [String: UserMovieInteraction] = [:]

        for userMovie in userMovies {
            if userMovie.isLiked || userMovie.isDisliked || userMovie.isFavorite {
                let interaction = UserMovieInteraction(
                    movieId: userMovie.movieId,
                    movieTitle: userMovie.movie.title,
                    posterURL: userMovie.movie.posterURL?.absoluteString,
                    likeStatus: userMovie.isLiked ? .liked : userMovie.isDisliked ? .disliked : .none,
                    isFavorite: userMovie.isFavorite
                )
                interactions[userMovie.movieId] = interaction
            }
        }

        if interactions.isEmpty {
            return nil
        }

        var userInteractions = UserMovieInteractions(userId: userId)
        userInteractions.interactions = interactions

        print("📊 Converted \(interactions.count) UserMovies to AI context")
        return userInteractions
    }

    private func getExclusionList(for userId: String) async throws -> [MovieFirestore] {
        let userMovies = try await userMovieService.getUserMovies(userId: userId, filter: nil)

        // Exclude movies from history and disliked movies
        let excludedMovies = userMovies.filter {
            $0.isInHistory || $0.isCurrentPick || $0.isDisliked
        }

        // Convert to legacy MovieFirestore format for OpenAI service
        let exclusionList = excludedMovies.map { MovieFirestore(from: $0.movie) }

        print("📝 Excluding \(exclusionList.count) movies from search (history + disliked)")
        return exclusionList
    }

    private func enrichMovieWithOMDB(_ movie: Movie, userId _: String) async throws -> Movie {
        do {
            let omdbService = OMDBService()
            let omdbMovie = try await omdbService.getMovieDetailsByTitle(title: movie.title)
            let enrichedMovie = Movie(
                from: omdbMovie,
                originalGenres: movie.genres,
                originalPlatforms: movie.streamingPlatforms
            )
            return enrichedMovie
        } catch {
            print("⚠️ OMDB enrichment failed for \(movie.title), using OpenAI data only")
            return movie
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
