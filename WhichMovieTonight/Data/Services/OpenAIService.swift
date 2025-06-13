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
        recentSuggestions: [MovieFirestore] = []
    ) async throws -> OpenAIMovieDTO {
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

        let prompt = """
        You are an AI movie recommender. Suggest a creative, lesser-known movie I can watch tonight based on the user's comprehensive preferences.

        CURRENT SESSION REQUIREMENTS:
        - Must be available on: \(platforms.joined(separator: ", "))
        - Matching one or more of these genres: \(genresString)

        USER PREFERENCE PROFILE:
        \(userPreferencesContext)

        RECOMMENDATION STRATEGY:
        1. Prioritize movies that match the user's historical preferences (liked genres, favorite actors)
        2. Avoid recommending movies similar to those the user disliked
        3. Avoid recent suggestions to ensure variety
        4. Suggest lesser-known gems that align with their taste profile

        Respond ONLY with JSON in the following format:

        {
          "title": "...",
          "genres": ["...", "..."],
          "poster_url": "https://valid.image.url/of/poster.jpg",
          "platforms": ["..."],
          "recommendation_reason": "Brief explanation why this matches the user's preferences"
        }

        The "poster_url" must be a valid public link to an actual image of the movie poster.
        Use a reliable source like Wikipedia, IMDb, or an official image hosting site.
        Do not write placeholder values. Always include a real image URL.
        The "recommendation_reason" should reference specific user preferences that make this a good match.
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
            let suggestion = try JSONDecoder().decode(OpenAIMovieDTO.self, from: jsonData)
            return suggestion
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

    private func extractJSON(from content: String) -> String? {
        guard let start = content.firstIndex(of: "{"),
              let end = content.lastIndex(of: "}") else { return nil }
        return String(content[start ... end])
    }
}
