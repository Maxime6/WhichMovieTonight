//
//  UserMovie.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import Foundation

// MARK: - User Movie Unified Model

struct UserMovie: Identifiable, Codable {
    let id: String // Same as movieId for simplicity
    let movieId: String // Movie.id (imdbID)
    let userId: String
    let movie: Movie

    // MARK: - Movie States

    var isCurrentPick: Bool = false
    var isInHistory: Bool = false
    var isLiked: Bool = false
    var isDisliked: Bool = false
    var isFavorite: Bool = false
    var isSeen: Bool = false
    var isSelectedForTonight: Bool = false

    // MARK: - Timestamps

    var recommendedAt: Date?
    var currentPicksSince: Date?
    var likedAt: Date?
    var dislikedAt: Date?
    var favoriteAt: Date?
    var seenAt: Date?
    var selectedAt: Date?
    var lastUpdated: Date = .init()

    // MARK: - Initializers

    /// Primary initializer
    init(
        userId: String,
        movie: Movie,
        isCurrentPick: Bool = false,
        isInHistory: Bool = false,
        isLiked: Bool = false,
        isDisliked: Bool = false,
        isFavorite: Bool = false,
        isSeen: Bool = false,
        isSelectedForTonight: Bool = false
    ) {
        id = movie.id
        movieId = movie.id
        self.userId = userId
        self.movie = movie
        self.isCurrentPick = isCurrentPick
        self.isInHistory = isInHistory
        self.isLiked = isLiked
        self.isDisliked = isDisliked
        self.isFavorite = isFavorite
        self.isSeen = isSeen
        self.isSelectedForTonight = isSelectedForTonight
        lastUpdated = Date()
    }

    // MARK: - Computed Properties

    /// Primary tag for display (highest priority tag)
    var primaryTag: MovieTag {
        let activeTags = allActiveTags.filter { $0 != .all }
        return activeTags.max(by: { $0.priority < $1.priority }) ?? .all
    }

    /// All active tags for filtering
    var allActiveTags: [MovieTag] {
        var tags: [MovieTag] = [.all] // Every movie has "all" tag

        if isCurrentPick { tags.append(.currentPicks) }
        if isInHistory { tags.append(.history) }
        if isLiked { tags.append(.liked) }
        if isDisliked { tags.append(.disliked) }
        if isFavorite { tags.append(.favorites) }
        if isSeen { tags.append(.seen) }
        if isSelectedForTonight { tags.append(.tonight) }

        return tags
    }

    /// Check if movie has any interactions (for cleanup logic)
    var hasOtherInteractions: Bool {
        return isLiked || isDisliked || isFavorite || isSeen || isSelectedForTonight
    }

    /// Check if movie contains a specific tag
    func hasTag(_ tag: MovieTag) -> Bool {
        return allActiveTags.contains(tag)
    }

    // MARK: - Business Logic Methods

    /// Mark as current pick (one of the 5 daily recommendations)
    mutating func markAsCurrentPick() {
        isCurrentPick = true
        currentPicksSince = Date()
        recommendedAt = recommendedAt ?? Date()
        isInHistory = true // Current picks are also in history
        lastUpdated = Date()
    }

    /// Remove from current picks (when new generation happens)
    mutating func removeFromCurrentPicks() {
        isCurrentPick = false
        currentPicksSince = nil
        // Keep isInHistory = true
        lastUpdated = Date()
    }

    /// Mark as liked
    mutating func markAsLiked() {
        isLiked = true
        isDisliked = false // Can't be both liked and disliked
        likedAt = Date()
        dislikedAt = nil
        lastUpdated = Date()
    }

    /// Mark as disliked
    mutating func markAsDisliked() {
        isDisliked = true
        isLiked = false // Can't be both liked and disliked
        dislikedAt = Date()
        likedAt = nil
        lastUpdated = Date()
    }

    /// Toggle favorite status
    mutating func toggleFavorite() {
        isFavorite.toggle()
        favoriteAt = isFavorite ? Date() : nil
        lastUpdated = Date()
    }

    /// Mark as seen
    mutating func markAsSeen() {
        isSeen = true
        seenAt = Date()
        lastUpdated = Date()
    }

    /// Select for tonight
    mutating func selectForTonight() {
        isSelectedForTonight = true
        selectedAt = Date()
        lastUpdated = Date()
    }

    /// Deselect for tonight
    mutating func deselectForTonight() {
        isSelectedForTonight = false
        selectedAt = nil
        lastUpdated = Date()
    }

    /// Remove from history (cleanup)
    mutating func removeFromHistory() {
        isInHistory = false
        recommendedAt = nil
        lastUpdated = Date()
    }
}

// MARK: - Sorting Extensions

extension UserMovie {
    /// Sort by last interaction date (most recent first)
    static func sortByLastInteraction(_ movies: [UserMovie]) -> [UserMovie] {
        return movies.sorted { $0.lastUpdated > $1.lastUpdated }
    }

    /// Sort by recommendation date (most recent first)
    static func sortByRecommendation(_ movies: [UserMovie]) -> [UserMovie] {
        return movies.sorted {
            ($0.recommendedAt ?? Date.distantPast) > ($1.recommendedAt ?? Date.distantPast)
        }
    }
}

// MARK: - Array Extensions

extension Array where Element == UserMovie {
    /// Filter by tag
    func filtered(by tag: MovieTag) -> [UserMovie] {
        if tag == .all {
            return self
        }
        return filter { $0.hasTag(tag) }
    }

    /// Get current picks (should be max 5)
    var currentPicks: [UserMovie] {
        return filter { $0.isCurrentPick }
    }

    /// Get history movies (excluding current picks)
    var historyOnly: [UserMovie] {
        return filter { $0.isInHistory && !$0.isCurrentPick }
    }

    /// Get tonight's selection
    var tonightSelection: UserMovie? {
        return first { $0.isSelectedForTonight }
    }

    /// Get movies that can be cleaned up (no interactions, old history)
    var cleanupCandidates: [UserMovie] {
        return filter { movie in
            movie.isInHistory &&
                !movie.isCurrentPick &&
                !movie.hasOtherInteractions
        }
    }
}
