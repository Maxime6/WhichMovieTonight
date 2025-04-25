//
//  HomeViewModel.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userName: String = "Maxime"
    @Published var selectedMovie: Movie?
    @Published var isLoading = false
    
    private let findMovieUseCase: FindTonightMovieUseCase
    
    init(findMovieUseCase: FindTonightMovieUseCase = FindTonightMovieUseCaseImpl(repository: MockMovieRepository())) {
        self.findMovieUseCase = findMovieUseCase
    }
    
    func fetchUser() {
        userName = "Maxime"
    }
    
    func findTonightMovie() async throws {
        isLoading = true
        
        do {
            let movie = try await findMovieUseCase.execute()
            selectedMovie = Movie(id: movie.id, title: movie.title, overview: movie.overview, posterURL: movie.posterURL, backdropURL: movie.backdropURL, releaseDate: movie.releaseDate, genres: movie.genres, runtime: movie.runtime, rating: movie.rating, streamingPlatforms: movie.streamingPlatforms, matchPercentage: movie.matchPercentage)
        } catch {
            print("Error suggesting movie : \(error)")
        }
        
        isLoading = false
    }
}
