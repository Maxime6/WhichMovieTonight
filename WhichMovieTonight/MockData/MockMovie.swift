//
//  MockMovie.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation

enum MockMovie {
    static let sample = Movie(
        title: "Inception",
        overview: "Science fiction and thriller film with great actors.",
        posterURL: URL(string: "https://image.tmdb.org/t/p/w500/qmDpIHrmpJINaRKAfWQfftjCdyi.jpg"),
        releaseDate: Date(),
        genres: ["scienceFiction", "thriller"],
        streamingPlatforms: ["netflix", "primeVideo"],
        director: "Christopher Nolan",
        actors: "Leonardo DiCaprio, Marion Cotillard, Tom Hardy",
        runtime: "148 min",
        imdbRating: "8.8",
        imdbID: "tt1375666",
        year: "2010",
        rated: "PG-13",
        awards: "Won 4 Oscars"
    )
}
