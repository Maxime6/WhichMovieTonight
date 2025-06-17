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

    func execute(
        preferences: UserPreferences,
        userId: String
    ) async throws -> [Movie]
}

final class GetDailyRecommendationsUseCaseImpl: GetDailyRecommendationsUseCase {
    private let repository: MovieRepository

    init(repository: MovieRepository) {
        self.repository = repository
    }

    func execute(
        userPreferences: UserPreferencesService,
        userInteractions _: UserMovieInteractions?,
        excludeMovieIds _: [String]
    ) async throws -> [Movie] {
        let preferences = userPreferences.getUserPreferences()
        return try await execute(preferences: preferences, userId: "")
    }

    func execute(
        preferences: UserPreferences,
        userId _: String
    ) async throws -> [Movie] {
        // Validation des préférences utilisateur
        guard !preferences.favoriteGenres.isEmpty else {
            throw RecommendationError.missingPreferences("Aucun genre favori défini")
        }

        guard !preferences.favoriteStreamingPlatforms.isEmpty else {
            throw RecommendationError.missingPreferences("Aucune plateforme de streaming définie")
        }

        // Utiliser le repository existant mais adapter pour 5 films
        var recommendations: [Movie] = []
        let maxAttempts = 10 // Éviter les boucles infinies
        var attempts = 0

        while recommendations.count < 5 && attempts < maxAttempts {
            do {
                let movie = try await repository.findSuggestedMovie(
                    movieGenre: preferences.favoriteGenres,
                    streamingPlatforms: preferences.favoriteStreamingPlatforms,
                    userInteractions: nil,
                    favoriteActors: preferences.favoriteActors,
                    favoriteGenres: preferences.favoriteGenres,
                    recentSuggestions: recommendations.map { MovieFirestore(from: $0) }
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
