//
//  RecommendationCacheService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import FirebaseAuth
import Foundation

protocol RecommendationCacheServiceProtocol {
    func saveDailyRecommendations(_ recommendations: DailyRecommendations) async throws
    func getDailyRecommendations(for date: Date) async throws -> DailyRecommendations?
    func getTodaysRecommendations() async throws -> DailyRecommendations?
    func markMovieAsSeen(_ movie: Movie) async throws
    func getSeenMovies() async throws -> [SeenMovie]
    func getExcludedMovieIds() async throws -> [String]
    func shouldGenerateNewRecommendations() async throws -> Bool
}

final class RecommendationCacheService: RecommendationCacheServiceProtocol {
    private let firestoreService: FirestoreServiceProtocol
    private let cacheHistoryDays = 30

    init(firestoreService: FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    func saveDailyRecommendations(_ recommendations: DailyRecommendations) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CacheError.userNotAuthenticated
        }

        // Sauvegarder dans Firestore
        try await firestoreService.saveDailyRecommendations(recommendations, for: userId)
    }

    func getDailyRecommendations(for date: Date) async throws -> DailyRecommendations? {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CacheError.userNotAuthenticated
        }

        return try await firestoreService.getDailyRecommendations(for: date, userId: userId)
    }

    func getTodaysRecommendations() async throws -> DailyRecommendations? {
        // Utiliser le début de la journée pour une comparaison cohérente
        let today = Calendar.current.startOfDay(for: Date())
        return try await getDailyRecommendations(for: today)
    }

    func markMovieAsSeen(_ movie: Movie) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CacheError.userNotAuthenticated
        }

        let seenMovie = SeenMovie(
            movieId: movie.imdbID ?? movie.title, // Utiliser l'ID IMDB ou le titre comme fallback
            title: movie.title,
            posterURL: movie.posterURL?.absoluteString,
            userId: userId
        )

        try await firestoreService.markMovieAsSeen(seenMovie, for: userId)
    }

    func getSeenMovies() async throws -> [SeenMovie] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CacheError.userNotAuthenticated
        }

        return try await firestoreService.getSeenMovies(for: userId)
    }

    func getExcludedMovieIds() async throws -> [String] {
        guard Auth.auth().currentUser?.uid != nil else {
            throw CacheError.userNotAuthenticated
        }

        // Combiner les films vus et l'historique des recommandations récentes
        var seenMovieIds: [String] = []
        var recentRecommendations: [String] = []

        do {
            seenMovieIds = try await getSeenMovies().map { $0.movieId }
        } catch {
            print("⚠️ Impossible de récupérer les films vus (index manquant ?): \(error)")
            // Continuer sans les films vus pour l'instant
        }

        do {
            recentRecommendations = try await getRecentRecommendationIds()
        } catch {
            print("⚠️ Impossible de récupérer l'historique: \(error)")
            // Continuer sans l'historique pour l'instant
        }

        return seenMovieIds + recentRecommendations
    }

    func shouldGenerateNewRecommendations() async throws -> Bool {
        let todaysRecommendations = try await getTodaysRecommendations()
        return todaysRecommendations == nil
    }

    // MARK: - Private Methods

    private func getRecentRecommendationIds() async throws -> [String] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CacheError.userNotAuthenticated
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -cacheHistoryDays, to: Date()) ?? Date.distantPast

        return try await firestoreService.getRecentRecommendationIds(since: cutoffDate, for: userId)
    }
}

// MARK: - Cache Errors

enum CacheError: LocalizedError {
    case userNotAuthenticated
    case dataCorrupted
    case saveFailed(String)
    case loadFailed(String)

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Utilisateur non authentifié"
        case .dataCorrupted:
            return "Données corrompues dans le cache"
        case let .saveFailed(message):
            return "Échec de sauvegarde: \(message)"
        case let .loadFailed(message):
            return "Échec de chargement: \(message)"
        }
    }
}
