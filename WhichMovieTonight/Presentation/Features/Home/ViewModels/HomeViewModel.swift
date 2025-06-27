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

    @Published var currentRecommendations: [Movie] = []
    @Published var selectedMovieForTonight: Movie?
    @Published var isGeneratingRecommendations = false
    @Published var userName: String = "Movie Lover"

    // UI State
    @Published var showToast: Bool = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    // MARK: - Dependencies (Simplified)

    private let recommendationService: RecommendationServiceProtocol
    private let firestoreService: FirestoreService
    private let movieInteractionService: MovieInteractionServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        recommendationService: RecommendationServiceProtocol = RecommendationService(),
        firestoreService: FirestoreService = FirestoreService(),
        movieInteractionService: MovieInteractionServiceProtocol = MovieInteractionService()
    ) {
        self.recommendationService = recommendationService
        self.firestoreService = firestoreService
        self.movieInteractionService = movieInteractionService

        Task {
            await initializeData()
        }
    }

    // MARK: - Computed Properties

    var welcomeMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        return "\(greeting) \(userName), ready for new discoveries?"
    }

    // MARK: - Public Methods

    /// Initialize all data for HomeView
    func initializeData() async {
        await loadUserDisplayName()
        await loadSelectedMovieForTonight()
        await loadOrGenerateRecommendations()
    }

    /// Load or generate recommendations
    private func loadOrGenerateRecommendations() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID available")
            return
        }

        do {
            // Try to load existing recommendations
            let existingRecommendations = try await recommendationService.loadCurrentRecommendations(for: userId)

            if !existingRecommendations.isEmpty {
                currentRecommendations = existingRecommendations
                print("📱 Loaded \(existingRecommendations.count) existing recommendations")
            } else {
                // Generate new recommendations
                await generateRecommendations()
            }
        } catch {
            print("❌ Error loading recommendations: \(error)")
            if error.localizedDescription.contains("offline") {
                showOfflineMessage()
            } else {
                errorMessage = "Failed to load recommendations. Please try again."
            }
        }
    }

    /// Generate new recommendations (initial or refresh)
    func generateRecommendations() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID available for generation")
            return
        }

        isGeneratingRecommendations = true

        do {
            let newRecommendations = try await recommendationService.generateNewRecommendations(for: userId)
            currentRecommendations = newRecommendations
            print("🎉 Generated \(newRecommendations.count) new recommendations")
        } catch {
            print("❌ Failed to generate recommendations: \(error)")
            if error.localizedDescription.contains("offline") {
                showOfflineMessage()
            } else {
                errorMessage = "Unable to generate recommendations. Please try again."
            }
        }

        isGeneratingRecommendations = false
    }

    /// Manual refresh recommendations
    func refreshRecommendations() async {
        print("🔄 Manual refresh triggered")
        await generateRecommendations()
    }

    // MARK: - Selected Movie For Tonight Management

    /// Select a movie for tonight and save to Firestore
    func selectMovieForTonight(_ movie: Movie) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        do {
            let movieFirestore = MovieFirestore(from: movie)
            try await firestoreService.saveSelectedMovieForTonight(movieFirestore, for: userId)
            selectedMovieForTonight = movie
            showToastMessage("Selected for tonight: \(movie.title)")
        } catch {
            print("❌ Error selecting movie for tonight: \(error)")
            errorMessage = "Failed to select movie. Please try again."
        }
    }

    /// Deselect current movie for tonight
    func deselectMovieForTonight() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication required"
            return
        }

        do {
            try await firestoreService.removeSelectedMovieForTonight(for: userId)
            selectedMovieForTonight = nil
            showToastMessage("Movie deselected")
        } catch {
            print("❌ Error deselecting movie: \(error)")
            errorMessage = "Failed to deselect movie. Please try again."
        }
    }

    // MARK: - Private Methods

    private func loadUserDisplayName() async {
        if let user = Auth.auth().currentUser {
            userName = user.displayName ?? "Movie Lover"
        }
    }

    private func loadSelectedMovieForTonight() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            if let movieFirestore = try await firestoreService.getSelectedMovieForTonight(for: userId) {
                selectedMovieForTonight = movieFirestore.toMovie()
                print("📱 Loaded selected movie for tonight: \(movieFirestore.title)")
            }
        } catch {
            print("❌ Error loading selected movie: \(error)")
            if error.localizedDescription.contains("offline") {
                print("📱 App is offline - selected movie will load when connection is restored")
            }
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showToast = false
            self.toastMessage = nil
        }
    }

    private func showOfflineMessage() {
        errorMessage = "No internet connection. Please check your connection and try again."
    }
}
