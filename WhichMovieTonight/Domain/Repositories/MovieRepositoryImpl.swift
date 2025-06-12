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

    func findSuggestedMovie(
        movieGenre: [MovieGenre],
        streamingPlatforms: [StreamingPlatform],
        userInteractions: UserMovieInteractions?,
        favoriteActors: [String],
        favoriteGenres: [MovieGenre],
        recentSuggestions: [MovieFirestore]
    ) async throws -> Movie {
        // Vérifications préalables
        guard !movieGenre.isEmpty else {
            throw URLError(.badURL)
        }

        guard !streamingPlatforms.isEmpty else {
            throw URLError(.badURL)
        }

        // 1. Obtenir la suggestion d'OpenAI
        do {
            let platformNames = streamingPlatforms.map { $0.rawValue }
            let movieDTO = try await openAIService.getMovieSuggestion(
                for: platformNames,
                movieGenre: movieGenre,
                userInteractions: userInteractions,
                favoriteActors: favoriteActors,
                favoriteGenres: favoriteGenres,
                recentSuggestions: recentSuggestions
            )
            print("OpenAI suggested movie: \(movieDTO.title)")

            return try await processMovieSuggestion(movieDTO)
        } catch {
            print("Failed to get OpenAI suggestion: \(error)")
            throw error
        }
    }

    private func processMovieSuggestion(_ movieDTO: OpenAIMovieDTO) async throws -> Movie {
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
            return createFallbackMovie(from: movieDTO)
        }
    }

    private func createFallbackMovie(from movieDTO: OpenAIMovieDTO) -> Movie {
        return Movie(
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
    }
}
