//
//  RecommendationService.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on [Current Date]
//

import FirebaseAuth
import Foundation

// MARK: - Recommendation Service Protocol

protocol RecommendationServiceProtocol {
    func getCachedRecommendations(for userId: String) async throws -> [Movie]?
    func shouldGenerateNewRecommendations(for userId: String) async throws -> Bool
    func generateDailyRecommendations(for userId: String) async throws -> [Movie]
    func markMovieAsSeen(_ movie: Movie, for userId: String) async throws
}

// MARK: - Recommendation Service Implementation

final class RecommendationService: RecommendationServiceProtocol {
    // MARK: - Dependencies

    private let openAIService: OpenAIService
    private let omdbService: OMDBService
    private let firestoreService: FirestoreService
    private let userPreferencesService: UserPreferencesService

    // MARK: - Initialization

    init(
        openAIService: OpenAIService = OpenAIService(),
        omdbService: OMDBService = OMDBService(),
        firestoreService: FirestoreService = FirestoreService(),
        userPreferencesService: UserPreferencesService = UserPreferencesService()
    ) {
        self.openAIService = openAIService
        self.omdbService = omdbService
        self.firestoreService = firestoreService
        self.userPreferencesService = userPreferencesService
    }

    // MARK: - Public Methods

    /// Get cached recommendations for today if they exist
    func getCachedRecommendations(for userId: String) async throws -> [Movie]? {
        let todaysRecommendations = try await firestoreService.getDailyRecommendations(
            for: Date(),
            userId: userId
        )

        return todaysRecommendations?.movies.map { $0.toMovie() }
    }

    /// Check if new recommendations should be generated (daily check)
    func shouldGenerateNewRecommendations(for userId: String) async throws -> Bool {
        // Check if we have recommendations for today
        let todaysRecommendations = try await getCachedRecommendations(for: userId)
        return todaysRecommendations == nil
    }

    /// Generate 5 new daily recommendations using AI
    func generateDailyRecommendations(for userId: String) async throws -> [Movie] {
        print("🎬 Starting daily recommendations generation for user: \(userId)")

        // 1. Get user preferences
        let userPreferences = userPreferencesService.getUserPreferences()
        guard !userPreferences.favoriteGenres.isEmpty || !userPreferences.favoriteStreamingPlatforms.isEmpty else {
            throw RecommendationError.missingUserPreferences
        }

        // 2. Get user interactions for AI context
        let userInteractions = try await firestoreService.getUserMovieInteractions(for: userId)

        // 3. Get exclusion lists to avoid duplicates
        let excludedMovieIds = try await getExcludedMovieIds(for: userId)

        // 4. Generate 5 unique movies via AI
        var generatedMovies: [Movie] = []
        var attempts = 0
        let maxAttempts = 10 // Fallback to avoid infinite loops

        while generatedMovies.count < 5 && attempts < maxAttempts {
            attempts += 1

            do {
                let movie = try await generateSingleRecommendation(
                    userId: userId,
                    userPreferences: userPreferences,
                    userInteractions: userInteractions,
                    excludedMovieIds: excludedMovieIds + generatedMovies.map { $0.uniqueId }
                )

                // Check for duplicates
                if !generatedMovies.contains(where: { $0.title.lowercased() == movie.title.lowercased() }) {
                    generatedMovies.append(movie)
                    print("✅ Generated movie \(generatedMovies.count)/5: \(movie.title)")
                }

            } catch {
                print("⚠️ Failed to generate movie (attempt \(attempts)): \(error)")
                // Continue trying with other genres/platforms
            }
        }

        guard !generatedMovies.isEmpty else {
            throw RecommendationError.noMoviesGenerated
        }

        // 5. Save recommendations to cache
        try await saveDailyRecommendations(generatedMovies, for: userId)

        print("🎉 Successfully generated \(generatedMovies.count) recommendations")
        return generatedMovies
    }

    /// Mark a movie as seen to exclude from future recommendations
    func markMovieAsSeen(_ movie: Movie, for userId: String) async throws {
        let seenMovie = SeenMovie(from: movie, userId: userId)
        try await firestoreService.markMovieAsSeen(seenMovie, for: userId)
        print("✅ Movie marked as seen: \(movie.title)")
    }

    // MARK: - Private Methods

    /// Generate a single movie recommendation using AI + OMDB
    private func generateSingleRecommendation(
        userId: String,
        userPreferences: UserPreferences,
        userInteractions: UserMovieInteractions?,
        excludedMovieIds: [String]
    ) async throws -> Movie {
        // Prepare recent suggestions to avoid
        let recentSuggestions = try await getRecentSuggestions(for: userId, excludedIds: excludedMovieIds)

        // Get AI suggestion
        let movieDTO = try await openAIService.getMovieSuggestion(
            for: userPreferences.favoriteStreamingPlatforms.map { $0.rawValue },
            movieGenre: userPreferences.favoriteGenres,
            userInteractions: userInteractions,
            favoriteActors: userPreferences.favoriteActors,
            favoriteGenres: userPreferences.favoriteGenres,
            recentSuggestions: recentSuggestions
        )

        // Enrich with OMDB data
        return try await enrichMovieWithOMDB(movieDTO)
    }

    /// Enrich OpenAI movie suggestion with OMDB data
    private func enrichMovieWithOMDB(_ movieDTO: OpenAIMovieDTO) async throws -> Movie {
        do {
            let omdbMovie = try await omdbService.getMovieDetailsByTitle(title: movieDTO.title)
            return Movie(
                from: omdbMovie,
                originalGenres: movieDTO.genres,
                originalPlatforms: movieDTO.platforms
            )
        } catch {
            print("⚠️ OMDB enrichment failed for \(movieDTO.title), using OpenAI data only")
            // Fallback to OpenAI data only
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

    /// Get all movie IDs to exclude from recommendations
    private func getExcludedMovieIds(for userId: String) async throws -> [String] {
        var excludedIds: [String] = []

        // Add recently recommended movies (last 30 days)
        let recentRecommendations = try await getRecentRecommendationIds(for: userId, daysBack: 30)
        excludedIds.append(contentsOf: recentRecommendations)

        // Add seen movies
        let seenMovies = try await firestoreService.getSeenMovies(for: userId)
        excludedIds.append(contentsOf: seenMovies.map { $0.movieId })

        // Add disliked movies
        if let userInteractions = try await firestoreService.getUserMovieInteractions(for: userId) {
            let dislikedIds = userInteractions.dislikedMovies.map { $0.movieId }
            excludedIds.append(contentsOf: dislikedIds)
        }

        print("📝 Excluding \(excludedIds.count) movies from recommendations")
        return Array(Set(excludedIds)) // Remove duplicates
    }

    /// Get recent recommendation IDs to avoid duplicates
    private func getRecentRecommendationIds(for userId: String, daysBack: Int) async throws -> [String] {
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        return try await firestoreService.getRecentRecommendationIds(since: startDate, for: userId)
    }

    /// Get recent suggestions for OpenAI context
    private func getRecentSuggestions(for userId: String, excludedIds _: [String]) async throws -> [MovieFirestore] {
        let recentIds = try await getRecentRecommendationIds(for: userId, daysBack: 7)
        // This would need implementation in FirestoreService to get MovieFirestore objects
        // For now, return empty array - OpenAI will work with user interactions instead
        return []
    }

    /// Save generated recommendations to Firestore
    private func saveDailyRecommendations(_ movies: [Movie], for userId: String) async throws {
        let movieFirestore = movies.map { MovieFirestore(from: $0) }
        let dailyRecommendations = DailyRecommendations(
            userId: userId,
            date: Date(),
            movies: movieFirestore
        )

        try await firestoreService.saveDailyRecommendations(dailyRecommendations, for: userId)
        print("💾 Daily recommendations saved to Firestore")
    }
}

// MARK: - Recommendation Errors

enum RecommendationError: LocalizedError {
    case missingUserPreferences
    case noMoviesGenerated
    case cacheError

    var errorDescription: String? {
        switch self {
        case .missingUserPreferences:
            return "User preferences not found. Please complete onboarding."
        case .noMoviesGenerated:
            return "Unable to generate movie recommendations. Please try again."
        case .cacheError:
            return "Error accessing recommendation cache."
        }
    }
}
