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

    @Published var userName: String = ""
    @Published var dailyRecommendations: [Movie] = []
    @Published var isLoading = false
    @Published var showToast = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?
    @Published var lastRefreshDate: Date?

    // MARK: - Dependencies

    private let getDailyRecommendationsUseCase: GetDailyRecommendationsUseCase
    private let recommendationCacheService: RecommendationCacheServiceProtocol
    private let notificationService: DailyNotificationServiceProtocol
    private let preferencesService: UserPreferencesService
    private let firestoreService: FirestoreServiceProtocol

    private var authViewModel: AuthenticationViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var userInteractions: UserMovieInteractions?

    // MARK: - Initialization

    init(
        getDailyRecommendationsUseCase: GetDailyRecommendationsUseCase = GetDailyRecommendationsUseCaseImpl(repository: MovieRepositoryImpl()),
        recommendationCacheService: RecommendationCacheServiceProtocol = RecommendationCacheService(),
        notificationService: DailyNotificationServiceProtocol = DailyNotificationService(),
        preferencesService: UserPreferencesService = UserPreferencesService(),
        firestoreService: FirestoreServiceProtocol = FirestoreService()
    ) {
        self.getDailyRecommendationsUseCase = getDailyRecommendationsUseCase
        self.recommendationCacheService = recommendationCacheService
        self.notificationService = notificationService
        self.preferencesService = preferencesService
        self.firestoreService = firestoreService

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
                    await self?.generateDailyRecommendations()
                }
            }
            .store(in: &cancellables)
    }

    private func updateUserName() {
        guard let authViewModel = authViewModel else {
            userName = "User"
            return
        }

        let displayName = authViewModel.displayName
        if displayName.isEmpty {
            userName = "User"
        } else {
            let components = displayName.components(separatedBy: " ")
            userName = components.first ?? displayName
        }
    }

    // MARK: - Public Methods

    func loadInitialData() async {
        await loadUserData()
        await loadTodaysRecommendations()
        await setupNotifications()
    }

    func refreshRecommendations() async {
        await generateDailyRecommendations()
    }

    func markMovieAsSeen(_ movie: Movie) async {
        do {
            try await recommendationCacheService.markMovieAsSeen(movie)
            showToastMessage("Film marqué comme déjà vu")
            // Optionnel : supprimer le film des recommandations actuelles
            dailyRecommendations.removeAll { $0.title == movie.title }
        } catch {
            showErrorMessage("Erreur lors du marquage du film")
        }
    }

    // MARK: - Private Methods

    private func loadUserData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            userInteractions = try await firestoreService.getUserMovieInteractions(for: userId)
        } catch {
            print("Erreur lors du chargement des interactions utilisateur: \(error)")
        }
    }

    private func loadTodaysRecommendations() async {
        do {
            print("🔍 Recherche des recommandations du jour...")
            // Vérifier si des recommandations existent déjà pour aujourd'hui
            if let todaysRecommendations = try await recommendationCacheService.getTodaysRecommendations() {
                dailyRecommendations = todaysRecommendations.movies.map { $0.toMovie() }
                lastRefreshDate = todaysRecommendations.generatedAt
                print("✅ Recommandations du jour chargées depuis le cache: \(dailyRecommendations.count) films")
            } else {
                print("📄 Aucune recommandation trouvée pour aujourd'hui, génération en cours...")
                // Générer de nouvelles recommandations
                await generateDailyRecommendations()
            }
        } catch {
            print("❌ Erreur lors du chargement des recommandations: \(error)")
            // Ignorer l'erreur de l'index manquant et générer des recommandations
            if error.localizedDescription.contains("requires an index") {
                print("⚠️ Index Firestore manquant, génération de nouvelles recommandations...")
                await generateDailyRecommendations()
            } else {
                showErrorMessage("Impossible de charger les recommandations")
            }
        }
    }

    private func generateDailyRecommendations() async {
        guard !isLoading else {
            print("⏳ Génération déjà en cours, abandon...")
            return
        }

        print("🎬 Début de génération des recommandations quotidiennes")

        // Validation des préférences
        guard !preferencesService.favoriteGenres.isEmpty else {
            print("❌ Aucun genre favori configuré")
            showErrorMessage("Veuillez configurer vos genres favoris dans les paramètres")
            return
        }

        guard !preferencesService.favoriteStreamingPlatforms.isEmpty else {
            print("❌ Aucune plateforme de streaming configurée")
            showErrorMessage("Veuillez configurer vos plateformes de streaming dans les paramètres")
            return
        }

        print("✅ Préférences valides - Genres: \(preferencesService.favoriteGenres.count), Plateformes: \(preferencesService.favoriteStreamingPlatforms.count)")

        isLoading = true
        errorMessage = nil

        do {
            // Obtenir les IDs des films à exclure
            let excludedMovieIds = try await recommendationCacheService.getExcludedMovieIds()

            // Générer 5 nouvelles recommandations
            let newRecommendations = try await getDailyRecommendationsUseCase.execute(
                userPreferences: preferencesService,
                userInteractions: userInteractions,
                excludeMovieIds: excludedMovieIds
            )

            // Sauvegarder les recommandations
            guard let userId = Auth.auth().currentUser?.uid else {
                throw RecommendationError.generationFailed("Utilisateur non authentifié")
            }

            let dailyRecommendationsModel = DailyRecommendations(
                userId: userId,
                date: Calendar.current.startOfDay(for: Date()),
                movies: newRecommendations.map { MovieFirestore(from: $0) }
            )
            try await recommendationCacheService.saveDailyRecommendations(dailyRecommendationsModel)

            // Mettre à jour l'interface
            dailyRecommendations = newRecommendations
            lastRefreshDate = Date()

            showToastMessage("5 nouveaux films sélectionnés pour vous !")

        } catch let RecommendationError.missingPreferences(message) {
            showErrorMessage(message)
        } catch let RecommendationError.generationFailed(message) {
            showErrorMessage(message)
            // Essayer de charger les recommandations du jour précédent
            await loadPreviousDayRecommendations()
        } catch {
            showErrorMessage("Erreur lors de la génération des recommandations")
            await loadPreviousDayRecommendations()
        }

        isLoading = false
    }

    private func loadPreviousDayRecommendations() async {
        do {
            let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            if let previousRecommendations = try await recommendationCacheService.getDailyRecommendations(for: previousDay) {
                dailyRecommendations = previousRecommendations.movies.map { $0.toMovie() }
                showToastMessage("Recommandations du jour précédent affichées")
            }
        } catch {
            print("Impossible de charger les recommandations du jour précédent: \(error)")
        }
    }

    private func setupNotifications() async {
        let granted = await notificationService.requestPermission()
        if granted {
            notificationService.scheduleDailyRecommendationNotification()
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
        "Hey \(userName), here are your daily recommendations"
    }
}
