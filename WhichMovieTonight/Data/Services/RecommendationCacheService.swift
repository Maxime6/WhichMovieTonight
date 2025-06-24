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
    private let cacheHistoryDays = 7 // Reduced from 30 to 7 days for better variety

    init(firestoreService: FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    func saveDailyRecommendations(_ recommendations: DailyRecommendations) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CacheError.userNotAuthenticated
        }

        // Sauvegarder dans Firestore
        try await firestoreService.saveDailyRecommendations(recommendations, for: userId)

        // Log pour debugging
        print("✅ Recommandations sauvegardées: \(recommendations.movies.count) films pour le \(formatDate(recommendations.date))")
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
        print("✅ Film marqué comme vu: \(movie.title)")
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

        // Combiner les films vus et l'historique des recommandations récentes (7 jours)
        var seenMovieIds: [String] = []
        var recentRecommendations: [String] = []

        do {
            seenMovieIds = try await getSeenMovies().map { $0.movieId }
            print("📋 Films déjà vus exclus: \(seenMovieIds.count)")
        } catch {
            print("⚠️ Impossible de récupérer les films vus (index manquant ?): \(error)")
            // Continuer sans les films vus pour l'instant
        }

        do {
            recentRecommendations = try await getRecentRecommendationIds()
            print("📋 Films des 7 derniers jours exclus: \(recentRecommendations.count)")
        } catch {
            print("⚠️ Impossible de récupérer l'historique récent: \(error)")
            // Continuer sans l'historique pour l'instant
        }

        let allExcluded = seenMovieIds + recentRecommendations
        let uniqueExcluded = Array(Set(allExcluded)) // Remove duplicates

        print("🚫 Total films exclus: \(uniqueExcluded.count) (vus: \(seenMovieIds.count), récents: \(recentRecommendations.count))")

        return uniqueExcluded
    }

    func shouldGenerateNewRecommendations() async throws -> Bool {
        let todaysRecommendations = try await getTodaysRecommendations()
        let shouldGenerate = todaysRecommendations == nil

        if shouldGenerate {
            print("🔄 Pas de recommandations pour aujourd'hui, génération nécessaire")
        } else {
            print("✅ Recommandations déjà disponibles pour aujourd'hui")
        }

        return shouldGenerate
    }

    // MARK: - Private Methods

    private func getRecentRecommendationIds() async throws -> [String] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CacheError.userNotAuthenticated
        }

        // Get movies from last 7 days instead of 30
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -cacheHistoryDays, to: Date()) ?? Date.distantPast

        let recentIds = try await firestoreService.getRecentRecommendationIds(since: cutoffDate, for: userId)

        print("📅 Récupération des recommandations depuis le \(formatDate(cutoffDate)): \(recentIds.count) films")

        return recentIds
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
