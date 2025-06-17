//
//  GetDailyRecommendationsUseCase.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation

protocol GetDailyRecommendationsUseCase {
    func execute(
        userPreferences: UserPreferencesService,
        userInteractions: UserMovieInteractions?,
        excludeMovieIds: [String]
    ) async throws -> [Movie]
}

final class GetDailyRecommendationsUseCaseImpl: GetDailyRecommendationsUseCase {
    private let repository: MovieRepository

    init(repository: MovieRepository) {
        self.repository = repository
    }

    func execute(
        userPreferences: UserPreferencesService,
        userInteractions: UserMovieInteractions?,
        excludeMovieIds: [String]
    ) async throws -> [Movie] {
        // Validation des préférences utilisateur
        guard !userPreferences.favoriteGenres.isEmpty else {
            throw RecommendationError.missingPreferences("Aucun genre favori défini")
        }

        guard !userPreferences.favoriteStreamingPlatforms.isEmpty else {
            throw RecommendationError.missingPreferences("Aucune plateforme de streaming définie")
        }

        // Utiliser le repository existant mais adapter pour 5 films
        var recommendations: [Movie] = []
        let maxAttempts = 10 // Éviter les boucles infinies
        var attempts = 0

        // Convertir les IDs à exclure en MovieFirestore pour compatibilité
        let excludeMoviesFirestore = excludeMovieIds.map { id in
            // Créer un Movie temporaire avec l'ID à exclure
            let tempMovie = Movie(
                title: "",
                overview: nil,
                posterURL: nil,
                releaseDate: nil,
                genres: [],
                streamingPlatforms: [],
                director: nil,
                actors: nil,
                runtime: nil,
                imdbRating: nil,
                imdbID: id,
                year: nil,
                rated: nil,
                awards: nil
            )
            return MovieFirestore(from: tempMovie)
        }

        while recommendations.count < 5 && attempts < maxAttempts {
            do {
                let movie = try await repository.findSuggestedMovie(
                    movieGenre: userPreferences.favoriteGenres,
                    streamingPlatforms: userPreferences.favoriteStreamingPlatforms,
                    userInteractions: userInteractions,
                    favoriteActors: userPreferences.favoriteActors,
                    favoriteGenres: userPreferences.favoriteGenres,
                    recentSuggestions: excludeMoviesFirestore + recommendations.map { MovieFirestore(from: $0) }
                )

                // Vérifier que le film n'est pas déjà dans les recommandations
                if !recommendations.contains(where: { $0.title == movie.title }) {
                    recommendations.append(movie)
                }

            } catch {
                print("Erreur lors de la génération d'une recommandation: \(error)")
                attempts += 1
            }
        }

        if recommendations.isEmpty {
            throw RecommendationError.generationFailed("Impossible de générer des recommandations")
        }

        return recommendations
    }
}

// MARK: - Recommendation Errors

enum RecommendationError: LocalizedError {
    case missingPreferences(String)
    case generationFailed(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case let .missingPreferences(message):
            return "Préférences manquantes: \(message)"
        case let .generationFailed(message):
            return "Échec de génération: \(message)"
        case let .networkError(message):
            return "Erreur réseau: \(message)"
        }
    }
}
