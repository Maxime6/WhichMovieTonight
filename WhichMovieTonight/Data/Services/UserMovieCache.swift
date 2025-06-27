//
//  UserMovieCache.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import Foundation

// MARK: - User Movie Cache

@MainActor
final class UserMovieCache: ObservableObject {
    static let shared = UserMovieCache()

    // Cache structure: [userId: [movieId: UserMovie]]
    private var movieCache: [String: [String: UserMovie]] = [:]
    private var userMoviesCache: [String: [UserMovie]] = [:]
    private var lastFetch: [String: Date] = [:]

    // Cache settings
    private let cacheExpiry: TimeInterval = 300 // 5 minutes
    private let maxCacheSize = 1000 // Maximum movies to cache per user

    private init() {}

    // MARK: - Single Movie Operations

    /// Get a cached movie for a specific user and movieId
    func getCachedMovie(userId: String, movieId: String) -> UserMovie? {
        guard isCacheValid(userId: userId) else {
            return nil
        }

        return movieCache[userId]?[movieId]
    }

    /// Cache a single movie
    func cacheMovie(_ movie: UserMovie, userId: String) {
        // Initialize cache for user if needed
        if movieCache[userId] == nil {
            movieCache[userId] = [:]
            userMoviesCache[userId] = []
        }

        // Update single movie cache
        movieCache[userId]?[movie.movieId] = movie

        // Update user movies cache
        if var userMovies = userMoviesCache[userId] {
            // Remove existing movie if present
            userMovies.removeAll { $0.movieId == movie.movieId }
            // Add updated movie
            userMovies.append(movie)
            userMoviesCache[userId] = userMovies
        }

        // Update last fetch time
        lastFetch[userId] = Date()

        print("💾 Cached movie: \(movie.movie.title) for user \(userId)")
    }

    /// Remove a cached movie
    func removeCachedMovie(userId: String, movieId: String) {
        movieCache[userId]?.removeValue(forKey: movieId)
        userMoviesCache[userId]?.removeAll { $0.movieId == movieId }

        print("🗑️ Removed cached movie: \(movieId) for user \(userId)")
    }

    // MARK: - Bulk Movie Operations

    /// Get all cached movies for a user
    func getCachedMovies(userId: String) -> [UserMovie]? {
        guard isCacheValid(userId: userId) else {
            return nil
        }

        return userMoviesCache[userId]
    }

    /// Cache multiple movies for a user
    func cacheMovies(_ movies: [UserMovie], userId: String, append: Bool = false) {
        if append && userMoviesCache[userId] != nil {
            // Append to existing cache
            var existingMovies = userMoviesCache[userId] ?? []
            for movie in movies {
                // Remove existing if present, then add updated
                existingMovies.removeAll { $0.movieId == movie.movieId }
                existingMovies.append(movie)
            }
            userMoviesCache[userId] = existingMovies
        } else {
            // Replace entire cache
            userMoviesCache[userId] = movies
        }

        // Update single movie cache
        if movieCache[userId] == nil {
            movieCache[userId] = [:]
        }

        for movie in movies {
            movieCache[userId]?[movie.movieId] = movie
        }

        // Enforce cache size limit
        enforceCacheLimit(userId: userId)

        // Update last fetch time
        lastFetch[userId] = Date()

        print("💾 Cached \(movies.count) movies for user \(userId)")
    }

    // MARK: - Cache Management

    /// Invalidate cache for a specific user
    func invalidateCache(userId: String) {
        movieCache.removeValue(forKey: userId)
        userMoviesCache.removeValue(forKey: userId)
        lastFetch.removeValue(forKey: userId)

        print("🔄 Cache invalidated for user \(userId)")
    }

    /// Invalidate all cache
    func invalidateAllCache() {
        movieCache.removeAll()
        userMoviesCache.removeAll()
        lastFetch.removeAll()

        print("🔄 All cache invalidated")
    }

    /// Check if cache is valid for a user
    private func isCacheValid(userId: String) -> Bool {
        guard let lastFetchDate = lastFetch[userId] else {
            return false
        }

        let isValid = Date().timeIntervalSince(lastFetchDate) < cacheExpiry

        if !isValid {
            print("⏰ Cache expired for user \(userId)")
            invalidateCache(userId: userId)
        }

        return isValid
    }

    /// Enforce cache size limit to prevent memory issues
    private func enforceCacheLimit(userId: String) {
        guard let userMovies = userMoviesCache[userId],
              userMovies.count > maxCacheSize
        else {
            return
        }

        // Keep most recently updated movies
        let sortedMovies = userMovies.sorted { $0.lastUpdated > $1.lastUpdated }
        let trimmedMovies = Array(sortedMovies.prefix(maxCacheSize))

        userMoviesCache[userId] = trimmedMovies

        // Update single movie cache
        movieCache[userId] = Dictionary(uniqueKeysWithValues:
            trimmedMovies.map { ($0.movieId, $0) }
        )

        print("✂️ Cache trimmed to \(trimmedMovies.count) movies for user \(userId)")
    }

    // MARK: - Cache Statistics

    /// Get cache statistics for debugging
    func getCacheStats() -> CacheStats {
        let totalUsers = movieCache.keys.count
        let totalMovies = movieCache.values.reduce(0) { $0 + $1.count }
        let validCaches = movieCache.keys.filter { isCacheValid(userId: $0) }.count

        return CacheStats(
            totalUsers: totalUsers,
            totalMovies: totalMovies,
            validCaches: validCaches,
            cacheHitRate: calculateCacheHitRate()
        )
    }

    private var cacheHits = 0
    private var cacheMisses = 0

    private func calculateCacheHitRate() -> Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0.0 }
        return Double(cacheHits) / Double(total)
    }

    /// Track cache hit for statistics
    func trackCacheHit() {
        cacheHits += 1
    }

    /// Track cache miss for statistics
    func trackCacheMiss() {
        cacheMisses += 1
    }
}

// MARK: - Cache Statistics

struct CacheStats {
    let totalUsers: Int
    let totalMovies: Int
    let validCaches: Int
    let cacheHitRate: Double

    var description: String {
        """
        📊 Cache Statistics:
        - Users: \(totalUsers)
        - Movies: \(totalMovies) 
        - Valid Caches: \(validCaches)
        - Hit Rate: \(String(format: "%.1f", cacheHitRate * 100))%
        """
    }
}

// MARK: - Cache Configuration

extension UserMovieCache {
    /// Configure cache settings
    func configureCacheSettings(expiryInterval _: TimeInterval? = nil, maxSize _: Int? = nil) {
        // These would need to be made mutable if we want runtime configuration
        print("⚙️ Cache configuration: expiry=\(cacheExpiry)s, maxSize=\(maxCacheSize)")
    }
}
