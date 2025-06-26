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
    // MARK: - Published Properties

    @Published var selectedMovieForTonight: Movie?
    @Published var userName: String = "Movie Lover"

    // UI State
    @Published var showToast: Bool = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    // MARK: - Dependencies (Simplified)

    private let firestoreService: FirestoreService
    private let movieInteractionService: MovieInteractionServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        firestoreService: FirestoreService = FirestoreService(),
        movieInteractionService: MovieInteractionServiceProtocol = MovieInteractionService()
    ) {
        self.firestoreService = firestoreService
        self.movieInteractionService = movieInteractionService
        loadUserData()
    }

    // MARK: - Public Methods

    /// Load user display name and selected movie for tonight
    func loadUserData() {
        Task {
            await loadUserDisplayName()
            await loadSelectedMovieForTonight()
        }
    }

    /// Manual refresh recommendations via AppStateManager
    func refreshRecommendations() async {
        // This will be called from the view with appStateManager.refreshRecommendations()
        // No longer handled in HomeViewModel
    }

    // MARK: - Selected Movie For Tonight Management

    /// Select a movie for tonight and save to Firestore
    func selectMovieForTonight(_ movie: Movie) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            showErrorMessage("User not authenticated")
            return
        }

        do {
            try await firestoreService.saveSelectedMovieForTonight(movie, for: userId)
            selectedMovieForTonight = movie
            showToastMessage("Selected for tonight! 🎬")

        } catch {
            showErrorMessage("Failed to select movie")
            print("❌ Error selecting movie: \(error)")
        }
    }

    /// Remove selected movie for tonight
    func deselectMovieForTonight() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            showErrorMessage("User not authenticated")
            return
        }

        do {
            try await firestoreService.clearSelectedMovieForTonight(for: userId)
            selectedMovieForTonight = nil
            showToastMessage("Movie deselected")

        } catch {
            showErrorMessage("Failed to deselect movie")
            print("❌ Error deselecting movie: \(error)")
        }
    }

    // MARK: - Movie Interactions (Delegated to Service)

    /// Mark movie as seen and remove from recommendations
    func markMovieAsSeen(_ movie: Movie) async {
        do {
            try await movieInteractionService.markAsSeen(for: movie)
            showToastMessage("Marked as watched ✓")

        } catch {
            showErrorMessage("Failed to mark movie as seen")
            print("❌ Error marking movie as seen: \(error)")
        }
    }

    // MARK: - Private Methods

    /// Load user display name from Auth
    private func loadUserDisplayName() async {
        guard let user = Auth.auth().currentUser else {
            userName = "Movie Lover"
            return
        }

        let displayName = user.displayName ?? ""
        if displayName.isEmpty {
            userName = "Movie Lover"
        } else {
            let components = displayName.components(separatedBy: " ")
            userName = components.first ?? displayName
        }
    }

    /// Load selected movie for tonight from Firestore
    private func loadSelectedMovieForTonight() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }

        do {
            let movieData = try await firestoreService.getSelectedMovieForTonight(for: userId)

            // Check if movie is still valid (selected today)
            if let movieData = movieData, isSelectedMovieStillValid(movieData.createdAt) {
                selectedMovieForTonight = movieData.selectedMovie?.toMovie()
            } else if movieData != nil {
                // Clear invalid selection
                try await firestoreService.clearSelectedMovieForTonight(for: userId)
                selectedMovieForTonight = nil
            }
        } catch {
            // Handle offline gracefully - don't show error for offline mode
            if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                print("📱 App is offline - selected movie will load when connection is restored")
                // Don't set error message for offline state
            } else {
                errorMessage = "Erreur lors du chargement du film sélectionné"
                print("❌ Error loading selected movie: \(error)")
            }
        }
    }

    /// Check if selected movie is still valid (before 6am next day)
    private func isSelectedMovieStillValid(_ selectionDate: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Calculate 6am of the next day after selection
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: selectionDate),
              let expirationTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: nextDay)
        else {
            return false
        }

        return now < expirationTime
    }

    // MARK: - UI Helpers

    /// Show success toast message
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true

        // Auto-hide after 3 seconds
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            showToast = false
            toastMessage = nil
        }
    }

    /// Show error message
    private func showErrorMessage(_ message: String) {
        errorMessage = message

        // Auto-hide after 5 seconds
        Task {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            errorMessage = nil
        }
    }

    // MARK: - Computed Properties

    /// Welcome message for the user
    var welcomeMessage: String {
        "Hello \(userName), ready for new discoveries?"
    }

    /// Check if there's a selected movie for tonight
    var hasSelectedMovie: Bool {
        selectedMovieForTonight != nil
    }
}
