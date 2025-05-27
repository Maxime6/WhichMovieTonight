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
    @Published var suggestedMovie: Movie?
    @Published var isLoading = false
    @Published var selectedGenres: [MovieGenre] = []
    @Published var showToast: Bool = false
    @Published var toastMessage: String? = nil
    @Published var showMovieConfirmation = false
    @Published var showGenreSelection = false

    private let findMovieUseCase: FindTonightMovieUseCase
    private var lastSearchTime: Date = .distantPast
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
        // Reset des états temporaires au démarrage
        resetSearchState()
        isLoading = false
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
        // Éviter les recherches multiples simultanées
        guard !isLoading else { return }

        // Éviter les recherches trop rapprochées (minimum 2 secondes)
        let now = Date()
        if now.timeIntervalSince(lastSearchTime) < 2.0 {
            toastMessage = "Veuillez patienter avant de relancer une recherche"
            showToast = true
            isLoading = false
            return
        }
        lastSearchTime = now

        isLoading = true
        showGenreSelection = false // Fermer l'écran de sélection

        do {
            let movie = try await findMovieUseCase.execute(movieGenre: selectedGenres)
            suggestedMovie = movie // Stocker le film suggéré pour l'écran de confirmation
            showMovieConfirmation = true // Afficher l'écran de confirmation
        } catch {
            print("Error suggesting movie : \(error)")
            // En cas d'erreur, afficher un message et reset l'état
            toastMessage = "Erreur lors de la recherche. Veuillez réessayer."
            showToast = true
            resetSearchState()
        }

        isLoading = false
    }

    func confirmMovie() {
        if let movie = suggestedMovie {
            selectedMovie = movie
            toastMessage = "Film sélectionné ! Bon visionnage !"
            showToast = true
        }
        resetSearchState()
    }

    func searchAgain() {
        resetSearchState()
        // Relancer automatiquement une nouvelle recherche
        Task {
            try await findTonightMovie()
        }
    }

    private func resetSearchState() {
        suggestedMovie = nil
        showMovieConfirmation = false
        showGenreSelection = false
    }
}
