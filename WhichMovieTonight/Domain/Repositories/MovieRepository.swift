//
//  MovieRepository.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation

protocol MovieRepository {
    func findSuggestedMovie(movieGenre: [MovieGenre]) async throws -> Movie
}
