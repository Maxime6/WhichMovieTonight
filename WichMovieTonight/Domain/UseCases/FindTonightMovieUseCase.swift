//
//  FindTonightMovieUseCase.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation

protocol FindTonightMovieUseCase {
    func execute(movieGenre: [MovieGenre]) async throws -> Movie
}

final class FindTonightMovieUseCaseImpl: FindTonightMovieUseCase {
    private let repository: MovieRepository
    
    init(repository: MovieRepository) {
        self.repository = repository
    }
    
    func execute(movieGenre: [MovieGenre]) async throws -> Movie {
        try await repository.findSuggestedMovie(movieGenre: movieGenre)
    }
}
