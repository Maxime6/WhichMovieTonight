//
//  HomeViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation
import SwiftUI

//enum HomeViewState: Equatable {
//    case idle
//    case selectingGenres
//    case loading
//    case showingResult(Movie)
//    case error
//}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userName: String = "Maxime"
    @Published var selectedMovie: Movie?
    @Published var isLoading = false
    @Published var selectedGenres: [MovieGenre] = []
    @Published var showToast: Bool = false
    @Published var toastMessage: String? = nil

    private let findMovieUseCase: FindTonightMovieUseCase

    init(findMovieUseCase: FindTonightMovieUseCase = FindTonightMovieUseCaseImpl(repository: MovieRepositoryImpl())) {
        self.findMovieUseCase = findMovieUseCase
    }

    func fetchUser() {
        userName = "Maxime"
    }

    func findTonightMovie() async throws {
        do {
            let movie = try await findMovieUseCase.execute(movieGenre: selectedGenres)
            selectedMovie = Movie(title: movie.title,
                                  overview: movie.overview,
                                  posterURL: movie.posterURL,
                                  releaseDate: movie.releaseDate,
                                  genres: movie.genres,
                                  streamingPlatforms: movie.streamingPlatforms)
            toastMessage = "AI has find your movie"
            showToast = true
        } catch {
            print("Error suggesting movie : \(error)")
        }

        withAnimation {
                self.isLoading = false
        }
    }
}
