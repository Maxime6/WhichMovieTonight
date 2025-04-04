import Foundation

struct Movie: Identifiable, Equatable {
    let id: UUID
    let title: String
    let overview: String
    let posterURL: URL?
    let backdropURL: URL?
    let releaseDate: Date
    let genres: [MovieGenre]
    let runtime: Int // in minutes
    let rating: Double // IMDb rating
    let streamingPlatforms: [StreamingPlatform]
    let matchPercentage: Int

    var formattedRuntime: String {
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedReleaseYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: releaseDate)
    }

    // Example movie for previews
    static var preview: Movie {
        Movie(
            id: UUID(),
            title: "Inception",
            overview: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.",
            posterURL: URL(string: "https://example.com/inception-poster.jpg"),
            backdropURL: URL(string: "https://example.com/inception-backdrop.jpg"),
            releaseDate: Date(),
            genres: [.scienceFiction, .action, .thriller],
            runtime: 148,
            rating: 8.8,
            streamingPlatforms: [.netflix, .primeVideo],
            matchPercentage: 95
        )
    }
}
