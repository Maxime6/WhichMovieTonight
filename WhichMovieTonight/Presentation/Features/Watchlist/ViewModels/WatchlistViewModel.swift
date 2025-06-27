//
//  WatchlistViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
final class WatchlistViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var userMovies: [UserMovie] = []
    @Published var filteredMovies: [UserMovie] = []
    @Published var selectedTag: MovieTag = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let userMovieService: UserMovieServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(userMovieService: UserMovieServiceProtocol = UserMovieService()) {
        self.userMovieService = userMovieService

        // Setup tag filtering
        setupTagFiltering()

        Task {
            await loadUserMovies()
        }
    }

    // MARK: - Public Methods

    /// Load all user movies
    func loadUserMovies() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            userMovies = try await userMovieService.getUserMovies(userId: userId, filter: nil)
            print("📱 Loaded \(userMovies.count) movies for user")
        } catch {
            print("❌ Error loading user movies: \(error)")
            if error.localizedDescription.contains("offline") {
                errorMessage = "No internet connection. Please check your connection and try again."
            } else {
                errorMessage = "Failed to load movies. Please try again."
            }
        }

        isLoading = false
    }

    /// Refresh movies (manual pull-to-refresh)
    func refreshMovies() async {
        await loadUserMovies()
    }

    /// Select a filter tag
    func selectTag(_ tag: MovieTag) {
        selectedTag = tag
    }

    /// Toggle like status of a movie
    func toggleLike(_ movie: UserMovie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.movieId) { userMovie in
                if userMovie.isLiked {
                    // Remove like
                    userMovie.isLiked = false
                    userMovie.likedAt = nil
                } else {
                    // Add like
                    userMovie.markAsLiked()
                }
            }

            // Refresh local data
            await loadUserMovies()

        } catch {
            print("❌ Error toggling like: \(error)")
            errorMessage = "Failed to update movie. Please try again."
        }
    }

    /// Toggle dislike status of a movie
    func toggleDislike(_ movie: UserMovie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.movieId) { userMovie in
                if userMovie.isDisliked {
                    // Remove dislike
                    userMovie.isDisliked = false
                    userMovie.dislikedAt = nil
                } else {
                    // Add dislike
                    userMovie.markAsDisliked()
                }
            }

            // Refresh local data
            await loadUserMovies()

        } catch {
            print("❌ Error toggling dislike: \(error)")
            errorMessage = "Failed to update movie. Please try again."
        }
    }

    /// Toggle favorite status of a movie
    func toggleFavorite(_ movie: UserMovie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.movieId) { userMovie in
                userMovie.toggleFavorite()
            }

            // Refresh local data
            await loadUserMovies()

        } catch {
            print("❌ Error toggling favorite: \(error)")
            errorMessage = "Failed to update movie. Please try again."
        }
    }

    /// Mark movie as seen
    func markAsSeen(_ movie: UserMovie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.movieId) { userMovie in
                userMovie.markAsSeen()
            }

            // Refresh local data
            await loadUserMovies()

        } catch {
            print("❌ Error marking as seen: \(error)")
            errorMessage = "Failed to update movie. Please try again."
        }
    }

    /// Select movie for tonight
    func selectForTonight(_ movie: UserMovie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await userMovieService.setTonightSelection(userId: userId, movieId: movie.movieId)

            // Refresh local data
            await loadUserMovies()

        } catch {
            print("❌ Error selecting for tonight: \(error)")
            errorMessage = "Failed to select movie for tonight. Please try again."
        }
    }

    // MARK: - Computed Properties

    /// Tag statistics for display
    var tagStats: [MovieTag: Int] {
        var stats: [MovieTag: Int] = [:]

        for tag in MovieTag.allCases {
            stats[tag] = userMovies.filtered(by: tag).count
        }

        return stats
    }

    /// Check if there are any movies
    var hasMovies: Bool {
        return !userMovies.isEmpty
    }

    /// Check if filtered results are empty
    var hasFilteredMovies: Bool {
        return !filteredMovies.isEmpty
    }

    // MARK: - Private Methods

    /// Setup reactive tag filtering
    private func setupTagFiltering() {
        $selectedTag
            .combineLatest($userMovies)
            .map { tag, movies in
                movies.filtered(by: tag)
            }
            .assign(to: &$filteredMovies)
    }
}

// MARK: - Sorting and Filtering Helpers

extension WatchlistViewModel {
    /// Get movies sorted by last interaction
    func getMoviesSortedByInteraction() -> [UserMovie] {
        return UserMovie.sortByLastInteraction(filteredMovies)
    }

    /// Get movies sorted by recommendation date
    func getMoviesSortedByRecommendation() -> [UserMovie] {
        return UserMovie.sortByRecommendation(filteredMovies)
    }

    /// Get current picks only
    func getCurrentPicks() -> [UserMovie] {
        return filteredMovies.currentPicks
    }

    /// Get tonight's selection
    func getTonightSelection() -> UserMovie? {
        return filteredMovies.tonightSelection
    }
}
