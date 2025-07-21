//
//  UserMovieData.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseFirestore
import Foundation

// MARK: - Simple User Data Model

struct UserMovieData: Codable {
    let id: String
    let userId: String
    let currentPicks: [MovieFirestore] // Les 5 films actuellement recommandés
    let generationHistory: [MovieFirestore] // Les 10 dernières générations (pour éviter répétitions)
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Migration Support for Old Data Structure

    enum CodingKeys: String, CodingKey {
        case id, userId, currentPicks, generationHistory, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle required fields with fallbacks for migration
        userId = try container.decode(String.self, forKey: .userId)

        // If old data doesn't have an id, generate one
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString

        // Handle new fields with fallbacks for old data
        currentPicks = try container.decodeIfPresent([MovieFirestore].self, forKey: .currentPicks) ?? []
        generationHistory = try container.decodeIfPresent([MovieFirestore].self, forKey: .generationHistory) ?? []

        // Handle dates with fallbacks
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(currentPicks, forKey: .currentPicks)
        try container.encode(generationHistory, forKey: .generationHistory)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    init(userId: String, currentPicks: [MovieFirestore] = []) {
        id = UUID().uuidString
        self.userId = userId
        self.currentPicks = currentPicks
        generationHistory = []
        createdAt = Date()
        updatedAt = Date()
    }

    // Helper to add new generation and maintain history limit
    func withNewGeneration(_ newPicks: [MovieFirestore]) -> UserMovieData {
        var newHistory = generationHistory
        newHistory.append(contentsOf: newPicks)

        // Keep only last 10 movies in history
        if newHistory.count > 10 {
            newHistory = Array(newHistory.suffix(10))
        }

        return UserMovieData(
            id: id,
            userId: userId,
            currentPicks: newPicks,
            generationHistory: newHistory,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Helper init for UserMovieData

extension UserMovieData {
    init(id: String, userId: String, currentPicks: [MovieFirestore], generationHistory: [MovieFirestore], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.currentPicks = currentPicks
        self.generationHistory = generationHistory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct MovieFirestore: Codable, Identifiable {
    let id: String
    let title: String
    let overview: String?
    let posterURL: String?
    let releaseDate: Date?
    let genres: [String]
    let streamingPlatforms: [String]
    let director: String?
    let actors: String?
    let runtime: String?
    let imdbRating: String?
    let imdbID: String?
    let year: String?
    let rated: String?
    let awards: String?
    let createdAt: Date

    init(from movie: Movie) {
        id = UUID().uuidString
        title = movie.title
        overview = movie.overview
        posterURL = movie.posterURL?.absoluteString
        releaseDate = movie.releaseDate
        genres = movie.genres
        streamingPlatforms = movie.streamingPlatforms
        director = movie.director
        actors = movie.actors
        runtime = movie.runtime
        imdbRating = movie.imdbRating
        imdbID = movie.id // Use movie.id (which is the imdbID in new structure)
        year = movie.year
        rated = movie.rated
        awards = movie.awards
        createdAt = Date()
    }

    func toMovie() -> Movie {
        return Movie(
            id: imdbID ?? id, // Use imdbID if available, fallback to id
            title: title,
            overview: overview,
            posterURL: posterURL != nil ? URL(string: posterURL!) : nil,
            releaseDate: releaseDate,
            genres: genres,
            streamingPlatforms: streamingPlatforms,
            director: director,
            actors: actors,
            runtime: runtime,
            imdbRating: imdbRating,
            year: year,
            rated: rated,
            awards: awards
        )
    }
}
