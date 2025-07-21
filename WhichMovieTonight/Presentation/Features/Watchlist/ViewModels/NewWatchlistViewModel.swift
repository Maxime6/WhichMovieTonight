//
//  NewWatchlistViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import FirebaseAuth
import Foundation

@MainActor
final class NewWatchlistViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var userMovies: [UserMovie] = []
    @Published var searchText: String = ""
    @Published var currentSortOption: SortOption = .recentlyAdded
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let userMovieService: UserMovieServiceProtocol

    // MARK: - Initialization

    init(userMovieService: UserMovieServiceProtocol = UserMovieService()) {
        self.userMovieService = userMovieService
    }

    // MARK: - Public Methods

    /// Load user's watchlist movies
    func loadUserMovies() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        isLoading = true

        do {
            let watchlistMovies = try await userMovieService.getWatchlistMovies(userId: userId)
            userMovies = watchlistMovies.sorted(by: { $0.toWatchAt ?? Date() > $1.toWatchAt ?? Date() })
        } catch {
            print("❌ Error loading watchlist movies: \(error)")
            errorMessage = "Failed to load watchlist. Please try again."
        }

        isLoading = false
    }

    /// Refresh movies
    func refreshMovies() async {
        await loadUserMovies()
    }

    /// Sort movies by option
    func sortBy(_ option: SortOption) {
        currentSortOption = option
        userMovies = sortMovies(userMovies, by: option)
    }

    // MARK: - Movie Interactions

    /// Toggle like status
    func toggleLike(_ movie: UserMovie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.movieId) { userMovie in
                userMovie.markAsLiked()
            }

            // Refresh local data
            await loadUserMovies()

        } catch {
            print("❌ Error toggling like: \(error)")
            errorMessage = "Failed to update movie. Please try again."
        }
    }

    /// Toggle dislike status
    func toggleDislike(_ movie: UserMovie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.movieId) { userMovie in
                userMovie.markAsDisliked()
            }

            // Refresh local data
            await loadUserMovies()

        } catch {
            print("❌ Error toggling dislike: \(error)")
            errorMessage = "Failed to update movie. Please try again."
        }
    }

    /// Toggle favorite status
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

    /// Remove from watchlist
    func removeFromWatchlist(_ movie: UserMovie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await userMovieService.removeFromWatchlist(userId: userId, movieId: movie.movieId)

            // Refresh local data
            await loadUserMovies()

        } catch {
            print("❌ Error removing from watchlist: \(error)")
            errorMessage = "Failed to remove from watchlist. Please try again."
        }
    }

    // MARK: - Computed Properties

    /// Check if there are any movies
    var hasMovies: Bool {
        return !userMovies.isEmpty
    }

    /// Filtered movies based on search text
    var filteredMovies: [UserMovie] {
        if searchText.isEmpty {
            return userMovies
        }
        return userMovies.filter { movie in
            movie.movie.title.localizedCaseInsensitiveContains(searchText) ||
                movie.movie.genres.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                (movie.movie.actors?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - Private Methods

    private func sortMovies(_ movies: [UserMovie], by option: SortOption) -> [UserMovie] {
        switch option {
        case .recentlyAdded:
            return movies.sorted { ($0.toWatchAt ?? Date()) > ($1.toWatchAt ?? Date()) }
        case .titleAscending:
            return movies.sorted { $0.movie.title < $1.movie.title }
        case .titleDescending:
            return movies.sorted { $0.movie.title > $1.movie.title }
        case .yearDescending:
            return movies.sorted {
                let year1 = Int($0.movie.year ?? "0") ?? 0
                let year2 = Int($1.movie.year ?? "0") ?? 0
                return year1 > year2
            }
        case .yearAscending:
            return movies.sorted {
                let year1 = Int($0.movie.year ?? "0") ?? 0
                let year2 = Int($1.movie.year ?? "0") ?? 0
                return year1 < year2
            }
        case .ratingDescending:
            return movies.sorted {
                let rating1 = Double($0.movie.imdbRating ?? "0") ?? 0
                let rating2 = Double($1.movie.imdbRating ?? "0") ?? 0
                return rating1 > rating2
            }
        }
    }
}
