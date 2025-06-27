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
    func saveInteraction(_ interaction: UserMovieInteraction) async throws
    func markAsSeen(for movie: Movie) async throws
    func isSeen(movie: Movie) async throws -> Bool
    func toggleLike(for movie: Movie) async throws -> MovieLikeStatus
    func toggleDislike(for movie: Movie) async throws -> MovieLikeStatus
    func toggleFavorite(for movie: Movie) async throws -> Bool
}

// MARK: - Movie Interaction Service Implementation

final class MovieInteractionService: MovieInteractionServiceProtocol {
    // MARK: - Dependencies

    private let firestoreService: FirestoreServiceProtocol

    // MARK: - Initialization

    init(firestoreService: FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    // MARK: - Public Methods

    /// Get current interaction status for a movie
    func getMovieInteraction(for movie: Movie) async throws -> UserMovieInteraction? {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        let interactions = try await firestoreService.getUserMovieInteractions(for: userId)
        return interactions?.interactions[movie.uniqueId]
    }

    /// Save interaction for a movie
    func saveInteraction(_ interaction: UserMovieInteraction) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        try await firestoreService.saveUserMovieInteraction(interaction, for: userId)
        print("✅ Movie interaction saved: \(interaction.movieId)")
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

    /// Check if movie is marked as seen
    func isSeen(movie: Movie) async throws -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        let seenMovies = try await firestoreService.getSeenMovies(for: userId)
        return seenMovies.contains { $0.movieId == movie.uniqueId }
    }

    /// Toggle like status for a movie
    func toggleLike(for movie: Movie) async throws -> MovieLikeStatus {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        var interactions = try await firestoreService.getUserMovieInteractions(for: userId) ?? UserMovieInteractions(userId: userId)

        let movieId = movie.uniqueId
        var interaction = interactions.interactions[movieId] ?? UserMovieInteraction(
            movieId: movieId,
            movieTitle: movie.title,
            posterURL: movie.posterURL?.absoluteString
        )

        // Toggle like status
        interaction.likeStatus = interaction.likeStatus == MovieLikeStatus.liked ? MovieLikeStatus.none : MovieLikeStatus.liked
        interaction.updatedAt = Date()

        interactions.interactions[movieId] = interaction
        interactions.updatedAt = Date()

        try await firestoreService.saveUserMovieInteraction(interaction, for: userId)

        return interaction.likeStatus
    }

    /// Toggle dislike status for a movie
    func toggleDislike(for movie: Movie) async throws -> MovieLikeStatus {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        var interactions = try await firestoreService.getUserMovieInteractions(for: userId) ?? UserMovieInteractions(userId: userId)

        let movieId = movie.uniqueId
        var interaction = interactions.interactions[movieId] ?? UserMovieInteraction(
            movieId: movieId,
            movieTitle: movie.title,
            posterURL: movie.posterURL?.absoluteString
        )

        // Toggle dislike status
        interaction.likeStatus = interaction.likeStatus == MovieLikeStatus.disliked ? MovieLikeStatus.none : MovieLikeStatus.disliked
        interaction.updatedAt = Date()

        interactions.interactions[movieId] = interaction
        interactions.updatedAt = Date()

        try await firestoreService.saveUserMovieInteraction(interaction, for: userId)

        return interaction.likeStatus
    }

    /// Toggle favorite status for a movie
    func toggleFavorite(for movie: Movie) async throws -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MovieInteractionError.userNotAuthenticated
        }

        var interactions = try await firestoreService.getUserMovieInteractions(for: userId) ?? UserMovieInteractions(userId: userId)

        let movieId = movie.uniqueId
        var interaction = interactions.interactions[movieId] ?? UserMovieInteraction(
            movieId: movieId,
            movieTitle: movie.title,
            posterURL: movie.posterURL?.absoluteString
        )

        // Toggle favorite status
        interaction.isFavorite.toggle()
        interaction.updatedAt = Date()

        interactions.interactions[movieId] = interaction
        interactions.updatedAt = Date()

        try await firestoreService.saveUserMovieInteraction(interaction, for: userId)

        return interaction.isFavorite
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
