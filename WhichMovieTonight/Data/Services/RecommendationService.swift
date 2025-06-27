//
//  RecommendationService.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on [Current Date]
//

import FirebaseAuth
import Foundation

// MARK: - Simple Recommendation Service Protocol

protocol RecommendationServiceProtocol {
    func loadCurrentRecommendations(for userId: String) async throws -> [Movie]
    func generateNewRecommendations(for userId: String) async throws -> [Movie]
}

// MARK: - Simple Recommendation Service Implementation

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

    /// Load current recommendations from UserMovieData
    func loadCurrentRecommendations(for userId: String) async throws -> [Movie] {
        print("📱 Loading current recommendations for user: \(userId)")

        if let userData = try await firestoreService.getUserMovieData(for: userId) {
            let movies = userData.currentPicks.map { $0.toMovie() }
            print("📱 Loaded \(movies.count) current recommendations from cache")
            return movies
        } else {
            print("📱 No cached recommendations found")
            return []
        }
    }

    /// Generate new recommendations (same for both initial and refresh)
    func generateNewRecommendations(for userId: String) async throws -> [Movie] {
        print("🎬 Generating new recommendations for user: \(userId)")

        // 1. Get user preferences
        let userPreferences = userPreferencesService.getUserPreferences()
        guard userPreferences.isValid else {
            throw RecommendationError.missingUserPreferences
        }

        // 2. Get user interactions for AI context
        let userInteractions = try await firestoreService.getUserMovieInteractions(for: userId)

        // 3. Get exclusion list from generation history
        let exclusionList = try await getExclusionList(for: userId)

        // 4. Generate 5 movies using main AI prompt
        var generatedMovies: [Movie] = []
        var attempts = 0
        let maxAttempts = 10

        while generatedMovies.count < 5 && attempts < maxAttempts {
            attempts += 1

            do {
                let movieDTO = try await openAIService.getMovieSuggestion(
                    for: userPreferences.favoriteStreamingPlatforms.map { $0.rawValue },
                    movieGenre: userPreferences.favoriteGenres,
                    userInteractions: userInteractions,
                    favoriteActors: userPreferences.favoriteActors,
                    favoriteGenres: userPreferences.favoriteGenres,
                    recentSuggestions: exclusionList
                )

                let movie = try await enrichMovieWithOMDB(movieDTO)

                // Simple duplicate check by title
                if !generatedMovies.contains(where: { $0.title.lowercased() == movie.title.lowercased() }) {
                    generatedMovies.append(movie)
                    print("✅ Generated movie \(generatedMovies.count)/5: \(movie.title)")
                }

            } catch {
                print("⚠️ Failed to generate movie (attempt \(attempts)): \(error)")
            }
        }

        guard !generatedMovies.isEmpty else {
            throw RecommendationError.noMoviesGenerated
        }

        // 5. Save to UserMovieData with history
        try await saveNewGeneration(generatedMovies, for: userId)

        print("🎉 Successfully generated \(generatedMovies.count) new recommendations")
        return generatedMovies
    }

    // MARK: - Private Methods

    /// Get exclusion list from generation history
    private func getExclusionList(for userId: String) async throws -> [MovieFirestore] {
        if let userData = try await firestoreService.getUserMovieData(for: userId) {
            print("📝 Excluding \(userData.generationHistory.count) movies from generation history")
            return userData.generationHistory
        } else {
            print("📝 No generation history found")
            return []
        }
    }

    /// Save new generation and update history
    private func saveNewGeneration(_ movies: [Movie], for userId: String) async throws {
        let movieFirestore = movies.map { MovieFirestore(from: $0) }

        if let existingUserData = try await firestoreService.getUserMovieData(for: userId) {
            // Update existing data with new generation
            let updatedData = existingUserData.withNewGeneration(movieFirestore)
            try await firestoreService.updateUserMovieData(updatedData, for: userId)
        } else {
            // Create new UserMovieData
            let newUserData = UserMovieData(userId: userId, currentPicks: movieFirestore)
                .withNewGeneration(movieFirestore)
            try await firestoreService.saveUserMovieData(newUserData, for: userId)
        }

        print("💾 Saved new generation to UserMovieData")
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
}

// MARK: - Recommendation Errors

enum RecommendationError: LocalizedError {
    case missingUserPreferences
    case noMoviesGenerated

    var errorDescription: String? {
        switch self {
        case .missingUserPreferences:
            return "User preferences not found. Please complete onboarding."
        case .noMoviesGenerated:
            return "Unable to generate movie recommendations. Please try again."
        }
    }
}
