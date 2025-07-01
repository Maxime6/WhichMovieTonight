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

    // MARK: - Sort Options

    enum SortOption: String, CaseIterable {
        case recentlyAdded
        case titleAscending
        case titleDescending
        case yearDescending
        case yearAscending
        case ratingDescending

        var displayName: String {
            switch self {
            case .recentlyAdded: return "Recently Added"
            case .titleAscending: return "Title A-Z"
            case .titleDescending: return "Title Z-A"
            case .yearDescending: return "Year (Newest)"
            case .yearAscending: return "Year (Oldest)"
            case .ratingDescending: return "Rating (High to Low)"
            }
        }

        var icon: String {
            switch self {
            case .recentlyAdded: return "clock.fill"
            case .titleAscending: return "textformat.abc"
            case .titleDescending: return "textformat.abc.dottedunderline"
            case .yearDescending: return "calendar.badge.plus"
            case .yearAscending: return "calendar.badge.minus"
            case .ratingDescending: return "star.fill"
            }
        }
    }

    // MARK: - Initialization

    init(userMovieService: UserMovieServiceProtocol = UserMovieService()) {
        self.userMovieService = userMovieService

        // Load saved sort preference
        loadSortPreference()

        // Setup search and filtering
        setupSearchAndFiltering()

        Task {
            await loadFavorites()
        }
    }

    // MARK: - Public Methods

    /// Load user's favorite movies
    func loadFavorites() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let allMovies = try await userMovieService.getUserMovies(userId: userId, filter: nil)
            favorites = allMovies.filter { $0.isFavorite }
            print("📱 Loaded \(favorites.count) favorite movies")
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

    /// Perform search with debouncing
    func performSearch(_ query: String) {
        searchText = query
    }

    /// Change sort option
    func sortBy(_ option: SortOption) {
        currentSortOption = option
        saveSortPreference()
        applySortingAndFiltering()
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
    private func sortFavorites(_ favorites: [UserMovie], by option: SortOption) -> [UserMovie] {
        switch option {
        case .recentlyAdded:
            return favorites.sorted { ($0.favoriteAt ?? Date.distantPast) > ($1.favoriteAt ?? Date.distantPast) }
        case .titleAscending:
            return favorites.sorted { $0.movie.title.localizedCaseInsensitiveCompare($1.movie.title) == .orderedAscending }
        case .titleDescending:
            return favorites.sorted { $0.movie.title.localizedCaseInsensitiveCompare($1.movie.title) == .orderedDescending }
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

    /// Apply current sorting and filtering
    private func applySortingAndFiltering() {
        filteredFavorites = filterAndSortFavorites(favorites, searchText: searchText, sortOption: currentSortOption)
    }

    /// Load saved sort preference
    private func loadSortPreference() {
        if let savedSort = UserDefaults.standard.string(forKey: "favorites_sort_preference"),
           let sortOption = SortOption(rawValue: savedSort)
        {
            currentSortOption = sortOption
        }
    }

    /// Save sort preference
    private func saveSortPreference() {
        UserDefaults.standard.set(currentSortOption.rawValue, forKey: "favorites_sort_preference")
    }
}
