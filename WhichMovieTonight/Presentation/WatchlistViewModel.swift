//
//  WatchlistViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import FirebaseAuth
import Foundation

@MainActor
class WatchlistViewModel: ObservableObject {
    @Published var userInteractions: UserMovieInteractions?
    @Published var lastSuggestions: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    // MARK: - Public Methods

    func loadUserInteractions() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            userInteractions = try await firestoreService.getUserMovieInteractions(for: userId)
            // Charger également les dernières suggestions
            let userData = try await firestoreService.getUserMovieData(for: userId)
            if let userData = userData {
                lastSuggestions = userData.lastSuggestions.map { $0.toMovie() }
            }
        } catch {
            errorMessage = "Erreur lors du chargement des interactions: \(error.localizedDescription)"
            print("❌ Erreur lors du chargement des interactions: \(error)")
        }
    }

    func refreshData() async {
        await loadUserInteractions()
    }

    // MARK: - Computed Properties

    var favoriteMovies: [UserMovieInteraction] {
        return userInteractions?.favoriteMovies ?? []
    }

    var likedMovies: [UserMovieInteraction] {
        return userInteractions?.likedMovies ?? []
    }

    var dislikedMovies: [UserMovieInteraction] {
        return userInteractions?.dislikedMovies ?? []
    }
}
