//
//  OpenAIService.swift
//  WichMovieTonight
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

    func getMovieSuggestion(for platforms: [String], mood: String?) async throws -> Movie {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = """
        You are an AI movie recommender. Suggest a creative, lesser-known movie I can watch tonight.

        It must be available on: \(platforms.joined(separator: ", ")).
        Mood of the user: \(mood ?? "neutral").
        Respond ONLY with JSON in the following format:

        {
          "title": "...",
          "genres": ["...", "..."],
          "poster_url": "...",
          "platforms": ["..."]
        }
        """

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 1.0
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        let content = decoded.choices.first?.message.content ?? ""
        print("OpenAI content:\n\(content)")

        guard let jsonText = extractJSON(from: content),
              let jsonData = jsonText.data(using: .utf8) else {
            throw URLError(.badServerResponse)
        }

        let suggestion = try JSONDecoder().decode(OpenAIMovieDTO.self, from: jsonData)

        return Movie(
            id: UUID(),
            title: suggestion.title,
            overview: "",
            posterURL: URL(string: suggestion.posterUrl),
            backdropURL: nil,
            releaseDate: Date(),
            genres: suggestion.genres,
            runtime: nil,
            rating: 5.0,
            streamingPlatforms: suggestion.platforms,
            matchPercentage: 95
        )
    }

    private func extractJSON(from content: String) -> String? {
        guard let start = content.firstIndex(of: "{"),
              let end = content.lastIndex(of: "}") else { return nil }
        return String(content[start...end])
    }
}
