import Foundation

class UserPreferencesService: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let favoriteGenresKey = "favoriteGenres"
    private let favoriteActorsKey = "favoriteActors"
    private let favoriteStreamingPlatformsKey = "favoriteStreamingPlatforms"

    @Published var favoriteGenres: [MovieGenre] = []
    @Published var favoriteActors: [String] = []
    @Published var favoriteStreamingPlatforms: [StreamingPlatform] = []

    init() {
        loadFavoriteGenres()
        loadFavoriteActors()
        loadFavoriteStreamingPlatforms()
    }

    // MARK: - Genres

    func loadFavoriteGenres() {
        if let data = userDefaults.data(forKey: favoriteGenresKey),
           let genreStrings = try? JSONDecoder().decode([String].self, from: data)
        {
            favoriteGenres = genreStrings.compactMap { MovieGenre(rawValue: $0) }
        }
    }

    func saveFavoriteGenres(_ genres: [MovieGenre]) {
        let genreStrings = genres.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(genreStrings) {
            userDefaults.set(data, forKey: favoriteGenresKey)
            favoriteGenres = genres
        }
    }

    func toggleGenre(_ genre: MovieGenre) {
        var updatedGenres = favoriteGenres
        if favoriteGenres.contains(genre) {
            updatedGenres.removeAll { $0 == genre }
        } else {
            updatedGenres.append(genre)
        }
        saveFavoriteGenres(updatedGenres)
    }

    func isGenreSelected(_ genre: MovieGenre) -> Bool {
        favoriteGenres.contains(genre)
    }

    // MARK: - Actors

    func loadFavoriteActors() {
        if let actors = userDefaults.stringArray(forKey: favoriteActorsKey) {
            favoriteActors = actors
        }
    }

    func saveFavoriteActors(_ actors: [String]) {
        userDefaults.set(actors, forKey: favoriteActorsKey)
        favoriteActors = actors
    }

    func addActor(_ actor: String) {
        var updatedActors = favoriteActors
        updatedActors.append(actor)
        saveFavoriteActors(updatedActors)
    }

    func removeActor(_ actor: String) {
        var updatedActors = favoriteActors
        updatedActors.removeAll { $0 == actor }
        saveFavoriteActors(updatedActors)
    }

    // MARK: - Streaming Platforms

    func loadFavoriteStreamingPlatforms() {
        if let data = userDefaults.data(forKey: favoriteStreamingPlatformsKey),
           let platformStrings = try? JSONDecoder().decode([String].self, from: data)
        {
            favoriteStreamingPlatforms = platformStrings.compactMap { StreamingPlatform(rawValue: $0) }
        }
    }

    func saveFavoriteStreamingPlatforms(_ platforms: [StreamingPlatform]) {
        let platformStrings = platforms.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(platformStrings) {
            userDefaults.set(data, forKey: favoriteStreamingPlatformsKey)
            favoriteStreamingPlatforms = platforms
        }
    }

    func toggleStreamingPlatform(_ platform: StreamingPlatform) {
        var updatedPlatforms = favoriteStreamingPlatforms
        if favoriteStreamingPlatforms.contains(platform) {
            updatedPlatforms.removeAll { $0 == platform }
        } else {
            updatedPlatforms.append(platform)
        }
        saveFavoriteStreamingPlatforms(updatedPlatforms)
    }

    func isStreamingPlatformSelected(_ platform: StreamingPlatform) -> Bool {
        favoriteStreamingPlatforms.contains(platform)
    }

    // MARK: - Preferences Model

    func getUserPreferences() -> UserPreferences {
        return UserPreferences(
            favoriteGenres: favoriteGenres,
            favoriteActors: favoriteActors,
            favoriteStreamingPlatforms: favoriteStreamingPlatforms
        )
    }
}
