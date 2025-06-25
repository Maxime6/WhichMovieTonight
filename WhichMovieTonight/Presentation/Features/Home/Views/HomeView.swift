//
//  HomeView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var authViewModel: AuthenticationViewModel
    @StateObject private var preferencesService = UserPreferencesService()

    @State private var showingProfileMenu = false
    @State private var showingDeleteAlert = false
    @State private var showingMovieDetail = false
    @State private var selectedMovie: Movie?
    @State private var showingRefreshConfirmation = false
    @Namespace private var heroAnimation

    init() {
        _authViewModel = StateObject(wrappedValue: AuthenticationViewModel())
        let preferencesService = UserPreferencesService()
        _preferencesService = StateObject(wrappedValue: preferencesService)
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection

                    // Selected Movie For Tonight Section
                    selectedMovieSection

                    // Daily Recommendations Section
                    recommendationsSection

                    // Bottom spacing
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
                .padding(.horizontal)
            }

            // Floating Refresh Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if !viewModel.isGeneratingRecommendations && !viewModel.dailyRecommendations.isEmpty {
                        floatingRefreshButton
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }

            // No longer using loading overlay - AI thinking indicator is integrated in recommendations section
        }
        .onAppear {
            setupViewModels()
            // Initial data loading is now handled by ContentView during launch screen
        }
        .overlay(
            Group {
                // Toast Messages
                if let message = viewModel.toastMessage, viewModel.showToast {
                    VStack {
                        Spacer()
                        ToastView(
                            message: message,
                            icon: "checkmark.seal.fill",
                            onDismiss: { viewModel.toastMessage = nil },
                            isShowing: $viewModel.showToast
                        )
                        .padding(.bottom, 100)
                    }
                }

                // Error Messages
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        ErrorBannerView(message: errorMessage)
                            .padding(.horizontal)
                        Spacer()
                    }
                }
            }
        )
        .sheet(isPresented: $showingProfileMenu) {
            ProfileMenuView(
                authViewModel: authViewModel,
                onSignOut: {
                    authViewModel.signOut()
                    showingProfileMenu = false
                },
                onDeleteAccount: {
                    showingDeleteAlert = true
                }
            )
            .presentationDetents([.medium])
        }
        .confirmationDialog("Supprimer le compte", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                Task {
                    let success = await authViewModel.deleteAccount()
                    if success {
                        showingProfileMenu = false
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action est irréversible. Toutes vos données seront supprimées et vous devrez refaire l'onboarding.")
        }
        .confirmationDialog("Today's picks ain't hitting right?", isPresented: $showingRefreshConfirmation, titleVisibility: .visible) {
            Button("Get me new ones!", role: .destructive) {
                Task {
                    await viewModel.refreshRecommendations()
                }
            }
            Button("Never mind", role: .cancel) {}
        } message: {
            Text("You sure you want different recommendations?")
        }
        .sheet(isPresented: $showingMovieDetail) {
            if let movie = selectedMovie {
                MovieDetailSheet(
                    movie: movie,
                    namespace: heroAnimation,
                    isPresented: $showingMovieDetail,
                    source: .suggestion,
                    onSelectForTonight: {
                        Task {
                            await viewModel.selectMovieForTonight(movie)
                        }
                        showingMovieDetail = false
                    }
                )
            } else {
                // Fallback view if selectedMovie is nil
                VStack {
                    Text("Error loading movie details")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Button("Close") {
                        showingMovieDetail = false
                    }
                    .padding()
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Header with Profile
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.heroMessage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let lastRefresh = viewModel.lastRefreshDate {
                        Text("Last updated: \(formatDate(lastRefresh))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: {
                    showingProfileMenu = true
                }) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Selected Movie Section

    private var selectedMovieSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tonight's pick")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }

            if let selectedMovie = viewModel.selectedMovieForTonight {
                SelectedMovieCard(
                    movie: selectedMovie,
                    onTap: {
                        // We're already on MainActor since this is a SwiftUI View
                        self.selectedMovie = selectedMovie
                        showingMovieDetail = true
                    },
                    onDeselect: {
                        Task {
                            await viewModel.deselectMovieForTonight()
                        }
                    }
                )
                .matchedGeometryEffect(
                    id: "selected-movie-\(selectedMovie.title)",
                    in: heroAnimation
                )
            } else {
                noMovieSelectedView
            }
        }
    }

    private var noMovieSelectedView: some View {
        HStack {
            Image(systemName: "questionmark.circle")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("No film selected for tonight")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Floating Refresh Button

    private var floatingRefreshButton: some View {
        Button(action: {
            showingRefreshConfirmation = true
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Today's Picks")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                if !viewModel.dailyRecommendations.isEmpty {
                    Text("\(viewModel.dailyRecommendations.count) films")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Content based on state
            if viewModel.shouldShowAIThinking {
                AIThinkingIndicator()
                    .transition(.scale.combined(with: .opacity))
            } else if viewModel.shouldShowEmptyState {
                emptyStateView
            } else if !viewModel.dailyRecommendations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.dailyRecommendations, id: \.title) { movie in
                            RecommendationCard(
                                movie: movie,
                                onTap: {
                                    selectedMovie = movie
                                    showingMovieDetail = true
                                },
                                onMarkAsSeen: {
                                    Task {
                                        await viewModel.markMovieAsSeen(movie)
                                    }
                                }
                            )
                            .matchedGeometryEffect(
                                id: "movie-\(movie.title)",
                                in: heroAnimation
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal, -16)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Loading Overlay (Deprecated - now using AI thinking indicator)

    // This overlay is no longer used in the new UX flow

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "movieclapper")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No recommendations yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Pull to refresh or check your preferences in settings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await viewModel.refreshRecommendations()
                }
            }) {
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 40)
    }

    // MARK: - Helper Methods

    private func setupViewModels() {
        if authViewModel.appStateManager == nil {
            authViewModel.appStateManager = appStateManager
        }
        viewModel.setAuthViewModel(authViewModel)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct ErrorBannerView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(AppStateManager())
}
