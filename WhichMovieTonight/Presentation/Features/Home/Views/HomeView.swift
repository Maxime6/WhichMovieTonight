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
    @State private var showingDeleteConfirmation = false
    @State private var showingProfileMenu = false
    @State private var showingProfileSheet = false
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

                // Tonight's Pick fixé en bas
                VStack(spacing: 0) {
                    Divider()
                        .background(.quaternary)

                    selectedMovieSection
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
                            .padding(.bottom, 140) // Au-dessus de Tonight's Pick
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
        .confirmationDialog("Remove from Tonight's Pick", isPresented: $showingDeleteConfirmation) {
            Button("Remove", role: .destructive) {
                Task {
                    await viewModel.deselectMovieForTonight()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove this movie from tonight's selection?")
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
                onSelectForTonight: {
                    Task {
                        await viewModel.selectMovieForTonight(userMovie.movie)
                    }
                    selectedUserMovie = nil
                }
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

    // MARK: - Selected Movie Section

    private var selectedMovieSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tonight's Pick")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.primaryGradient)

                Spacer()
            }

            // CONTENEUR AVEC HAUTEUR FIXE pour l'alignement
            VStack {
                if let movieForTonight = viewModel.selectedMovieForTonight {
                    SelectedMovieCard(
                        movie: movieForTonight,
                        onTap: {
                            print("🎬 Tapping on selected movie for tonight: \(movieForTonight.title)")
                            print("   - selectedMovieForTonightUserMovie: \(viewModel.selectedMovieForTonightUserMovie?.movie.title ?? "nil")")
                            print("   - userId: \(viewModel.selectedMovieForTonightUserMovie?.userId ?? "nil")")
                            selectedUserMovie = viewModel.selectedMovieForTonightUserMovie
                        },
                        onDeselect: {
                            showingDeleteConfirmation = true
                        }
                    )
                } else {
                    emptySelectedMovieState
                }
            }
            .frame(height: 115)
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

    private var emptySelectedMovieState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tv")
                .font(.system(size: 24))
                .foregroundStyle(DesignSystem.primaryGradient)

            Text("No movie selected for tonight")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Choose one from your daily picks above!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 102)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
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
