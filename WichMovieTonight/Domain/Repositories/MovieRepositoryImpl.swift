//
//  MovieRepositoryImpl.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 02/05/2025.
//

import Foundation

final class MovieRepositoryImpl: MovieRepository {
    private let openAIService = OpenAIService()
    
    func findSuggestedMovie(movieGenre: [MovieGenre]) async throws -> Movie {
        try await openAIService.getMovieSuggestion(for: ["netflix"], movieGenre: movieGenre, mood: "happy")
    }
}
