import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var mainRecommendation: Movie?
    @Published private(set) var alternativeRecommendations: [Movie] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var selectedMovie: Movie?

    // MARK: - User Properties

    let nickname: String
    let currentMood: Mood

    // MARK: - Initialization

    init(nickname: String, currentMood: Mood) {
        self.nickname = nickname
        self.currentMood = currentMood

        // TODO: Load real data
        loadMockData()
    }

    // MARK: - Public Methods

    func refreshRecommendations() {
        // TODO: Implement real API call
        loadMockData()
    }

    func markMovieAsWatched(_: Movie, rating _: Int) {
        // TODO: Implement movie rating
    }

    // MARK: - Private Methods

    private func loadMockData() {
        mainRecommendation = Movie(
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

        alternativeRecommendations = [
            Movie(
                id: UUID(),
                title: "The Matrix",
                overview: "A computer programmer discovers that reality as he knows it is a simulation created by machines, and joins a rebellion to break free.",
                posterURL: URL(string: "https://example.com/matrix-poster.jpg"),
                backdropURL: URL(string: "https://example.com/matrix-backdrop.jpg"),
                releaseDate: Date(),
                genres: [.scienceFiction, .action],
                runtime: 136,
                rating: 8.7,
                streamingPlatforms: [.netflix],
                matchPercentage: 92
            ),
            Movie(
                id: UUID(),
                title: "Interstellar",
                overview: "A team of explorers travel through a wormhole in space in an attempt to ensure humanity's survival.",
                posterURL: URL(string: "https://example.com/interstellar-poster.jpg"),
                backdropURL: URL(string: "https://example.com/interstellar-backdrop.jpg"),
                releaseDate: Date(),
                genres: [.scienceFiction, .drama],
                runtime: 169,
                rating: 8.6,
                streamingPlatforms: [.primeVideo],
                matchPercentage: 88
            ),
        ]
    }
}
