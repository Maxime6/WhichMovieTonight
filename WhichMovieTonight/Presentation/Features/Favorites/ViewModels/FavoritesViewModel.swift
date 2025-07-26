//
//  FavoritesViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
final class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var favorites: [UserMovie] = []
    @Published var filteredFavorites: [UserMovie] = []
    @Published var searchText: String = ""
    @Published var currentSortOption: SortOption = .recentlyAdded
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let userMovieService: UserMovieServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(userMovieService: UserMovieServiceProtocol = UserMovieService()) {
        self.userMovieService = userMovieService

        // Setup reactive search and filtering
        setupSearchAndFiltering()

        Task {
            await loadFavorites()
        }
    }

    // MARK: - Public Methods

    /// Load user favorites
    func loadFavorites() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            favorites = try await userMovieService.getUserMovies(userId: userId, filter: .favorites)
            print("📱 Loaded \(favorites.count) favorites for user")
        } catch {
            print("❌ Error loading favorites: \(error)")
            if error.localizedDescription.contains("offline") {
                errorMessage = "No internet connection. Please check your connection and try again."
            } else {
                errorMessage = "Failed to load favorites. Please try again."
            }
        }

        isLoading = false
    }

    /// Refresh favorites (manual pull-to-refresh)
    func refreshFavorites() async {
        await loadFavorites()
    }

    /// Sort by specified option
    func sortBy(_ option: SortOption) {
        currentSortOption = option
    }

    /// Toggle movie watchlist status (add/remove)
    func toggleWatchlist(_ movie: UserMovie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            if movie.isToWatch {
                // Remove from watchlist
                try await userMovieService.removeFromWatchlist(userId: userId, movieId: movie.movieId)
            } else {
                // Add to watchlist
                try await userMovieService.addToWatchlist(userId: userId, movieId: movie.movieId)
            }

            // Refresh local data
            await loadFavorites()

        } catch {
            print("❌ Error toggling watchlist: \(error)")
            errorMessage = "Failed to update watchlist. Please try again."
        }
    }

    // MARK: - Computed Properties

    /// Check if there are any favorites
    var hasFavorites: Bool {
        return !favorites.isEmpty
    }

    /// Check if filtered results are empty
    var hasFilteredFavorites: Bool {
        return !filteredFavorites.isEmpty
    }

    /// Get sorted and filtered favorites
    var sortedAndFilteredFavorites: [UserMovie] {
        return filteredFavorites
    }

    // MARK: - Private Methods

    /// Setup reactive search and filtering
    private func setupSearchAndFiltering() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .combineLatest($favorites, $currentSortOption)
            .map { searchText, favorites, sortOption in
                self.filterAndSortFavorites(favorites, searchText: searchText, sortOption: sortOption)
            }
            .assign(to: &$filteredFavorites)
    }

    /// Filter and sort favorites
    private func filterAndSortFavorites(_ favorites: [UserMovie], searchText: String, sortOption: SortOption) -> [UserMovie] {
        var filtered = favorites

        // Apply search filter
        if !searchText.isEmpty {
            let searchTerms = searchText.lowercased().split(separator: " ")
            filtered = favorites.filter { userMovie in
                let movie = userMovie.movie
                return searchTerms.allSatisfy { term in
                    movie.title.lowercased().contains(term) ||
                        movie.genres.contains { $0.lowercased().contains(term) } ||
                        (movie.actors?.contains { $0.lowercased().contains(term) } ?? false)
                }
            }
        }

        // Apply sorting
        return sortFavorites(filtered, by: sortOption)
    }

    /// Sort favorites by specified option
    private func sortFavorites(_ favorites: [UserMovie], by sortOption: SortOption) -> [UserMovie] {
        switch sortOption {
        case .recentlyAdded:
            return favorites.sorted { ($0.favoriteAt ?? Date.distantPast) > ($1.favoriteAt ?? Date.distantPast) }
        case .titleAscending:
            return favorites.sorted { $0.movie.title.lowercased() < $1.movie.title.lowercased() }
        case .titleDescending:
            return favorites.sorted { $0.movie.title.lowercased() > $1.movie.title.lowercased() }
        case .yearDescending:
            return favorites.sorted { ($0.movie.year ?? "0") > ($1.movie.year ?? "0") }
        case .yearAscending:
            return favorites.sorted { ($0.movie.year ?? "0") < ($1.movie.year ?? "0") }
        case .ratingDescending:
            return favorites.sorted {
                let rating1 = Double($0.movie.imdbRating ?? "0") ?? 0
                let rating2 = Double($1.movie.imdbRating ?? "0") ?? 0
                return rating1 > rating2
            }
        }
    }
}
