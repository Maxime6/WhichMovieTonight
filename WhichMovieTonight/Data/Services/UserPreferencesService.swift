import Foundation

class UserPreferencesService: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let favoriteGenresKey = "favoriteGenres"
    private let favoriteActorsKey = "favoriteActors"

    @Published var favoriteGenres: [MovieGenre] = []
    @Published var favoriteActors: [String] = []

    init() {
        loadFavoriteGenres()
        loadFavoriteActors()
    }

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
}
