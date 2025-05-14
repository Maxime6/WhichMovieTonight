//
//  MovieRepositoryImpl.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 02/05/2025.
//

import Foundation

final class MovieRepositoryImpl: MovieRepository {
    private let openAIService = OpenAIService()
    
    func findSuggestedMovie(movieGenre: [MovieGenre]) async throws -> Movie {
        let movieDTO = try await openAIService.getMovieSuggestion(for: ["netflix"], movieGenre: movieGenre, mood: "happy")
        let movie = Movie(title: movieDTO.title, overview: "", posterURL: URL(string: movieDTO.posterUrl), releaseDate: Date(), genres: movieDTO.genres, streamingPlatforms: movieDTO.platforms)
        print(movieDTO.posterUrl)
        return movie
    }
}
