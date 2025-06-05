//
//  UserMovieData.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseFirestore
import Foundation

struct UserMovieData: Codable {
    let id: String
    let userId: String
    let selectedMovie: MovieFirestore?
    let lastSuggestions: [MovieFirestore]
    let createdAt: Date
    let updatedAt: Date

    init(userId: String, selectedMovie: MovieFirestore? = nil, lastSuggestions: [MovieFirestore] = []) {
        id = UUID().uuidString
        self.userId = userId
        self.selectedMovie = selectedMovie
        self.lastSuggestions = lastSuggestions
        createdAt = Date()
        updatedAt = Date()
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
        imdbID = movie.imdbID
        year = movie.year
        rated = movie.rated
        awards = movie.awards
        createdAt = Date()
    }

    func toMovie() -> Movie {
        return Movie(
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
            imdbID: imdbID,
            year: year,
            rated: rated,
            awards: awards
        )
    }
}
