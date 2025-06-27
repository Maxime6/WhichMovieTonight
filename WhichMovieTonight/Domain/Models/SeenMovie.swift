//
//  SeenMovie.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import Foundation

// MARK: - Seen Movie Model

struct SeenMovie: Codable, Identifiable {
    let id: String
    let userId: String
    let movieId: String
    let title: String
    let seenAt: Date

    init(userId: String, movieId: String, title: String) {
        id = UUID().uuidString
        self.userId = userId
        self.movieId = movieId
        self.title = title
        seenAt = Date()
    }

    init(id: String, userId: String, movieId: String, title: String, seenAt: Date) {
        self.id = id
        self.userId = userId
        self.movieId = movieId
        self.title = title
        self.seenAt = seenAt
    }
}
