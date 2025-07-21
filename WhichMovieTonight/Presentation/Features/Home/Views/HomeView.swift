//
//  HomeView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import FirebaseAuth
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @EnvironmentObject private var appStateManager: AppStateManager
    @EnvironmentObject private var userProfileService: UserProfileService
    @State private var showingMovieDetail = false
    @State private var selectedUserMovie: UserMovie?
    @State private var showingRefreshConfirmation = false
    @State private var showingProfileMenu = false
    @State private var showingProfileSheet = false
    @State private var showingAISearching = false
    @Namespace private var heroAnimation

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            // AnimatedMeshGradient in safe area
            VStack {
                ZStack {
                    AnimatedMeshGradient()
                        .opacity(0.1)
                        .frame(height: 170)

                    // Subtle shadow overlay at bottom for smooth integration
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .black.opacity(0.1),
                                        .black.opacity(0.2),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 40)
                    }
                }
                .ignoresSafeArea(edges: .top)

                Spacer()
            }

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

                // AI Search Section fixé en bas
                VStack(spacing: 0) {
                    Divider()
                        .background(.quaternary)

                    aiSearchSection
                        .frame(height: 134)
                        .padding(.horizontal)
                        .padding(.vertical, 16)
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
                            .padding(.bottom, 140) // Au-dessus de AI Search
                    }
                }
            }
        }
        .overlay(toastOverlay)
        .sheet(isPresented: $showingProfileSheet) {
            ProfileSheet(userProfileService: userProfileService)
        }
        .onAppear {
            // Initialize ViewModel with UserProfileService
            Task {
                await viewModel.initializeData(userProfileService: userProfileService)
            }
        }
        .confirmationDialog("Refresh Recommendations", isPresented: $showingRefreshConfirmation) {
            Button("Generate New Movies") {
                Task {
                    await viewModel.refreshRecommendations(userProfileService: userProfileService)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Generate 5 new movie recommendations?")
        }

        .sheet(item: $selectedUserMovie, onDismiss: {
            selectedUserMovie = nil
        }) { userMovie in
            MovieDetailSheet(
                movie: userMovie.movie,
                userMovie: userMovie,
                namespace: heroAnimation,
                isPresented: .constant(true),
                source: .suggestion,
                onAddToWatchlist: {
                    Task {
                        await viewModel.addToWatchlist(userMovie.movie)
                    }
                    selectedUserMovie = nil
                }
            )
        }
        .sheet(isPresented: $viewModel.showSearchResult) {
            if let searchResult = viewModel.searchResult {
                MovieDetailSheet(
                    movie: searchResult,
                    userMovie: nil,
                    namespace: heroAnimation,
                    isPresented: $viewModel.showSearchResult,
                    source: .aiSearch,
                    onAddToWatchlist: {
                        Task {
                            await viewModel.addToWatchlist(searchResult)
                        }
                        viewModel.showSearchResult = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showingAISearching) {
            AISearchingView(
                message: "Searching for the perfect movie...",
                isSearchQuery: true,
                onCancel: {
                    showingAISearching = false
                    viewModel.isSearching = false
                }
            )
        }
        .fullScreenCover(isPresented: $viewModel.isGeneratingRecommendations) {
            AISearchingView(
                message: "Generating your daily recommendations...",
                isSearchQuery: false,
                onCancel: nil
            )
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.welcomeMessage(userProfileService: userProfileService))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.primaryGradient)
                        .opacity(1)
                        .animation(DesignSystem.easeInOutAnimation.delay(0.2), value: true)

                    Text(viewModel.welcomeSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(1)
                        .animation(DesignSystem.easeInOutAnimation.delay(0.4), value: true)
                }

                Spacer()

                Button(action: { showingProfileSheet = true }) {
                    ProfilePictureView(
                        size: 50,
                        profilePictureURL: userProfileService.profilePictureURL,
                        displayName: userProfileService.displayName.isEmpty ? viewModel.userName : userProfileService.displayName,
                        showEditIcon: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.extraLargeRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.extraLargeRadius)
                        .stroke(DesignSystem.subtleGradient, lineWidth: 1)
                        .blur(radius: 0.5)
                )
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 20,
                topTrailingRadius: 0
            )
        )
        .subtleShadow()
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Picks")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.primaryGradient)

                Spacer()
            }

            if viewModel.isGeneratingRecommendations {
                // Generation progress view
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.primaryCyan))

                    Text("Generating your daily picks...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                                .stroke(DesignSystem.subtleGradient, lineWidth: 1)
                                .blur(radius: 0.5)
                        )
                )
                .subtleShadow()
            } else if viewModel.currentRecommendations.isEmpty {
                // Empty state
                emptyRecommendationsState
            } else {
                // Recommendations scroll view
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.currentRecommendations, id: \.id) { userMovie in
                            MovieCardView(
                                movie: userMovie.movie,
                                namespace: heroAnimation,
                                onPosterTap: {
                                    print("🎬 Tapping on recommendation movie: \(userMovie.movie.title)")
                                    print("   - userId: \(userMovie.userId)")
                                    print("   - isCurrentPick: \(userMovie.isCurrentPick)")
                                    print("   - isInHistory: \(userMovie.isInHistory)")
                                    selectedUserMovie = userMovie
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

    // MARK: - AI Search Section

    private var aiSearchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("AI Movie Search")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.primaryGradient)

                Spacer()
            }

            // AI Search Bar
            AISearchBar(
                searchText: $viewModel.searchText,
                placeholder: "Ask AI to find a movie...",
                onSearch: {
                    Task {
                        await viewModel.performAISearch(userProfileService: userProfileService)
                        if viewModel.isSearching {
                            showingAISearching = true
                        }
                    }
                },
                isSearching: viewModel.isSearching,
                validationMessage: viewModel.searchValidationMessage
            )
        }
    }

    // MARK: - Empty States

    private var emptyRecommendationsState: some View {
        VStack(spacing: 16) {
            ZStack {
                Image(systemName: "popcorn")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignSystem.primaryGradient)
                    .scaleEffect(1.0)
                    .animation(
                        .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )

                // Subtle sparkles
                HStack(spacing: 8) {
                    SparkleAnimation(delay: 0.0)
                    SparkleAnimation(delay: 0.3)
                    SparkleAnimation(delay: 0.6)
                }
                .offset(x: 30, y: -20)
            }

            Text("No recommendations yet")
                .font(.headline)
                .foregroundStyle(DesignSystem.primaryGradient)

            Text("We're working on finding the perfect movies for you!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                        .stroke(DesignSystem.subtleGradient, lineWidth: 1)
                        .blur(radius: 0.5)
                )
        )
        .subtleShadow()
    }

    // MARK: - Floating Refresh Button

    private var floatingRefreshButton: some View {
        Button(action: {
            showingRefreshConfirmation = true
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(DesignSystem.primaryGradient)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(.ultraThickMaterial)
                        .overlay(
                            Circle()
                                .stroke(DesignSystem.primaryGradient, lineWidth: 1)
                                .blur(radius: 0.5)
                        )
                )
                .primaryShadow()
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
                            .foregroundStyle(DesignSystem.primaryGradient)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()

                        // Dismiss button
                        Button("OK") {
                            viewModel.errorMessage = nil
                        }
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.primaryGradient)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                                    .stroke(DesignSystem.subtleGradient, lineWidth: 1)
                                    .blur(radius: 0.5)
                            )
                    )
                    .subtleShadow()
                    .padding(.horizontal)

                    Spacer()
                }
            }
        }
    }

    // Note: AIThinkingIndicator replaced with inline ProgressView in recommendationsSection
}

#Preview {
    let userProfileService = UserProfileService()
    let homeViewModel = HomeViewModel(
        userMovieService: UserMovieService()
    )

    return HomeView()
        .environmentObject(AppStateManager(userProfileService: userProfileService))
        .environmentObject(homeViewModel)
        .environmentObject(userProfileService)
}
