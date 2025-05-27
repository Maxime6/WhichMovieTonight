//
//  Movie+OMDB.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 05/05/2025.
//

import Foundation

extension Movie {
    init(from omdbMovie: OMDBMovieDTO, originalGenres: [String] = [], originalPlatforms: [String] = []) {
        self.init(
            title: omdbMovie.title,
            overview: omdbMovie.plot,
            posterURL: URL(string: omdbMovie.poster ?? ""),
            releaseDate: Self.parseReleaseDate(from: omdbMovie.released),
            genres: originalGenres.isEmpty ? Self.parseGenres(from: omdbMovie.genre) : originalGenres,
            streamingPlatforms: originalPlatforms,
            director: omdbMovie.director,
            actors: omdbMovie.actors,
            runtime: omdbMovie.runtime,
            imdbRating: omdbMovie.imdbRating,
            imdbID: omdbMovie.imdbID,
            year: omdbMovie.year,
            rated: omdbMovie.rated,
            awards: omdbMovie.awards
        )
    }

    private static func parseReleaseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter.date(from: dateString)
    }

    private static func parseGenres(from genreString: String?) -> [String] {
        guard let genreString = genreString else { return [] }

        return genreString.components(separatedBy: ", ").map { genre in
            // Mapper les genres OMDB vers nos genres internes
            switch genre.lowercased() {
            case "action": return "action"
            case "adventure": return "adventure"
            case "animation": return "animation"
            case "comedy": return "comedy"
            case "crime": return "crime"
            case "documentary": return "documentary"
            case "drama": return "drama"
            case "family": return "family"
            case "fantasy": return "fantasy"
            case "horror": return "horror"
            case "mystery": return "mystery"
            case "romance": return "romance"
            case "sci-fi": return "scienceFiction"
            case "thriller": return "thriller"
            case "western": return "western"
            default: return genre.lowercased()
            }
        }
    }
}
