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
    @Published var isLoading = false
    @Published var showToast = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?
    @Published var lastRefreshDate: Date?

    // MARK: - Dependencies (Injected)

    @Injected private var homeDataService: HomeDataServiceProtocol
    @Injected private var recommendationCacheService: RecommendationCacheServiceProtocol

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

    // MARK: - Private Methods

    private func loadUserDisplayName(userId: String) async {
        let displayName = await homeDataService.loadUserDisplayName(userId: userId)
        userName = displayName
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

        // Auto-hide après 3 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showToast = false
            self.toastMessage = nil
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message

        // Auto-hide après 5 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.errorMessage = nil
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
