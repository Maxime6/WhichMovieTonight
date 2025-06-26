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
            Color(.systemGray6)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection

                    // Daily Recommendations Section
                    recommendationsSection

                    // Selected Movie For Tonight Section
                    selectedMovieSection

                    // Bottom spacing for tab bar
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
                    if !appStateManager.dailyRecommendations.isEmpty && !appStateManager.isGeneratingRecommendations {
                        floatingRefreshButton
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
        .overlay(toastOverlay)
        .confirmationDialog(
            "Today's picks not hitting right?",
            isPresented: $showingRefreshConfirmation,
            titleVisibility: .visible
        ) {
            Button("Get me new ones!", role: .destructive) {
                Task {
                    await appStateManager.refreshRecommendations()
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

            if appStateManager.isGeneratingRecommendations {
                // Show AI thinking indicator
                AIThinkingIndicator()
                    .frame(height: 200)
            } else if appStateManager.dailyRecommendations.isEmpty {
                // Empty state
                emptyRecommendationsState
            } else {
                // Recommendations scroll view
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(appStateManager.dailyRecommendations, id: \.id) { movie in
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
        .background(Color(.systemBackground))
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
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Floating Refresh Button

    private var floatingRefreshButton: some View {
        Button(action: {
            showingRefreshConfirmation = true
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
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
}

#Preview {
    HomeView()
        .environmentObject(AppStateManager())
}
