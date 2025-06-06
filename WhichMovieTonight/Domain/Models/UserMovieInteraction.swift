//
//  UserMovieInteraction.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation

// MARK: - User Movie Interaction Types

enum MovieLikeStatus: String, Codable, CaseIterable {
    case none
    case liked
    case disliked

    var icon: String {
        switch self {
        case .none: return "hand.thumbsup"
        case .liked: return "hand.thumbsup.fill"
        case .disliked: return "hand.thumbsdown.fill"
        }
    }

    var color: String {
        switch self {
        case .none: return "gray"
        case .liked: return "blue"
        case .disliked: return "red"
        }
    }
}

// MARK: - User Movie Interaction Model

struct UserMovieInteraction: Identifiable, Codable {
    let id: String
    let movieId: String // Using imdbID or title as unique identifier
    let movieTitle: String
    let posterURL: String?
    var likeStatus: MovieLikeStatus
    var isFavorite: Bool
    let createdAt: Date
    var updatedAt: Date

    init(movieId: String, movieTitle: String, posterURL: String? = nil, likeStatus: MovieLikeStatus = .none, isFavorite: Bool = false) {
        id = UUID().uuidString
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.posterURL = posterURL
        self.likeStatus = likeStatus
        self.isFavorite = isFavorite
        createdAt = Date()
        updatedAt = Date()
    }
}

// MARK: - User Interactions Data

struct UserMovieInteractions: Codable {
    let userId: String
    var interactions: [String: UserMovieInteraction] // Key is movieId
    let createdAt: Date
    var updatedAt: Date

    init(userId: String) {
        self.userId = userId
        interactions = [:]
        createdAt = Date()
        updatedAt = Date()
    }

    var favoriteMovies: [UserMovieInteraction] {
        return interactions.values.filter { $0.isFavorite }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var likedMovies: [UserMovieInteraction] {
        return interactions.values.filter { $0.likeStatus == .liked }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var dislikedMovies: [UserMovieInteraction] {
        return interactions.values.filter { $0.likeStatus == .disliked }.sorted { $0.updatedAt > $1.updatedAt }
    }
}

// MARK: - Extension for Movie

extension Movie {
    var uniqueId: String {
        return imdbID ?? title.replacingOccurrences(of: " ", with: "").lowercased()
    }
}
