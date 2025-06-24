//
//  HomeViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//  Refactored by AI Assistant on 25/04/2025.
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var userName: String = "Cinéphile"
    @Published var dailyRecommendations: [Movie] = []
    @Published var selectedMovieForTonight: Movie?
    @Published var isLoading = false
    @Published var showToast = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?
    @Published var lastRefreshDate: Date?

    // MARK: - Dependencies (Injected)

    @Injected private var homeDataService: HomeDataServiceProtocol
    @Injected private var recommendationCacheService: RecommendationCacheServiceProtocol
    @Injected private var userDataService: UserDataServiceProtocol

    // MARK: - Private Properties

    private var authViewModel: AuthenticationViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupNotificationObservers()
    }

    // MARK: - Setup Methods

    func setAuthViewModel(_ authViewModel: AuthenticationViewModel) {
        self.authViewModel = authViewModel
        updateUserName()

        authViewModel.$displayName
            .sink { [weak self] _ in
                self?.updateUserName()
            }
            .store(in: &cancellables)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .shouldGenerateRecommendations)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshRecommendations()
                }
            }
            .store(in: &cancellables)
    }

    private func updateUserName() {
        guard let authViewModel = authViewModel else {
            userName = "Cinéphile"
            return
        }

        let displayName = authViewModel.displayName
        if displayName.isEmpty {
            userName = "Cinéphile"
        } else {
            let components = displayName.components(separatedBy: " ")
            userName = components.first ?? displayName
        }
    }

    // MARK: - Public Methods

    func loadInitialData() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            showErrorMessage("Utilisateur non authentifié")
            return
        }

        await loadUserDisplayName(userId: userId)
        await loadSelectedMovieForTonight(userId: userId)
        await loadTodaysRecommendations(userId: userId)
        await setupNotifications()
    }

    func refreshRecommendations() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            showErrorMessage("Utilisateur non authentifié")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let recommendations = try await homeDataService.refreshRecommendations(userId: userId)
            dailyRecommendations = recommendations
            lastRefreshDate = Date()
            showToastMessage("5 nouveaux films sélectionnés pour vous !")
        } catch {
            showErrorMessage("Erreur lors de l'actualisation des recommandations")
            print("❌ Erreur refresh: \(error)")
        }

        isLoading = false
    }

    func markMovieAsSeen(_ movie: Movie) async {
        do {
            try await recommendationCacheService.markMovieAsSeen(movie)
            showToastMessage("Film marqué comme déjà vu")
            // Supprimer le film des recommandations actuelles
            dailyRecommendations.removeAll { $0.title == movie.title }
        } catch {
            showErrorMessage("Erreur lors du marquage du film")
            print("❌ Erreur mark as seen: \(error)")
        }
    }

    // MARK: - Selected Movie For Tonight Methods

    func selectMovieForTonight(_ movie: Movie) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            showErrorMessage("Utilisateur non authentifié")
            return
        }

        do {
            try await userDataService.saveSelectedMovie(movie, for: userId)
            selectedMovieForTonight = movie
            showToastMessage("Film sélectionné pour ce soir !")
        } catch {
            showErrorMessage("Erreur lors de la sélection du film")
            print("❌ Erreur select movie: \(error)")
        }
    }

    func deselectMovieForTonight() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            showErrorMessage("Utilisateur non authentifié")
            return
        }

        do {
            try await userDataService.clearSelectedMovie(for: userId)
            selectedMovieForTonight = nil
            showToastMessage("Film désélectionné")
        } catch {
            showErrorMessage("Erreur lors de la désélection du film")
            print("❌ Erreur deselect movie: \(error)")
        }
    }

    // MARK: - Private Methods

    private func loadUserDisplayName(userId: String) async {
        let displayName = await homeDataService.loadUserDisplayName(userId: userId)
        userName = displayName
    }

    private func loadSelectedMovieForTonight(userId: String) async {
        do {
            if let userData = try await userDataService.getUserMovieData(for: userId),
               let selectedMovieData = userData.selectedMovie
            {
                // Check if the selected movie is still valid (before 6am next day)
                if isSelectedMovieStillValid(userData.updatedAt) {
                    selectedMovieForTonight = selectedMovieData.toMovie()
                } else {
                    // Movie selection has expired, clear it
                    try await userDataService.clearSelectedMovie(for: userId)
                    selectedMovieForTonight = nil
                }
            }
        } catch {
            print("❌ Erreur lors du chargement du film sélectionné: \(error)")
            selectedMovieForTonight = nil
        }
    }

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

    private func loadTodaysRecommendations(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let recommendations = try await homeDataService.loadTodaysRecommendations(userId: userId)
            dailyRecommendations = recommendations
            lastRefreshDate = Date()
            print("✅ \(recommendations.count) recommandations chargées avec succès")
        } catch {
            showErrorMessage("Impossible de charger les recommandations")
            print("❌ Erreur load recommendations: \(error)")
            // Fallback: essayer de générer de nouvelles recommandations
            await refreshRecommendations()
        }

        isLoading = false
    }

    private func setupNotifications() async {
        do {
            try await homeDataService.setupNotifications()
        } catch {
            print("⚠️ Erreur configuration notifications: \(error)")
            // Les notifications ne sont pas critiques, on continue sans erreur
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true

        // Auto-hide après 3 secondes using Task instead of DispatchQueue
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            showToast = false
            toastMessage = nil
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message

        // Auto-hide après 5 secondes using Task instead of DispatchQueue
        Task {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            errorMessage = nil
        }
    }

    // MARK: - Computed Properties

    var shouldShowEmptyState: Bool {
        dailyRecommendations.isEmpty && !isLoading
    }

    var heroMessage: String {
        "Hey \(userName), voici vos recommandations du jour"
    }
}
