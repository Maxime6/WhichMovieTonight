//
//  Movie.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import Foundation

// MARK: - Movie Domain Model (Unified)

struct Movie: Identifiable, Equatable, Codable {
    let id: String // imdbID as primary key
    let title: String
    let overview: String?
    let posterURL: URL?
    let releaseDate: Date?
    let genres: [String]
    let streamingPlatforms: [String]

    // OMDB Properties
    let director: String?
    let actors: String?
    let runtime: String?
    let imdbRating: String?
    let year: String?
    let rated: String?
    let awards: String?

    // MARK: - Initializers

    /// Primary initializer with all properties
    init(
        id: String,
        title: String,
        overview: String? = nil,
        posterURL: URL? = nil,
        releaseDate: Date? = nil,
        genres: [String] = [],
        streamingPlatforms: [String] = [],
        director: String? = nil,
        actors: String? = nil,
        runtime: String? = nil,
        imdbRating: String? = nil,
        year: String? = nil,
        rated: String? = nil,
        awards: String? = nil
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterURL = posterURL
        self.releaseDate = releaseDate
        self.genres = genres
        self.streamingPlatforms = streamingPlatforms
        self.director = director
        self.actors = actors
        self.runtime = runtime
        self.imdbRating = imdbRating
        self.year = year
        self.rated = rated
        self.awards = awards
    }

    /// Convenience initializer from OMDB with fallback for missing imdbID
    init(from omdb: OMDBMovieDTO, originalGenres: [String] = [], originalPlatforms: [String] = []) {
        // Use imdbID as primary key, fallback to title+year if missing
        if let imdbID = omdb.imdbID, !imdbID.isEmpty {
            id = imdbID
        } else {
            // Fallback: create unique ID from title + year
            let cleanTitle = omdb.title.replacingOccurrences(of: " ", with: "").lowercased()
            id = "\(cleanTitle)_\(omdb.year)"
            print("⚠️ No imdbID for \(omdb.title), using fallback ID: \(id)")
        }

        title = omdb.title
        overview = omdb.plot
        posterURL = URL(string: omdb.poster ?? "")

        // Parse release date from OMDB released field
        releaseDate = DateFormatter.omdbDateFormatter.date(from: omdb.released ?? "")

        // Use original genres/platforms from AI, fallback to OMDB parsing
        if !originalGenres.isEmpty {
            genres = originalGenres
        } else {
            genres = omdb.genre?.components(separatedBy: ", ") ?? []
        }

        if !originalPlatforms.isEmpty {
            streamingPlatforms = originalPlatforms
        } else {
            streamingPlatforms = [] // OMDB doesn't provide streaming platforms
        }

        director = omdb.director
        actors = omdb.actors
        runtime = omdb.runtime
        imdbRating = omdb.imdbRating
        year = omdb.year
        rated = omdb.rated
        awards = omdb.awards
    }

    // MARK: - Computed Properties

    var formattedReleaseYear: String {
        return year ?? "Unknown"
    }

    var displayRuntime: String {
        return runtime ?? "N/A"
    }

    var hasValidPoster: Bool {
        return posterURL != nil
    }

    var displayRating: String {
        guard let rating = imdbRating, !rating.isEmpty else { return "N/A" }
        return "⭐ \(rating)"
    }

    // MARK: - Preview Data

    static var preview: Movie {
        Movie(
            id: "tt1375666",
            title: "Inception",
            overview: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.",
            posterURL: URL(string: "https://picsum.photos/300/450"),
            releaseDate: Date(),
            genres: ["Science Fiction", "Action", "Thriller"],
            streamingPlatforms: ["Netflix", "Prime Video"],
            director: "Christopher Nolan",
            actors: "Leonardo DiCaprio, Marion Cotillard, Tom Hardy",
            runtime: "148 min",
            imdbRating: "8.8",
            year: "2010",
            rated: "PG-13",
            awards: "Won 4 Oscars"
        )
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let omdbDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()
}

// MARK: - Legacy Compatibility (to be removed after migration)

extension Movie {
    /// Legacy initializer for backward compatibility during migration
    @available(*, deprecated, message: "Use init(id:title:...) instead")
    init(
        title: String,
        overview: String? = nil,
        posterURL: URL? = nil,
        releaseDate: Date? = nil,
        genres: [String] = [],
        streamingPlatforms: [String] = [],
        director: String? = nil,
        actors: String? = nil,
        runtime: String? = nil,
        imdbRating: String? = nil,
        imdbID: String? = nil,
        year: String? = nil,
        rated: String? = nil,
        awards: String? = nil
    ) {
        self.init(
            id: imdbID ?? title.replacingOccurrences(of: " ", with: "").lowercased(),
            title: title,
            overview: overview,
            posterURL: posterURL,
            releaseDate: releaseDate,
            genres: genres,
            streamingPlatforms: streamingPlatforms,
            director: director,
            actors: actors,
            runtime: runtime,
            imdbRating: imdbRating,
            year: year,
            rated: rated,
            awards: awards
        )
    }
}

// MARK: - Movie Genres

enum MovieGenre: String, CaseIterable, Identifiable {
    case action = "Action"
    case adventure = "Adventure"
    case animation = "Animation"
    case comedy = "Comedy"
    case crime = "Crime"
    case documentary = "Documentary"
    case drama = "Drama"
    case family = "Family"
    case fantasy = "Fantasy"
    case horror = "Horror"
    case mystery = "Mystery"
    case romance = "Romance"
    case scienceFiction = "Science Fiction"
    case thriller = "Thriller"
    case western = "Western"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .action: return "flame.fill"
        case .adventure: return "map.fill"
        case .animation: return "sparkles.fill"
        case .comedy: return "face.smiling.fill"
        case .crime: return "lock.fill"
        case .documentary: return "camera.fill"
        case .drama: return "theatermasks.fill"
        case .family: return "house.fill"
        case .fantasy: return "wand.and.stars"
        case .horror: return "ghost.fill"
        case .mystery: return "magnifyingglass.fill"
        case .romance: return "heart.fill"
        case .scienceFiction: return "star.fill"
        case .thriller: return "bolt.fill"
        case .western: return "sun.dust.fill"
        }
    }
}

// MARK: - Streaming Platforms

enum StreamingPlatform: String, CaseIterable, Identifiable {
    case netflix = "Netflix"
    case primeVideo = "Prime Video"
    case appleTV = "Apple TV+"
    case disneyPlus = "Disney+"
    case paramountPlus = "Paramount+"
    case hboMax = "HBO Max"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .netflix: return "play.tv.fill"
        case .primeVideo: return "play.square.fill"
        case .appleTV: return "appletv.fill"
        case .disneyPlus: return "sparkles.tv.fill"
        case .paramountPlus: return "play.circle.fill"
        case .hboMax: return "tv.fill"
        }
    }
}
