//
//  HomeView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var appStateManager: AppStateManager
    @State private var showingMovieDetail = false
    @State private var selectedMovie: Movie?
    @State private var showingRefreshConfirmation = false
    @Namespace private var heroAnimation

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Hero Section avec padding top
                VStack {
                    heroSection
                        .padding(.top, 20)

                    // Daily Recommendations Section
                    recommendationsSection
                        .padding(.top, 24)
                }
                .padding(.horizontal)

                Spacer()

                // Tonight's Pick fixé en bas
                VStack(spacing: 0) {
                    Divider()
                        .background(.ultraThinMaterial)

                    selectedMovieSection
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                }
            }

            // Floating Refresh Button (bas droite)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if !viewModel.currentRecommendations.isEmpty && !viewModel.isGeneratingRecommendations {
                        floatingRefreshButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 140) // Au-dessus de Tonight's Pick
                    }
                }
            }
        }
        .overlay(toastOverlay)
        .overlay(fullScreenAIThinkingIndicator)
        .confirmationDialog("Refresh Recommendations", isPresented: $showingRefreshConfirmation) {
            Button("Generate New Movies") {
                Task {
                    await viewModel.refreshRecommendations()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Generate 5 new movie recommendations?")
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
                // Fallback view if selectedMovie is nil (shouldn't happen but safety first)
                VStack {
                    Text("Erreur")
                        .font(.headline)
                    Text("Film non trouvé")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Fermer") {
                        showingMovieDetail = false
                    }
                    .padding()
                }
                .padding()
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.welcomeMessage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Don't miss your daily recommendations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Picks")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()
            }

            if viewModel.currentRecommendations.isEmpty {
                // Empty state
                emptyRecommendationsState
            } else {
                // Recommendations scroll view
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.currentRecommendations, id: \.id) { movie in
                            MovieCardView(
                                movie: movie,
                                namespace: heroAnimation,
                                onPosterTap: {
                                    selectedMovie = movie
                                    showingMovieDetail = true
                                }
                            )
                            .frame(width: 160, height: 280)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 300)
            }
        }
    }

    // MARK: - Selected Movie Section

    private var selectedMovieSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tonight's Pick")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()
            }

            if let selectedMovie = viewModel.selectedMovieForTonight {
                SelectedMovieCard(
                    movie: selectedMovie,
                    onTap: {
                        self.selectedMovie = selectedMovie
                        showingMovieDetail = true
                    },
                    onDeselect: {
                        Task {
                            await viewModel.deselectMovieForTonight()
                        }
                    }
                )
            } else {
                emptySelectedMovieState
            }
        }
    }

    // MARK: - Empty States

    private var emptyRecommendationsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "popcorn")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No recommendations yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("We're working on finding the perfect movies for you!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var emptySelectedMovieState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tv")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No movie selected for tonight")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Choose one from your daily picks above!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Floating Refresh Button

    private var floatingRefreshButton: some View {
        Button(action: {
            showingRefreshConfirmation = true
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(.ultraThickMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Toast Overlay

    private var toastOverlay: some View {
        Group {
            // Success Toast
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
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()

                        // Dismiss button
                        Button("OK") {
                            viewModel.errorMessage = nil
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    .padding(.horizontal)

                    Spacer()
                }
            }
        }
    }

    // MARK: - Full Screen AI Thinking Indicator

    private var fullScreenAIThinkingIndicator: some View {
        ZStack {
            if viewModel.isGeneratingRecommendations {
                Color.black.opacity(0.5)
                    .ignoresSafeArea(.all)

                AIThinkingIndicator()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppStateManager())
}
