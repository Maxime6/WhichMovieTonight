//
//  RecommendationService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseAuth
import Foundation

// MARK: - Recommendation Service Protocol

protocol RecommendationServiceProtocol {
    func loadCurrentRecommendations(for userId: String) async throws -> [Movie]
    func generateNewRecommendations(for userId: String) async throws -> [Movie]
}

// MARK: - Recommendation Service Implementation

final class RecommendationService: RecommendationServiceProtocol {
    // MARK: - Dependencies

    private let openAIService: OpenAIService
    private let omdbService: OMDBService
    private let userMovieService: UserMovieServiceProtocol
    private let userProfileService: UserProfileService

    // MARK: - Initialization

    init(
        openAIService: OpenAIService = OpenAIService(),
        omdbService: OMDBService = OMDBService(),
        userMovieService: UserMovieServiceProtocol = UserMovieService(),
        userProfileService: UserProfileService
    ) {
        self.openAIService = openAIService
        self.omdbService = omdbService
        self.userMovieService = userMovieService
        self.userProfileService = userProfileService
    }

    // MARK: - Public Methods

    /// Load current recommendations from UserMovieService
    func loadCurrentRecommendations(for userId: String) async throws -> [Movie] {
        print("📱 Loading current recommendations for user: \(userId)")

        let currentPicks = try await userMovieService.getCurrentPicks(userId: userId)
        let movies = currentPicks.map { $0.movie }

        print("📱 Loaded \(movies.count) current recommendations")
        return movies
    }

    /// Generate new recommendations with retry logic
    func generateNewRecommendations(for userId: String) async throws -> [Movie] {
        print("🎬 Generating new recommendations for user: \(userId)")

        // 1. Load user preferences from Firebase
        await userProfileService.loadUserPreferences(userId: userId)
        let userPreferences = await MainActor.run { userProfileService.getUserPreferences() }
        guard userPreferences.isValid else {
            throw RecommendationError.missingUserPreferences
        }

        // 2. Get user interactions for AI context (converted from UserMovies)
        let userInteractions = try await getUserInteractionsForAI(userId: userId)

        // 3. Get exclusion list from history and disliked movies
        let exclusionList = try await getExclusionList(for: userId)

        // 4. Generate 5 movies with retry logic
        var generatedMovies: [Movie] = []
        var attempts = 0
        let maxRetries = 3
        var lastError: Error?

        while generatedMovies.count < 5 && attempts < maxRetries {
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
                lastError = error
                print("⚠️ Failed to generate movie (attempt \(attempts)): \(error)")

                if attempts == 2 {
                    // Show progress message after 2nd attempt
                    print("🔄 Generation taking longer than expected...")
                }

                // Wait before retry
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }

        guard !generatedMovies.isEmpty else {
            if let lastError = lastError {
                throw RecommendationError.generationFailedAfterRetries(lastError)
            } else {
                throw RecommendationError.noMoviesGenerated
            }
        }

        // 5. Save new generation using UserMovieService
        try await saveNewGeneration(generatedMovies, for: userId)

        print("🎉 Successfully generated \(generatedMovies.count) new recommendations")
        return generatedMovies
    }

    // MARK: - Private Methods

    /// Get user interactions converted to legacy format for OpenAI service
    private func getUserInteractionsForAI(userId: String) async throws -> UserMovieInteractions? {
        let userMovies = try await userMovieService.getUserMovies(userId: userId, filter: nil)

        // Convert UserMovies to legacy UserMovieInteractions format
        var interactions: [String: UserMovieInteraction] = [:]

        for userMovie in userMovies {
            if userMovie.isLiked || userMovie.isDisliked || userMovie.isFavorite {
                let interaction = UserMovieInteraction(
                    movieId: userMovie.movieId,
                    movieTitle: userMovie.movie.title,
                    posterURL: userMovie.movie.posterURL?.absoluteString,
                    likeStatus: userMovie.isLiked ? .liked : userMovie.isDisliked ? .disliked : .none,
                    isFavorite: userMovie.isFavorite
                )
                interactions[userMovie.movieId] = interaction
            }
        }

        if interactions.isEmpty {
            return nil
        }

        var userInteractions = UserMovieInteractions(userId: userId)
        userInteractions.interactions = interactions

        print("📊 Converted \(interactions.count) UserMovies to AI context")
        return userInteractions
    }

    /// Get exclusion list from history and disliked movies
    private func getExclusionList(for userId: String) async throws -> [MovieFirestore] {
        let userMovies = try await userMovieService.getUserMovies(userId: userId, filter: nil)

        // Exclude movies from history and disliked movies
        let excludedMovies = userMovies.filter {
            $0.isInHistory || $0.isCurrentPick || $0.isDisliked
        }

        // Convert to legacy MovieFirestore format for OpenAI service
        let exclusionList = excludedMovies.map { MovieFirestore(from: $0.movie) }

        print("📝 Excluding \(exclusionList.count) movies from generation (history + disliked)")
        return exclusionList
    }

    /// Save new generation using UserMovieService
    private func saveNewGeneration(_ movies: [Movie], for userId: String) async throws {
        // First cleanup old history to maintain 50 movie limit
        try await userMovieService.cleanupOldHistory(userId: userId, keepCount: 50)

        // Set new current picks (this will automatically clear old picks and mark as history)
        try await userMovieService.setCurrentPicks(userId: userId, movies: movies)

        print("💾 Saved \(movies.count) new current picks and updated history")
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
    case generationFailedAfterRetries(Error)

    var errorDescription: String? {
        switch self {
        case .missingUserPreferences:
            return "User preferences not found. Please complete onboarding."
        case .noMoviesGenerated:
            return "Unable to generate movie recommendations. Please try again."
        case let .generationFailedAfterRetries(underlyingError):
            return "Failed to generate recommendations after multiple attempts: \(underlyingError.localizedDescription)"
        }
    }
}
