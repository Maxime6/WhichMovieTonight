//
//  UserDataServiceProtocol.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import Foundation

// MARK: - User Data Service Protocol

protocol UserDataServiceProtocol {
    func getUserMovieData(for userId: String) async throws -> UserMovieData?
    func saveSelectedMovie(_ movie: Movie, for userId: String) async throws
    func saveMovieSuggestion(_ movie: Movie, for userId: String) async throws
    func clearSelectedMovie(for userId: String) async throws
}

// MARK: - User Movie Interactions Service Protocol

protocol UserMovieInteractionsServiceProtocol {
    func saveMovieInteraction(_ interaction: UserMovieInteraction, for userId: String) async throws
    func getUserMovieInteractions(for userId: String) async throws -> UserMovieInteractions?
    func getMovieInteraction(movieId: String, for userId: String) async throws -> UserMovieInteraction?
    func toggleMovieLike(movie: Movie, for userId: String) async throws -> MovieLikeStatus
    func toggleMovieDislike(movie: Movie, for userId: String) async throws -> MovieLikeStatus
    func toggleMovieFavorite(movie: Movie, for userId: String) async throws -> Bool
}

// MARK: - Daily Recommendations Service Protocol

protocol DailyRecommendationsServiceProtocol {
    func saveDailyRecommendations(_ recommendations: DailyRecommendations, for userId: String) async throws
    func getDailyRecommendations(for date: Date, userId: String) async throws -> DailyRecommendations?
    func getRecentRecommendationIds(since date: Date, for userId: String) async throws -> [String]
}

// MARK: - Seen Movies Service Protocol

protocol SeenMoviesServiceProtocol {
    func markMovieAsSeen(_ seenMovie: SeenMovie, for userId: String) async throws
    func getSeenMovies(for userId: String) async throws -> [SeenMovie]
}
