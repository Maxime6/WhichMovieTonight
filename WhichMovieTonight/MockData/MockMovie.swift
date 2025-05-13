//
//  MockMovie.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation

struct MockMovie {
    static let sample = Movie(id: UUID(), title: "Inception", overview: "Science fiction and thriller film with great actors.", posterURL: URL(string: "https://image.tmdb.org/t/p/w500/qmDpIHrmpJINaRKAfWQfftjCdyi.jpg"), backdropURL: nil, releaseDate: Date(), genres: ["scienceFiction", "thriller"], runtime: 0, rating: 5.0, streamingPlatforms: ["netflix", "primeVideo"], matchPercentage: 96)
}
