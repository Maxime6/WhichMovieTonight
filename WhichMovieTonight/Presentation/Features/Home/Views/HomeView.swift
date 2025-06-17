//
//  HomeView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var authViewModel: AuthenticationViewModel
    @StateObject private var preferencesService = UserPreferencesService()

    @State private var showingProfileMenu = false
    @State private var showingDeleteAlert = false
    @State private var showingMovieDetail = false
    @State private var selectedMovie: Movie?
    @Namespace private var heroAnimation

    init() {
        _authViewModel = StateObject(wrappedValue: AuthenticationViewModel())
        let preferencesService = UserPreferencesService()
        _preferencesService = StateObject(wrappedValue: preferencesService)
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection

                    // Daily Recommendations Section
                    recommendationsSection

                    // Bottom spacing
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
                .padding(.horizontal)
            }

            // Loading Overlay
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            setupViewModels()
            Task {
                await viewModel.loadInitialData()
            }
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
        .alert("Supprimer le compte", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                Task {
                    let success = await authViewModel.deleteAccount()
                    if success {
                        showingProfileMenu = false
                    }
                }
            }
        } message: {
            Text("Cette action est irréversible. Toutes vos données seront supprimées et vous devrez refaire l'onboarding.")
        }
        .sheet(isPresented: $showingMovieDetail) {
            if let movie = selectedMovie {
                MovieDetailSheet(
                    movie: movie,
                    namespace: heroAnimation,
                    isPresented: $showingMovieDetail,
                    source: .suggestion,
                    onSelectForTonight: nil
                )
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

            // Refresh Button
            if !viewModel.isLoading && !viewModel.dailyRecommendations.isEmpty {
                Button(action: {
                    Task {
                        await viewModel.refreshRecommendations()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh recommendations")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            if viewModel.shouldShowEmptyState {
                emptyStateView
            } else if !viewModel.dailyRecommendations.isEmpty {
                VStack(spacing: 16) {
                    HStack {
                        Text("Today's Picks")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(viewModel.dailyRecommendations.count) films")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

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
                }
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Generating your daily recommendations...")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("This may take a few moments")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThickMaterial)
            )
            .padding(.horizontal, 32)
        }
    }

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
                Text("Generate Recommendations")
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
