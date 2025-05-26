//
//  MovieRepositoryImpl.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 02/05/2025.
//

import Foundation

final class MovieRepositoryImpl: MovieRepository {
    private let openAIService = OpenAIService()
    private let omdbService = OMDBService()

    func findSuggestedMovie(movieGenre: [MovieGenre]) async throws -> Movie {
        // 1. Obtenir la suggestion d'OpenAI
        let movieDTO = try await openAIService.getMovieSuggestion(for: ["netflix"], movieGenre: movieGenre, mood: "happy")
        print("OpenAI suggested movie: \(movieDTO.title)")

        // 2. Enrichir avec les données OMDB
        do {
            let omdbMovie = try await omdbService.getMovieDetailsByTitle(title: movieDTO.title)
            print("OMDB data retrieved for: \(omdbMovie.title)")

            // 3. Créer le film avec les données OMDB enrichies
            let movie = Movie(
                from: omdbMovie,
                originalGenres: movieDTO.genres,
                originalPlatforms: movieDTO.platforms
            )

            return movie
        } catch {
            print("Failed to get OMDB data for \(movieDTO.title): \(error)")

            // 4. Fallback: créer le film avec les données OpenAI seulement
            let movie = Movie(
                title: movieDTO.title,
                overview: nil,
                posterURL: URL(string: movieDTO.posterUrl),
                releaseDate: Date(),
                genres: movieDTO.genres,
                streamingPlatforms: movieDTO.platforms,
                director: nil,
                actors: nil,
                runtime: nil,
                imdbRating: nil,
                imdbID: nil,
                year: nil,
                rated: nil,
                awards: nil
            )

            return movie
        }
    }
}
