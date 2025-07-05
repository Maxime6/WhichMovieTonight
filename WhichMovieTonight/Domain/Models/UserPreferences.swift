//
//  UserPreferences.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import Foundation

// MARK: - User Preferences Model

struct UserPreferences {
    let favoriteGenres: [MovieGenre]
    let favoriteActors: [String]
    let favoriteStreamingPlatforms: [StreamingPlatform]

    init(
        favoriteGenres: [MovieGenre] = [],
        favoriteActors: [String] = [],
        favoriteStreamingPlatforms: [StreamingPlatform] = []
    ) {
        self.favoriteGenres = favoriteGenres
        self.favoriteActors = favoriteActors
        self.favoriteStreamingPlatforms = favoriteStreamingPlatforms
    }

    var canGenerateRecommendations: Bool {
        !favoriteGenres.isEmpty && !favoriteStreamingPlatforms.isEmpty
    }
}
