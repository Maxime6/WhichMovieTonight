//
//  UserMovieService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseFirestore
import Foundation

// MARK: - User Movie Service Protocol

protocol UserMovieServiceProtocol {
    // CRUD Operations
    func getUserMovie(userId: String, movieId: String) async throws -> UserMovie?
    func saveUserMovie(_ userMovie: UserMovie) async throws
    func updateUserMovie(_ userMovie: UserMovie) async throws
    func deleteUserMovie(userId: String, movieId: String) async throws

    // Bulk Operations
    func getUserMovies(userId: String, filter: MovieTag?) async throws -> [UserMovie]
    func saveUserMovies(_ userMovies: [UserMovie]) async throws

    // Interaction Operations
    func updateMovieInteraction(userId: String, movieId: String, _ update: (inout UserMovie) -> Void) async throws

    // Current Picks Management
    func getCurrentPicks(userId: String) async throws -> [UserMovie]
    func setCurrentPicks(userId: String, movies: [Movie]) async throws
    func clearCurrentPicks(userId: String) async throws

    // Tonight Selection
    func getTonightSelection(userId: String) async throws -> UserMovie?
    func setTonightSelection(userId: String, movieId: String) async throws
    func clearTonightSelection(userId: String) async throws

    // Cleanup Operations
    func cleanupOldHistory(userId: String, keepCount: Int) async throws
}

// MARK: - User Movie Service Implementation

final class UserMovieService: UserMovieServiceProtocol {
    private let db = Firestore.firestore()
    private let cache = UserMovieCache.shared

    // Collection paths: userMovies/{userId}/movies/{movieId}
    private func userMoviesCollection(userId: String) -> CollectionReference {
        return db.collection("userMovies").document(userId).collection("movies")
    }

    private func movieDocument(userId: String, movieId: String) -> DocumentReference {
        return userMoviesCollection(userId: userId).document(movieId)
    }

    // MARK: - CRUD Operations

    func getUserMovie(userId: String, movieId: String) async throws -> UserMovie? {
        // Check cache first
        if let cachedMovie = await cache.getCachedMovie(userId: userId, movieId: movieId) {
            return cachedMovie
        }

        // Fetch from Firestore
        let document = try await movieDocument(userId: userId, movieId: movieId).getDocument()

        guard document.exists else {
            print("📄 No UserMovie found for user \(userId), movie \(movieId)")
            return nil
        }

        let userMovie = try document.data(as: UserMovie.self)
        print("✅ UserMovie loaded: \(userMovie.movie.title)")

        // Cache the result
        await cache.cacheMovie(userMovie, userId: userId)

        return userMovie
    }

    func saveUserMovie(_ userMovie: UserMovie) async throws {
        do {
            try await movieDocument(userId: userMovie.userId, movieId: userMovie.movieId)
                .setData(from: userMovie)

            print("✅ UserMovie saved: \(userMovie.movie.title)")

            // Update cache
            await cache.cacheMovie(userMovie, userId: userMovie.userId)

        } catch {
            print("❌ Error saving UserMovie: \(error)")
            throw error
        }
    }

    func updateUserMovie(_ userMovie: UserMovie) async throws {
        var updatedMovie = userMovie
        updatedMovie.lastUpdated = Date()

        try await saveUserMovie(updatedMovie)
        print("🔄 UserMovie updated: \(userMovie.movie.title)")
    }

    func deleteUserMovie(userId: String, movieId: String) async throws {
        do {
            try await movieDocument(userId: userId, movieId: movieId).delete()
            print("🗑️ UserMovie deleted: \(movieId)")

            // Remove from cache
            await cache.removeCachedMovie(userId: userId, movieId: movieId)

        } catch {
            print("❌ Error deleting UserMovie: \(error)")
            throw error
        }
    }

    // MARK: - Bulk Operations

    func getUserMovies(userId: String, filter: MovieTag? = nil) async throws -> [UserMovie] {
        // Check cache first
        if let cachedMovies = await cache.getCachedMovies(userId: userId) {
            if let filter = filter {
                return cachedMovies.filtered(by: filter)
            }
            return cachedMovies
        }

        // Fetch from Firestore
        let snapshot = try await userMoviesCollection(userId: userId)
            .order(by: "lastUpdated", descending: true)
            .getDocuments()

        let userMovies = try snapshot.documents.compactMap { document in
            try document.data(as: UserMovie.self)
        }

        print("✅ Loaded \(userMovies.count) UserMovies for user \(userId)")

        // Cache all movies
        await cache.cacheMovies(userMovies, userId: userId)

        // Apply filter if needed
        if let filter = filter {
            return userMovies.filtered(by: filter)
        }

        return userMovies
    }

    func saveUserMovies(_ userMovies: [UserMovie]) async throws {
        let batch = db.batch()

        for userMovie in userMovies {
            let docRef = movieDocument(userId: userMovie.userId, movieId: userMovie.movieId)
            try batch.setData(from: userMovie, forDocument: docRef)
        }

        try await batch.commit()
        print("✅ Batch saved \(userMovies.count) UserMovies")

        // Update cache for each user
        let groupedByUser = Dictionary(grouping: userMovies) { $0.userId }
        for (userId, movies) in groupedByUser {
            await cache.cacheMovies(movies, userId: userId, append: true)
        }
    }

    // MARK: - Interaction Operations

    func updateMovieInteraction(userId: String, movieId: String, _ update: (inout UserMovie) -> Void) async throws {
        // Get existing movie or create new one if interaction on non-existing movie
        var userMovie: UserMovie

        if let existingMovie = try await getUserMovie(userId: userId, movieId: movieId) {
            userMovie = existingMovie
        } else {
            // This should rarely happen - means user is interacting with a movie not in system
            throw UserMovieError.movieNotFound
        }

        // Apply the update
        update(&userMovie)

        // Save updated movie
        try await updateUserMovie(userMovie)

        print("🔄 Movie interaction updated: \(userMovie.movie.title)")
    }

    // MARK: - Current Picks Management

    func getCurrentPicks(userId: String) async throws -> [UserMovie] {
        let allMovies = try await getUserMovies(userId: userId)
        return allMovies.currentPicks.sorted {
            ($0.currentPicksSince ?? Date.distantPast) > ($1.currentPicksSince ?? Date.distantPast)
        }
    }

    func setCurrentPicks(userId: String, movies: [Movie]) async throws {
        // First, clear existing current picks
        try await clearCurrentPicks(userId: userId)

        // Create UserMovies for new picks
        var newUserMovies: [UserMovie] = []

        for movie in movies {
            var userMovie: UserMovie

            // Check if movie already exists (from history or interactions)
            if let existingMovie = try await getUserMovie(userId: userId, movieId: movie.id) {
                userMovie = existingMovie
            } else {
                // Create new UserMovie
                userMovie = UserMovie(userId: userId, movie: movie)
            }

            // Mark as current pick
            userMovie.markAsCurrentPick()
            newUserMovies.append(userMovie)
        }

        // Save all new picks
        try await saveUserMovies(newUserMovies)
        print("✅ Set \(movies.count) new current picks for user \(userId)")

        // Invalidate cache for this user
        await cache.invalidateCache(userId: userId)
    }

    func clearCurrentPicks(userId: String) async throws {
        let currentPicks = try await getCurrentPicks(userId: userId)

        var updatedMovies: [UserMovie] = []
        for var pick in currentPicks {
            pick.removeFromCurrentPicks()
            updatedMovies.append(pick)
        }

        if !updatedMovies.isEmpty {
            try await saveUserMovies(updatedMovies)
            print("🔄 Cleared \(updatedMovies.count) current picks for user \(userId)")
        }

        // Invalidate cache
        await cache.invalidateCache(userId: userId)
    }

    // MARK: - Tonight Selection

    func getTonightSelection(userId: String) async throws -> UserMovie? {
        let allMovies = try await getUserMovies(userId: userId)
        return allMovies.tonightSelection
    }

    func setTonightSelection(userId: String, movieId: String) async throws {
        // Clear any existing tonight selection first
        try await clearTonightSelection(userId: userId)

        // Set new selection
        try await updateMovieInteraction(userId: userId, movieId: movieId) { movie in
            movie.selectForTonight()
        }

        print("✅ Set tonight selection: \(movieId)")
    }

    func clearTonightSelection(userId: String) async throws {
        if let currentSelection = try await getTonightSelection(userId: userId) {
            try await updateMovieInteraction(userId: userId, movieId: currentSelection.movieId) { movie in
                movie.deselectForTonight()
            }
            print("🔄 Cleared tonight selection")
        }
    }

    // MARK: - Cleanup Operations

    func cleanupOldHistory(userId: String, keepCount: Int = 50) async throws {
        let allMovies = try await getUserMovies(userId: userId)
        let historyMovies = allMovies.historyOnly.sorted {
            ($0.recommendedAt ?? Date.distantPast) > ($1.recommendedAt ?? Date.distantPast)
        }

        if historyMovies.count > keepCount {
            let toProcess = Array(historyMovies.dropFirst(keepCount))
            let cleanupCandidates = toProcess.filter { !$0.hasOtherInteractions }
            let keepButRemoveHistory = toProcess.filter { $0.hasOtherInteractions }

            // Delete movies with no other interactions
            for movie in cleanupCandidates {
                try await deleteUserMovie(userId: userId, movieId: movie.movieId)
            }

            // Just remove from history for movies with other interactions
            var moviesToUpdate: [UserMovie] = []
            for var movie in keepButRemoveHistory {
                movie.removeFromHistory()
                moviesToUpdate.append(movie)
            }

            if !moviesToUpdate.isEmpty {
                try await saveUserMovies(moviesToUpdate)
            }

            print("🧹 Cleanup completed: deleted \(cleanupCandidates.count), updated \(moviesToUpdate.count)")

            // Invalidate cache
            await cache.invalidateCache(userId: userId)
        }
    }
}

// MARK: - User Movie Errors

enum UserMovieError: LocalizedError {
    case movieNotFound
    case userNotAuthenticated
    case invalidMovieData

    var errorDescription: String? {
        switch self {
        case .movieNotFound:
            return "Movie not found in user's collection"
        case .userNotAuthenticated:
            return "User must be authenticated"
        case .invalidMovieData:
            return "Invalid movie data provided"
        }
    }
}
