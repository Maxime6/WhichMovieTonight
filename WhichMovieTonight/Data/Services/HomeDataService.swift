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

            if let cachedRecommendations = try await recommendationCacheService.getTodaysRecommendations() {
                print("📋 Recommandations trouvées en cache: \(cachedRecommendations.movies.count) films")
                return cachedRecommendations.movies.map { $0.toMovie() }
            }

            print("📄 Aucune recommandation en cache, génération de nouvelles recommandations")
            return try await generateDailyRecommendations(userId: userId)
        } catch {
            print("❌ Erreur lors du chargement des recommandations: \(error)")
            // En cas d'erreur (ex: index Firestore manquant), générer de nouvelles recommandations
            return try await generateDailyRecommendations(userId: userId)
        }
    }

    func generateDailyRecommendations(userId: String) async throws -> [Movie] {
        print("🎬 Génération de nouvelles recommandations quotidiennes")

        do {
            let userPreferences = userPreferencesService.getUserPreferences()
            let movies = try await getDailyRecommendationsUseCase.execute(
                preferences: userPreferences,
                userId: userId
            )

            // Sauvegarder les nouvelles recommandations
            let dailyRecommendations = DailyRecommendations(
                userId: userId,
                date: Calendar.current.startOfDay(for: Date()),
                movies: movies.map { MovieFirestore(from: $0) }
            )

            try await recommendationCacheService.saveDailyRecommendations(dailyRecommendations)

            print("✅ \(movies.count) nouvelles recommandations générées et sauvegardées")
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
        let granted = await dailyNotificationService.requestPermission()
        if granted {
            dailyNotificationService.scheduleDailyRecommendationNotification()
            print("✅ Notifications configurées avec succès")
        } else {
            print("⚠️ Permission de notification refusée")
        }
    }
}
