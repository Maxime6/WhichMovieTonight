//
//  HomeDataService.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import Foundation

// MARK: - Home Data Service Protocol

protocol HomeDataServiceProtocol {
    func loadUserDisplayName(userId: String) async -> String
    func loadTodaysRecommendations(userId: String) async throws -> [Movie]
    func generateDailyRecommendations(userId: String) async throws -> [Movie]
    func refreshRecommendations(userId: String) async throws -> [Movie]
    func setupNotifications() async throws
}

// MARK: - Home Data Service Implementation

final class HomeDataService: HomeDataServiceProtocol {
    // MARK: - Dependencies (injected)

    @Injected private var userDataService: UserDataServiceProtocol
    @Injected private var recommendationCacheService: RecommendationCacheServiceProtocol
    @Injected private var userPreferencesService: UserPreferencesService
    @Injected private var dailyNotificationService: DailyNotificationServiceProtocol
    @Injected private var getDailyRecommendationsUseCase: GetDailyRecommendationsUseCase

    // MARK: - Public Methods

    func loadUserDisplayName(userId: String) async -> String {
        guard let userData = try? await userDataService.getUserMovieData(for: userId),
              let firstName = userData.selectedMovie?.title.split(separator: " ").first
        else {
            return "Cinéphile"
        }
        return String(firstName)
    }

    func loadTodaysRecommendations(userId: String) async throws -> [Movie] {
        do {
            print("🔄 Chargement des recommandations pour \(userId)")

            // Vérifier d'abord si des recommandations existent en cache
            if let cachedRecommendations = try await recommendationCacheService.getTodaysRecommendations() {
                print("✅ Recommandations trouvées en cache: \(cachedRecommendations.movies.count) films")
                let movies = cachedRecommendations.movies.map { $0.toMovie() }

                // Log des films trouvés
                for (index, movie) in movies.enumerated() {
                    print("📽️ \(index + 1). \(movie.title) (\(movie.year ?? "N/A"))")
                }

                return movies
            }

            print("📄 Aucune recommandation en cache pour aujourd'hui")

            // Vérifier si nous devons générer automatiquement ou attendre
            let shouldGenerate = try await recommendationCacheService.shouldGenerateNewRecommendations()

            if shouldGenerate {
                print("🎬 Génération immédiate de nouvelles recommandations")
                return try await generateDailyRecommendations(userId: userId)
            } else {
                print("⏳ En attente des recommandations programmées")
                // Retourner une liste vide - les recommandations seront générées à 6h
                return []
            }

        } catch {
            print("❌ Erreur lors du chargement des recommandations: \(error)")
            // En cas d'erreur, essayer de générer de nouvelles recommandations
            print("🔄 Tentative de génération de nouvelles recommandations en fallback")
            return try await generateDailyRecommendations(userId: userId)
        }
    }

    func generateDailyRecommendations(userId: String) async throws -> [Movie] {
        print("🎬 Génération de nouvelles recommandations quotidiennes pour \(userId)")

        do {
            let userPreferences = userPreferencesService.getUserPreferences()

            // Vérifier que les préférences sont valides
            guard userPreferences.isValid else {
                throw RecommendationError.missingPreferences("Préférences utilisateur incomplètes")
            }

            let movies = try await getDailyRecommendationsUseCase.execute(
                preferences: userPreferences,
                userId: userId
            )

            // Sauvegarder les nouvelles recommandations avec la date d'aujourd'hui
            let dailyRecommendations = DailyRecommendations(
                userId: userId,
                date: Calendar.current.startOfDay(for: Date()),
                movies: movies.map { MovieFirestore(from: $0) }
            )

            try await recommendationCacheService.saveDailyRecommendations(dailyRecommendations)

            print("✅ \(movies.count) nouvelles recommandations générées et sauvegardées")

            // Poster une notification pour informer que les recommandations sont prêtes
            NotificationCenter.default.post(name: .recommendationsGenerated, object: movies)

            return movies
        } catch {
            print("❌ Erreur lors de la génération des recommandations: \(error)")
            throw error
        }
    }

    func refreshRecommendations(userId: String) async throws -> [Movie] {
        print("🔄 Actualisation forcée des recommandations")
        return try await generateDailyRecommendations(userId: userId)
    }

    func setupNotifications() async throws {
        print("📱 Configuration des notifications quotidiennes")

        let granted = await dailyNotificationService.requestPermission()
        if granted {
            // Supprimer l'ancienne notification de génération à 6h
            dailyNotificationService.cancelGenerationNotifications()

            // Programmer seulement la notification à 8h (quand les films sont prêts)
            dailyNotificationService.scheduleDailyRecommendationNotification()

            print("✅ Notifications configurées avec succès:")
            print("   - Notification: 8h00 (les films sont prêts)")
        } else {
            print("⚠️ Permission de notification refusée")
            throw NotificationError.permissionDenied
        }
    }
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission de notification refusée"
        }
    }
}
