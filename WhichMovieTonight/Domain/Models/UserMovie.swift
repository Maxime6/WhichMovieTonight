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

    // MARK: - Custom Coding Keys for Migration

    enum CodingKeys: String, CodingKey {
        case id, movieId, userId, movie
        case isCurrentPick, isInHistory, isLiked, isDisliked, isFavorite, isSeen
        case isToWatch, isAISearchResult
        case isSelectedForTonight // For backward compatibility
        case recommendedAt, currentPicksSince, likedAt, dislikedAt, favoriteAt, seenAt
        case toWatchAt
        case selectedAt // For backward compatibility
        case lastUpdated
    }

    // MARK: - Movie States

    var isCurrentPick: Bool = false
    var isInHistory: Bool = false
    var isLiked: Bool = false
    var isDisliked: Bool = false
    var isFavorite: Bool = false
    var isSeen: Bool = false
    var isToWatch: Bool = false
    var isAISearchResult: Bool = false

    // MARK: - Timestamps

    var recommendedAt: Date?
    var currentPicksSince: Date?
    var likedAt: Date?
    var dislikedAt: Date?
    var favoriteAt: Date?
    var seenAt: Date?
    var toWatchAt: Date?
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
        isToWatch: Bool = false,
        isAISearchResult: Bool = false
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
        self.isToWatch = isToWatch
        self.isAISearchResult = isAISearchResult
        lastUpdated = Date()
    }

    // MARK: - Custom Encoding/Decoding for Migration

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        movieId = try container.decode(String.self, forKey: .movieId)
        userId = try container.decode(String.self, forKey: .userId)
        movie = try container.decode(Movie.self, forKey: .movie)

        // Decode boolean states
        isCurrentPick = try container.decodeIfPresent(Bool.self, forKey: .isCurrentPick) ?? false
        isInHistory = try container.decodeIfPresent(Bool.self, forKey: .isInHistory) ?? false
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        isDisliked = try container.decodeIfPresent(Bool.self, forKey: .isDisliked) ?? false
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isSeen = try container.decodeIfPresent(Bool.self, forKey: .isSeen) ?? false

        // Handle migration from isSelectedForTonight to isToWatch
        let oldIsSelectedForTonight = try container.decodeIfPresent(Bool.self, forKey: .isSelectedForTonight) ?? false
        let newIsToWatch = try container.decodeIfPresent(Bool.self, forKey: .isToWatch) ?? false
        isToWatch = oldIsSelectedForTonight || newIsToWatch

        // Decode AI search result flag
        isAISearchResult = try container.decodeIfPresent(Bool.self, forKey: .isAISearchResult) ?? false

        // Decode timestamps
        recommendedAt = try container.decodeIfPresent(Date.self, forKey: .recommendedAt)
        currentPicksSince = try container.decodeIfPresent(Date.self, forKey: .currentPicksSince)
        likedAt = try container.decodeIfPresent(Date.self, forKey: .likedAt)
        dislikedAt = try container.decodeIfPresent(Date.self, forKey: .dislikedAt)
        favoriteAt = try container.decodeIfPresent(Date.self, forKey: .favoriteAt)
        seenAt = try container.decodeIfPresent(Date.self, forKey: .seenAt)

        // Handle migration from selectedAt to toWatchAt
        let oldSelectedAt = try container.decodeIfPresent(Date.self, forKey: .selectedAt)
        let newToWatchAt = try container.decodeIfPresent(Date.self, forKey: .toWatchAt)
        toWatchAt = newToWatchAt ?? oldSelectedAt

        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(movieId, forKey: .movieId)
        try container.encode(userId, forKey: .userId)
        try container.encode(movie, forKey: .movie)

        // Encode boolean states
        try container.encode(isCurrentPick, forKey: .isCurrentPick)
        try container.encode(isInHistory, forKey: .isInHistory)
        try container.encode(isLiked, forKey: .isLiked)
        try container.encode(isDisliked, forKey: .isDisliked)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(isSeen, forKey: .isSeen)
        try container.encode(isToWatch, forKey: .isToWatch)
        try container.encode(isAISearchResult, forKey: .isAISearchResult)

        // Encode timestamps
        try container.encodeIfPresent(recommendedAt, forKey: .recommendedAt)
        try container.encodeIfPresent(currentPicksSince, forKey: .currentPicksSince)
        try container.encodeIfPresent(likedAt, forKey: .likedAt)
        try container.encodeIfPresent(dislikedAt, forKey: .dislikedAt)
        try container.encodeIfPresent(favoriteAt, forKey: .favoriteAt)
        try container.encodeIfPresent(seenAt, forKey: .seenAt)
        try container.encodeIfPresent(toWatchAt, forKey: .toWatchAt)
        try container.encode(lastUpdated, forKey: .lastUpdated)
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
        if isToWatch { tags.append(.toWatch) }
        if isAISearchResult { tags.append(.aiSearch) }

        return tags
    }

    /// Check if movie has any interactions (for cleanup logic)
    var hasOtherInteractions: Bool {
        return isLiked || isDisliked || isFavorite || isSeen || isToWatch
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

    /// Add to watchlist
    mutating func addToWatchlist() {
        isToWatch = true
        toWatchAt = Date()
        lastUpdated = Date()
    }

    /// Remove from watchlist
    mutating func removeFromWatchlist() {
        isToWatch = false
        toWatchAt = nil
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

    /// Get watchlist movies
    var watchlistMovies: [UserMovie] {
        return filter { $0.isToWatch }
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
