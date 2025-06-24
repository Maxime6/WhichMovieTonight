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
    @Injected private var recommendationCacheService: RecommendationCacheServiceProtocol

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

        print("🎬 Génération de 5 nouvelles recommandations...")
        print("📋 Genres préférés: \(preferences.favoriteGenres.map { $0.rawValue })")
        print("📺 Plateformes: \(preferences.favoriteStreamingPlatforms.map { $0.rawValue })")

        // Récupérer les films à exclure (vus + derniers 7 jours)
        var excludedMovieIds: [String] = []
        do {
            excludedMovieIds = try await recommendationCacheService.getExcludedMovieIds()
            print("🚫 Films à exclure: \(excludedMovieIds.count)")
        } catch {
            print("⚠️ Impossible de récupérer les films à exclure: \(error)")
            // Continuer sans exclusions pour éviter de bloquer l'utilisateur
        }

        // Générer les recommandations en évitant les doublons
        var recommendations: [Movie] = []
        var excludedTitles = Set(excludedMovieIds)
        let maxAttempts = 15 // Augmenté pour compenser les exclusions
        var attempts = 0

        while recommendations.count < 5 && attempts < maxAttempts {
            do {
                print("🔄 Tentative \(attempts + 1)/\(maxAttempts) - Films trouvés: \(recommendations.count)/5")

                let movie = try await repository.findSuggestedMovie(
                    movieGenre: preferences.favoriteGenres,
                    streamingPlatforms: preferences.favoriteStreamingPlatforms,
                    userInteractions: nil,
                    favoriteActors: preferences.favoriteActors,
                    favoriteGenres: preferences.favoriteGenres,
                    recentSuggestions: recommendations.map { MovieFirestore(from: $0) }
                )

                // Vérifier que le film n'est pas dans les exclusions (vu ou récent)
                let movieId = movie.imdbID ?? movie.title
                let movieTitle = movie.title

                if !excludedTitles.contains(movieId) && !excludedTitles.contains(movieTitle) {
                    // Vérifier qu'il n'est pas déjà dans les recommandations actuelles
                    if !recommendations.contains(where: { $0.title == movie.title }) {
                        recommendations.append(movie)
                        excludedTitles.insert(movieId)
                        excludedTitles.insert(movieTitle)
                        print("✅ Film ajouté: \(movie.title) (\(movie.year ?? "N/A"))")
                    } else {
                        print("⚠️ Film déjà dans les recommandations: \(movie.title)")
                    }
                } else {
                    print("⚠️ Film exclu (déjà vu ou récent): \(movie.title)")
                }

            } catch {
                print("❌ Erreur lors de la génération d'une recommandation: \(error)")
            }

            attempts += 1
        }

        if recommendations.isEmpty {
            print("❌ Aucune recommandation générée après \(attempts) tentatives")
            throw RecommendationError.generationFailed("Impossible de générer des recommandations")
        }

        print("✅ \(recommendations.count) recommandations générées avec succès après \(attempts) tentatives")

        // Log des films recommandés
        for (index, movie) in recommendations.enumerated() {
            print("📽️ \(index + 1). \(movie.title) (\(movie.year ?? "N/A")) - \(movie.genres.joined(separator: ", "))")
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
