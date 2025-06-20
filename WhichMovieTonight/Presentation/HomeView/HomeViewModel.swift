//
//  HomeViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var selectedMovie: Movie?
    @Published var suggestedMovie: Movie?
    @Published var lastSuggestions: [Movie] = []
    @Published var isLoading = false
    @Published var selectedGenres: [MovieGenre] = []
    @Published var showToast: Bool = false
    @Published var toastMessage: String? = nil
    @Published var showMovieConfirmation = false
    @Published var showGenreSelection = false

    // Nouvelles propriétés pour les données utilisateur
    @Published var userInteractions: UserMovieInteractions?
    @Published var userData: UserMovieData?

    private let findMovieUseCase: FindTonightMovieUseCase
    private let firestoreService: FirestoreServiceProtocol
    private let preferencesService: UserPreferencesService
    private var lastSearchTime: Date = .distantPast
    var authViewModel: AuthenticationViewModel?
    private var cancellables = Set<AnyCancellable>()

    init(findMovieUseCase: FindTonightMovieUseCase = FindTonightMovieUseCaseImpl(repository: MovieRepositoryImpl()), firestoreService: FirestoreServiceProtocol = FirestoreService(), preferencesService: UserPreferencesService = UserPreferencesService()) {
        self.findMovieUseCase = findMovieUseCase
        self.firestoreService = firestoreService
        self.preferencesService = preferencesService
    }

    func setAuthViewModel(_ authViewModel: AuthenticationViewModel) {
        self.authViewModel = authViewModel
        updateUserName()

        authViewModel.$displayName
            .sink { [weak self] _ in
                self?.updateUserName()
            }
            .store(in: &cancellables)
    }

    func fetchUser() {
        updateUserName()
        resetSearchState()
        isLoading = false
        verifyConfiguration()
        loadUserData()
    }

    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                // Charger les données de films utilisateur
                let userData = try await firestoreService.getUserMovieData(for: userId)
                if let userData = userData {
                    if let selectedMovieFirestore = userData.selectedMovie {
                        selectedMovie = selectedMovieFirestore.toMovie()
                    }
                    lastSuggestions = userData.lastSuggestions.map { $0.toMovie() }
                    self.userData = userData
                }

                // Charger les interactions utilisateur
                let userInteractions = try await firestoreService.getUserMovieInteractions(for: userId)
                self.userInteractions = userInteractions

            } catch {
                print("Erreur lors du chargement des données utilisateur: \(error)")
            }
        }
    }

    private func verifyConfiguration() {
        let validation = Config.validateConfiguration()
        if !validation.isValid {
            print("Warning: Missing API keys: \(validation.missingKeys.joined(separator: ", "))")
            toastMessage = "Configuration incomplète. Vérifiez vos clés API."
            showToast = true
        }
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
            let components = displayName.components(separatedBy: " ")
            userName = components.first ?? displayName
        }
    }

    func findTonightMovie() async throws {
        await findTonightMovieInternal(enforceDelay: true)
    }

    func searchAgain() {
        resetSearchState()
        Task {
            await findTonightMovieInternal(enforceDelay: false)
        }
    }

    private func findTonightMovieInternal(enforceDelay: Bool) async {
        guard !isLoading else { return }

        guard !selectedGenres.isEmpty else {
            toastMessage = "Veuillez sélectionner au moins un genre"
            showToast = true
            return
        }

        guard !preferencesService.favoriteStreamingPlatforms.isEmpty else {
            toastMessage = "Veuillez sélectionner au moins une plateforme de streaming dans vos préférences"
            showToast = true
            return
        }

        // Éviter les recherches trop rapprochées uniquement pour la recherche initiale
        if enforceDelay {
            let now = Date()
            if now.timeIntervalSince(lastSearchTime) < 2.0 {
                toastMessage = "Veuillez patienter avant de relancer une recherche"
                showToast = true
                isLoading = false
                return
            }
            lastSearchTime = now
        }

        isLoading = true
        showGenreSelection = false

        do {
            // Utiliser les suggestions locales les plus récentes pour éviter les doublons
            var recentSuggestionsFirestore = lastSuggestions.map { movie in
                MovieFirestore(from: movie)
            }

            // Ajouter le film actuellement suggéré pour l'éviter lors d'une nouvelle recherche
            if let currentSuggestion = suggestedMovie {
                recentSuggestionsFirestore.insert(MovieFirestore(from: currentSuggestion), at: 0)
            }

            let movie = try await findMovieUseCase.execute(
                movieGenre: selectedGenres,
                streamingPlatforms: preferencesService.favoriteStreamingPlatforms,
                userInteractions: userInteractions,
                favoriteActors: preferencesService.favoriteActors,
                favoriteGenres: preferencesService.favoriteGenres,
                recentSuggestions: recentSuggestionsFirestore
            )
            suggestedMovie = movie

            // Sauvegarder la suggestion dans Firestore
            if let userId = Auth.auth().currentUser?.uid {
                try await firestoreService.saveMovieSuggestion(movie, for: userId)
                // Mettre à jour les suggestions locales
                lastSuggestions.insert(movie, at: 0)
                if lastSuggestions.count > 10 {
                    lastSuggestions = Array(lastSuggestions.prefix(10))
                }
            }

            showMovieConfirmation = true
        } catch {
            print("Error suggesting movie : \(error)")

            let errorMessage: String
            if let urlError = error as? URLError {
                switch urlError.code {
                case .userAuthenticationRequired:
                    errorMessage = "Configuration manquante. Veuillez redémarrer l'application."
                case .notConnectedToInternet:
                    errorMessage = "Pas de connexion internet. Vérifiez votre réseau."
                case .timedOut:
                    errorMessage = "Délai d'attente dépassé. Veuillez réessayer."
                default:
                    errorMessage = "Erreur de réseau. Veuillez réessayer."
                }
            } else {
                errorMessage = "Erreur lors de la recherche. Veuillez réessayer."
            }

            toastMessage = errorMessage
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

            // Sauvegarder le film sélectionné dans Firestore
            if let userId = Auth.auth().currentUser?.uid {
                Task {
                    do {
                        try await firestoreService.saveSelectedMovie(movie, for: userId)
                    } catch {
                        print("Erreur lors de la sauvegarde du film sélectionné: \(error)")
                    }
                }
            }
        }
        resetSearchState()
    }

    func clearSelectedMovie() {
        selectedMovie = nil

        // Supprimer le film sélectionné de Firestore
        if let userId = Auth.auth().currentUser?.uid {
            Task {
                do {
                    try await firestoreService.clearSelectedMovie(for: userId)
                } catch {
                    print("Erreur lors de la suppression du film sélectionné: \(error)")
                }
            }
        }
    }

    private func resetSearchState() {
        suggestedMovie = nil
        showMovieConfirmation = false
        showGenreSelection = false
    }
}
