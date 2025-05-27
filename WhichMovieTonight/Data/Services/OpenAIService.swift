//
//  OpenAIService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 05/05/2025.
//

import Foundation

final class OpenAIService {
    private var apiKey: String {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fatalError("OPENAI_API_KEY environment variable not set")
        }
        return apiKey
    }

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func getMovieSuggestion(for platforms: [String], movieGenre: [MovieGenre], mood: String?) async throws -> OpenAIMovieDTO {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let genresString = movieGenre.map { $0.rawValue }.joined(separator: ", ")

        let prompt = """
        You are an AI movie recommender. Suggest a creative, lesser-known movie I can watch tonight.

        It must be available on: \(platforms.joined(separator: ", ")).
        Matching one or more of these genres: \(genresString)
        Mood of the user: \(mood ?? "neutral").
        Respond ONLY with JSON in the following format:

        {
          "title": "...",
          "genres": ["...", "..."],
          "poster_url": "https://valid.image.url/of/poster.jpg",
          "platforms": ["..."]
        }

        The "poster_url" must be a valid public link to an actual image of the movie poster.
        Use a reliable source like Wikipedia, IMDb, or an official image hosting site.
        Do not write placeholder values. Always include a real image URL.
        """

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "user", "content": prompt],
            ],
            "temperature": 1.0,
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
            return OpenAIMovieDTO(title: suggestion.title, genres: suggestion.genres, posterUrl: suggestion.posterUrl, platforms: suggestion.platforms)
        } catch {
            print("Failed to decode OpenAI response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }

    private func extractJSON(from content: String) -> String? {
        guard let start = content.firstIndex(of: "{"),
              let end = content.lastIndex(of: "}") else { return nil }
        return String(content[start ... end])
    }
}
