//
//  HomeViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Combine
import Foundation
import SwiftUI

// enum HomeViewState: Equatable {
//    case idle
//    case selectingGenres
//    case loading
//    case showingResult(Movie)
//    case error
// }

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var selectedMovie: Movie?
    @Published var isLoading = false
    @Published var selectedGenres: [MovieGenre] = []
    @Published var showToast: Bool = false
    @Published var toastMessage: String? = nil

    private let findMovieUseCase: FindTonightMovieUseCase
    private var authViewModel: AuthenticationViewModel?
    private var cancellables = Set<AnyCancellable>()

    init(findMovieUseCase: FindTonightMovieUseCase = FindTonightMovieUseCaseImpl(repository: MovieRepositoryImpl())) {
        self.findMovieUseCase = findMovieUseCase
    }

    func setAuthViewModel(_ authViewModel: AuthenticationViewModel) {
        self.authViewModel = authViewModel
        updateUserName()

        // Observe changes in displayName
        authViewModel.$displayName
            .sink { [weak self] _ in
                self?.updateUserName()
            }
            .store(in: &cancellables)
    }

    func fetchUser() {
        updateUserName()
    }

    private func updateUserName() {
        guard let authViewModel = authViewModel else {
            userName = "Utilisateur"
            return
        }

        let displayName = authViewModel.displayName
        if displayName.isEmpty {
            userName = "Utilisateur"
        } else {
            // Extract first name from display name
            let components = displayName.components(separatedBy: " ")
            userName = components.first ?? displayName
        }
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
