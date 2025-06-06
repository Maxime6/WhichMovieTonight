//
//  HomeView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import FirebaseAuth
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var authViewModel: AuthenticationViewModel

    @State private var actorsInput: String = ""
    @State private var genresSelected: [MovieGenre] = []
    @State private var showingProfileMenu = false
    @State private var showingDeleteAlert = false
    @State private var showingMovieDetail = false
    @State private var movieDetailSource: MovieDetailSource = .currentMovie
    @State private var selectedSuggestionMovie: Movie?
    @Namespace private var heroAnimation
    @State var counter: Int = 0
    @State var origin: CGPoint = .zero

    init() {
        _authViewModel = StateObject(wrappedValue: AuthenticationViewModel())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView

                Spacer()

                if let movie = viewModel.selectedMovie {
                    VStack(spacing: 10) {
                        Text("Film du soir")
                            .font(.title2.bold())
                            .foregroundColor(.primary)

                        movieCardView(movie: movie)

                        Button("Changer de film") {
                            viewModel.showGenreSelection = true
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                } else {
                    emptyStateView
                }

                Spacer()

                // Last suggestions at bottom
                LastSuggestionsView(suggestions: viewModel.lastSuggestions) { movie in
                    selectedSuggestionMovie = movie
                    movieDetailSource = .suggestion
                    showingMovieDetail = true
                    triggerHaptic()
                }
            }
            .padding()
            .blur(radius: viewModel.isLoading ? 10 : 0)
            .onAppear {
                if authViewModel.appStateManager == nil {
                    authViewModel.appStateManager = appStateManager
                }
                viewModel.setAuthViewModel(authViewModel)
                viewModel.fetchUser()
            }

            if viewModel.isLoading {
                AISearchingView()
            }
        }
        .animation(.easeInOut, value: viewModel.isLoading)
        .overlay(
            Group {
                if let message = viewModel.toastMessage, viewModel.showToast {
                    ToastView(message: message, icon: "checkmark.seal.fill", onDismiss: { viewModel.toastMessage = nil }, isShowing: $viewModel.showToast)
                }
            }, alignment: .bottom
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
        .fullScreenCover(isPresented: $viewModel.showMovieConfirmation) {
            if let movie = viewModel.suggestedMovie {
                NavigationView {
                    MovieConfirmationView(
                        movie: movie,
                        onConfirm: {
                            viewModel.confirmMovie()
                        },
                        onSearchAgain: {
                            viewModel.searchAgain()
                        }
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showGenreSelection) {
            NavigationView {
                GenreActorSelectionView(
                    selectedGenres: $viewModel.selectedGenres,
                    actorsInput: $actorsInput,
                    onStartSearch: {
                        Task {
                            try await viewModel.findTonightMovie()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingMovieDetail) {
            let movieToShow: Movie? = {
                switch movieDetailSource {
                case .currentMovie:
                    return viewModel.selectedMovie
                case .suggestion:
                    return selectedSuggestionMovie
                }
            }()

            if let movie = movieToShow {
                MovieDetailSheet(
                    movie: movie,
                    namespace: heroAnimation,
                    isPresented: $showingMovieDetail,
                    source: movieDetailSource,
                    onSelectForTonight: movieDetailSource == .suggestion ? {
                        selectMovieForTonight(movie)
                    } : nil
                )
            }
        }
    }

    // MARK: - Movie Card View

    @ViewBuilder
    private func movieCardView(movie: Movie) -> some View {
        VStack(spacing: 16) {
            // Movie poster (tappable)
            Button(action: {
                movieDetailSource = .currentMovie
                showingMovieDetail = true
                triggerHaptic()
            }) {
                if let url = movie.posterURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 200, height: 300)
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .primary.opacity(0.2), radius: 10)
                                .onPressingChanged { point in
                                    if let point {
                                        origin = point
                                        counter += 1
                                    }
                                }
                                .modifier(RippleEffect(at: origin, trigger: counter))
                        case .failure:
                            posterPlaceholder
                        @unknown default:
                            posterPlaceholder
                        }
                    }
                    .matchedGeometryEffect(id: "moviePoster-\(movie.id)", in: heroAnimation, isSource: !showingMovieDetail)
                } else {
                    posterPlaceholder
                        .matchedGeometryEffect(id: "moviePoster-placeholder", in: heroAnimation, isSource: !showingMovieDetail)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Movie title
            Text(movie.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // Movie info row (Date de sortie, IMDB rating, Durée)
            HStack(spacing: 20) {
                if let year = movie.year {
                    VStack(spacing: 4) {
                        Text(year)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Date de sortie")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let imdbRating = movie.imdbRating {
                    VStack(spacing: 4) {
                        Text(imdbRating)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("IMDB rating")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let runtime = movie.runtime {
                    VStack(spacing: 4) {
                        Text(runtime)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Durée")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray5).opacity(0.5))
        .cornerRadius(20)
        .onAppear {
            triggerHaptic()
        }
    }

    @ViewBuilder
    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.gray.opacity(0.2))
            .frame(width: 200, height: 300)
            .overlay {
                Image(systemName: "film")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.secondary)
            }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "movieclapper")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundStyle(.ultraThickMaterial)

            Text("No movie selected yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text("Tap below to let AI find the perfect movie for tonight !")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            AIActionButton(title: "Which Movie tonight ?") {
                viewModel.showGenreSelection = true
            }
        }
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 10)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Hi \(viewModel.userName),")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("Phrase d'introduction")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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

    private func selectMovieForTonight(_ movie: Movie) {
        viewModel.selectedMovie = movie

        if let userId = Auth.auth().currentUser?.uid {
            Task {
                do {
                    try await FirestoreService().saveSelectedMovie(movie, for: userId)
                } catch {
                    print("Erreur lors de la sauvegarde: \(error)")
                }
            }
        }

        showingMovieDetail = false
        triggerHaptic()
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppStateManager())
}

struct WaveRenderer: TextRenderer {
    var strength: Double
    var frequency: Double
    var animatableData: Double {
        get { strength }
        set { strength = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                for (index, glyph) in run.enumerated() {
                    let yOffset = strength * sin(Double(index) * frequency)
                    var copy = context
                    copy.translateBy(x: 0, y: yOffset)
                    copy.draw(glyph, options: .disablesSubpixelQuantization)
                }
            }
        }
    }
}
