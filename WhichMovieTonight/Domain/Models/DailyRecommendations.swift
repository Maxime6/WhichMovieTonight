//
//  DailyRecommendations.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import Foundation

// MARK: - Daily Recommendations Model

struct DailyRecommendations: Codable {
    let id: String
    let userId: String
    let date: Date
    let movies: [MovieFirestore]
    let generatedAt: Date

    init(userId: String, date: Date, movies: [MovieFirestore]) {
        id = UUID().uuidString
        self.userId = userId
        self.date = date
        self.movies = movies
        generatedAt = Date()
    }
}

// MARK: - Seen Movie Model

struct SeenMovie: Codable, Identifiable {
    let id: String
    let movieId: String
    let title: String
    let posterURL: String?
    let seenAt: Date
    let userId: String

    init(movieId: String, title: String, posterURL: String?, userId: String) {
        id = UUID().uuidString
        self.movieId = movieId
        self.title = title
        self.posterURL = posterURL
        seenAt = Date()
        self.userId = userId
    }

    // Conversion depuis Movie
    init(from movie: Movie, userId: String) {
        self.init(
            movieId: movie.imdbID ?? movie.title,
            title: movie.title,
            posterURL: movie.posterURL?.absoluteString,
            userId: userId
        )
    }
}

// Extensions pour les conversions
extension SeenMovie {
    func toMovie() -> Movie {
        // Créer un Movie directement avec les données disponibles
        return Movie(
            title: title,
            overview: nil,
            posterURL: posterURL != nil ? URL(string: posterURL!) : nil,
            releaseDate: nil,
            genres: [],
            streamingPlatforms: [],
            director: nil,
            actors: nil,
            runtime: nil,
            imdbRating: nil,
            imdbID: movieId,
            year: nil,
            rated: nil,
            awards: nil
        )
    }
}

// MARK: - Recommendation Cache Model

struct RecommendationCache: Codable {
    let userId: String
    let lastGenerationDate: Date
    let recommendationHistory: [String] // Movie IDs to avoid
    let seenMovies: [SeenMovie]

    init(userId: String) {
        self.userId = userId
        lastGenerationDate = Date.distantPast
        recommendationHistory = []
        seenMovies = []
    }

    func shouldGenerateNewRecommendations() -> Bool {
        let calendar = Calendar.current
        return !calendar.isDate(lastGenerationDate, inSameDayAs: Date())
    }

    func getRecentMovieIds(daysBack _: Int = 30) -> [String] {
        // Cette implémentation simplifiée retourne tous les IDs d'historique
        // Dans une implémentation plus complexe, nous filtrerions par date
        return recommendationHistory
    }

    func getSeenMovieIds() -> [String] {
        return seenMovies.map { $0.movieId }
    }
}
