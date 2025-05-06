//
//  HomeViewModel.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userName: String = "Maxime"
    @Published var selectedMovie: Movie?
    @Published var isLoading = false
    @Published var selectedGenres: [MovieGenre] = []
    
    private let findMovieUseCase: FindTonightMovieUseCase
    
    init(findMovieUseCase: FindTonightMovieUseCase = FindTonightMovieUseCaseImpl(repository: MovieRepositoryImpl())) {
        self.findMovieUseCase = findMovieUseCase
    }
    
    func fetchUser() {
        userName = "Maxime"
    }
    
    func findTonightMovie() async throws {
        withAnimation {
            isLoading = true
        }
        
        do {
            let movie = try await findMovieUseCase.execute(movieGenre: selectedGenres)
            selectedMovie = Movie(id: movie.id,
                                  title: movie.title,
                                  overview: movie.overview,
                                  posterURL: movie.posterURL,
                                  backdropURL: movie.backdropURL,
                                  releaseDate: movie.releaseDate,
                                  genres: movie.genres,
                                  runtime: movie.runtime,
                                  rating: movie.rating,
                                  streamingPlatforms: movie.streamingPlatforms,
                                  matchPercentage: movie.matchPercentage)
        } catch {
            print("Error suggesting movie : \(error)")
        }
        
        withAnimation {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.isLoading = false
            }
            
        }
    }
    
//    func confirmGenreSelectionAndStartSearch() async {
//        guard !selectedGenres.isEmpty else { return }
//        
//        state = .loading
//        
//        do {
//            let movie = try await findMovieUseCase.execute(
//                movieGenre: selectedGenres
//            )
//            state = .showingResult(movie)
//            selectedGenres = [] // 🔁 reset après usage
//        } catch {
//            print("Error suggesting movie: \(error)")
//            state = .error
//        }
//    }
}
