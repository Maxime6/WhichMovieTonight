import Foundation

class UserPreferencesService: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let favoriteGenresKey = "favoriteGenres"

    @Published var favoriteGenres: [MovieGenre] = []

    init() {
        loadFavoriteGenres()
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
}
