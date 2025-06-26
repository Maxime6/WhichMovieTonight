//
//  MovieInteractionService.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on [Current Date]
//

import FirebaseAuth
import Foundation

// MARK: - Movie Interaction Service Protocol

protocol MovieInteractionServiceProtocol {
    func getMovieInteraction(for movie: Movie) async throws -> UserMovieInteraction?
    func toggleLike(for movie: Movie) async throws -> MovieLikeStatus
    func toggleDislike(for movie: Movie) async throws -> MovieLikeStatus
    func toggleFavorite(for movie: Movie) async throws -> Bool
    func markAsSeen(for movie: Movie) async throws
}

// MARK: - Movie Interaction Service Implementation

final class MovieInteractionService: MovieInteractionServiceProtocol {
    // MARK: - Dependencies

    private let firestoreService: FirestoreService

    // MARK: - Initialization

    init(firestoreService: FirestoreService = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    // MARK: - Public Methods

    /// Get current interaction status for a movie
    func getMovieInteraction(for movie: Movie) async throws -> UserMovieInteraction? {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        return try await firestoreService.getMovieInteraction(
            movieId: movie.uniqueId,
            for: userId
        )
    }

    /// Toggle like status for a movie (like/none)
    func toggleLike(for movie: Movie) async throws -> MovieLikeStatus {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        let newStatus = try await firestoreService.toggleMovieLike(movie: movie, for: userId)
        print("✅ Movie like toggled: \(movie.title) -> \(newStatus)")
        return newStatus
    }

    /// Toggle dislike status for a movie (dislike/none)
    func toggleDislike(for movie: Movie) async throws -> MovieLikeStatus {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        let newStatus = try await firestoreService.toggleMovieDislike(movie: movie, for: userId)
        print("✅ Movie dislike toggled: \(movie.title) -> \(newStatus)")
        return newStatus
    }

    /// Toggle favorite status for a movie
    func toggleFavorite(for movie: Movie) async throws -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        let newStatus = try await firestoreService.toggleMovieFavorite(movie: movie, for: userId)
        print("✅ Movie favorite toggled: \(movie.title) -> \(newStatus)")
        return newStatus
    }

    /// Mark movie as seen (watched)
    func markAsSeen(for movie: Movie) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        let seenMovie = SeenMovie(from: movie, userId: userId)
        try await firestoreService.markMovieAsSeen(seenMovie, for: userId)
        print("✅ Movie marked as seen: \(movie.title)")
    }

    // MARK: - Utility Methods

    /// Get interaction status icons for UI
    func getInteractionIcons(for interaction: UserMovieInteraction?) -> (like: String, dislike: String, favorite: String) {
        let likeStatus = interaction?.likeStatus ?? .none
        let isFavorite = interaction?.isFavorite ?? false

        return (
            like: likeStatus == .liked ? "hand.thumbsup.fill" : "hand.thumbsup",
            dislike: likeStatus == .disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown",
            favorite: isFavorite ? "heart.fill" : "heart"
        )
    }

    /// Check if movie is marked as seen
    func isSeen(movie: Movie) async throws -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        let seenMovies = try await firestoreService.getSeenMovies(for: userId)
        return seenMovies.contains { $0.movieId == movie.uniqueId }
    }
}

// MARK: - Movie Interaction Errors

enum MovieInteractionError: LocalizedError {
    case userNotAuthenticated
    case movieNotFound
    case interactionFailed

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated. Please sign in."
        case .movieNotFound:
            return "Movie not found."
        case .interactionFailed:
            return "Failed to update movie interaction. Please try again."
        }
    }
}
