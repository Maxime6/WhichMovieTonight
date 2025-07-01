//
//  OpenAIService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 05/05/2025.
//

import Foundation

final class OpenAIService {
    private var apiKey: String? {
        return Config.openAIAPIKey
    }

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func getMovieSuggestion(
        for platforms: [String],
        movieGenre: [MovieGenre],
        userInteractions: UserMovieInteractions?,
        favoriteActors: [String],
        favoriteGenres: [MovieGenre],
        recentSuggestions: [MovieFirestore] = [],
        alreadyGeneratedMovies: [Movie] = []
    ) async throws -> [OpenAIMovieDTO] {
        guard let apiKey = apiKey else {
            print("OPENAI_API_KEY environment variable not set")
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // Timeout de 30 secondes

        let genresString = movieGenre.map { $0.rawValue }.joined(separator: ", ")
        let favoriteGenresString = favoriteGenres.map { $0.rawValue }.joined(separator: ", ")
        let favoriteActorsString = favoriteActors.joined(separator: ", ")

        // Analyser les préférences de l'utilisateur
        let userPreferencesContext = buildUserPreferencesContext(
            userInteractions: userInteractions,
            favoriteActorsString: favoriteActorsString,
            favoriteGenresString: favoriteGenresString,
            recentSuggestions: recentSuggestions
        )

        // Build context for already generated movies in this session
        let sessionMoviesContext = buildSessionMoviesContext(alreadyGeneratedMovies)

        let prompt = """
        You are an AI movie recommender. Generate exactly 5 diverse, creative, lesser-known movies for the user's daily recommendations based on their comprehensive preferences.

        REQUIREMENTS FOR ALL 5 MOVIES:
        - Must be available on: \(platforms.joined(separator: ", "))
        - Each movie should match one or more of these genres: \(genresString)
        - Ensure diversity between the 5 movies (different themes, eras, directors when possible)

        USER PREFERENCE PROFILE:
        \(userPreferencesContext)

        SESSION DIVERSITY REQUIREMENTS:
        \(sessionMoviesContext)

        RECOMMENDATION STRATEGY:
        1. Prioritize movies that match the user's historical preferences (liked genres, favorite actors)
        2. Avoid recommending movies similar to those the user disliked
        3. Avoid recent suggestions to ensure variety
        4. CRITICAL: Ensure diversity from already suggested movies in this session
        5. Suggest lesser-known gems that align with their taste profile
        6. Generate exactly 5 different movies with good variety between them

        Respond ONLY with a JSON array of exactly 5 movies in the following format:

        [
          {
            "title": "...",
            "genres": ["...", "..."],
            "poster_url": "https://valid.image.url/of/poster.jpg",
            "platforms": ["..."],
            "recommendation_reason": "Brief explanation why this matches the user's preferences"
          },
          {
            "title": "...",
            "genres": ["...", "..."],
            "poster_url": "https://valid.image.url/of/poster.jpg",
            "platforms": ["..."],
            "recommendation_reason": "Brief explanation why this matches the user's preferences"
          },
          {
            "title": "...",
            "genres": ["...", "..."],
            "poster_url": "https://valid.image.url/of/poster.jpg",
            "platforms": ["..."],
            "recommendation_reason": "Brief explanation why this matches the user's preferences"
          },
          {
            "title": "...",
            "genres": ["...", "..."],
            "poster_url": "https://valid.image.url/of/poster.jpg",
            "platforms": ["..."],
            "recommendation_reason": "Brief explanation why this matches the user's preferences"
          },
          {
            "title": "...",
            "genres": ["...", "..."],
            "poster_url": "https://valid.image.url/of/poster.jpg",
            "platforms": ["..."],
            "recommendation_reason": "Brief explanation why this matches the user's preferences"
          }
        ]

        Each "poster_url" must be a valid public link to an actual image of the movie poster.
        Use reliable sources like Wikipedia, IMDb, or official image hosting sites.
        Do not write placeholder values. Always include real image URLs.
        Each "recommendation_reason" should reference specific user preferences that make this a good match.
        CRITICAL: Return exactly 5 movies, no more, no less.
        """

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "user", "content": prompt],
            ],
            "temperature": 0.8, // Réduire la température pour des recommandations plus consistantes
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        let content = decoded.choices.first?.message.content ?? ""
        print("OpenAI content:\n\(content)")

        // Vérifier si la réponse contient une erreur ou un refus
        if content.lowercased().contains("i'm unable") ||
            content.lowercased().contains("i can't") ||
            content.lowercased().contains("i'm sorry")
        {
            throw URLError(.badServerResponse)
        }

        guard let jsonText = extractJSON(from: content),
              let jsonData = jsonText.data(using: .utf8)
        else {
            print("Failed to extract JSON from OpenAI response")
            throw URLError(.badServerResponse)
        }

        do {
            let suggestions = try JSONDecoder().decode([OpenAIMovieDTO].self, from: jsonData)
            print("✅ OpenAI generated \(suggestions.count) movies")
            return suggestions
        } catch {
            print("Failed to decode OpenAI response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }

    private func buildUserPreferencesContext(
        userInteractions: UserMovieInteractions?,
        favoriteActorsString: String,
        favoriteGenresString: String,
        recentSuggestions: [MovieFirestore]
    ) -> String {
        var context = ""

        // Genres favoris de l'utilisateur
        if !favoriteGenresString.isEmpty {
            context += "- Favorite genres: \(favoriteGenresString)\n"
        }

        // Acteurs favoris
        if !favoriteActorsString.isEmpty {
            context += "- Favorite actors: \(favoriteActorsString)\n"
        }

        // Analyse des interactions utilisateur
        if let interactions = userInteractions {
            // Films likés
            let likedMovies = interactions.likedMovies.prefix(5) // Les 5 derniers films likés
            if !likedMovies.isEmpty {
                context += "- Recently liked movies: \(likedMovies.map { $0.movieTitle }.joined(separator: ", "))\n"
            }

            // Films en favoris
            let favoriteMovies = interactions.favoriteMovies.prefix(3) // Les 3 favoris les plus récents
            if !favoriteMovies.isEmpty {
                context += "- Favorite movies: \(favoriteMovies.map { $0.movieTitle }.joined(separator: ", "))\n"
            }

            // Films dislikés (à éviter)
            let dislikedMovies = interactions.dislikedMovies.prefix(3)
            if !dislikedMovies.isEmpty {
                context += "- Avoid movies similar to these disliked films: \(dislikedMovies.map { $0.movieTitle }.joined(separator: ", "))\n"
            }
        }

        // Suggestions récentes à éviter
        if !recentSuggestions.isEmpty {
            let recentTitles = recentSuggestions.prefix(5).map { $0.title }
            context += "- Avoid these recently suggested movies: \(recentTitles.joined(separator: ", "))\n"
        }

        return context.isEmpty ? "No specific user preferences available yet." : context
    }

    private func buildSessionMoviesContext(_ movies: [Movie]) -> String {
        if movies.isEmpty {
            return "- This is the first recommendation in the session."
        }

        var context = "- AVOID movies similar to these already suggested in this session:\n"
        for (index, movie) in movies.enumerated() {
            let actors = movie.actors?.components(separatedBy: ", ").prefix(2).joined(separator: ", ") ?? "Unknown actors"
            let genres = movie.genres.prefix(2).joined(separator: ", ")
            context += "  \(index + 1). \(movie.title) (Genres: \(genres), Actors: \(actors))\n"
        }
        context += "- Ensure significant diversity in cast, director, and themes from above movies."

        return context
    }

    private func extractJSON(from content: String) -> String? {
        // Try to extract JSON array first (starts with [)
        if let arrayStart = content.firstIndex(of: "["),
           let arrayEnd = content.lastIndex(of: "]")
        {
            return String(content[arrayStart ... arrayEnd])
        }

        // Fallback to object extraction (starts with {) for compatibility
        if let objectStart = content.firstIndex(of: "{"),
           let objectEnd = content.lastIndex(of: "}")
        {
            return String(content[objectStart ... objectEnd])
        }

        return nil
    }
}
