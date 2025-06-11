//
//  WatchlistView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import FirebaseAuth
import SwiftUI

struct WatchlistView: View {
    @State private var selectedTab = 0
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var showingMovieDetail = false
    @State private var selectedMovie: Movie?
    @State private var showingSelectAlert = false
    @Namespace private var heroAnimation

    var body: some View {
        NavigationView {
            VStack {
                // Tab selector
                Picker("Watchlist Options", selection: $selectedTab) {
                    Text("J'aime").tag(0)
                    Text("Favoris").tag(1)
                    Text("Suggestions").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    likedMoviesView
                        .tag(0)

                    favoritesView
                        .tag(1)

                    suggestionsView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Watchlist")
            .refreshable {
                await viewModel.refreshData()
            }
            .task {
                await viewModel.loadUserInteractions()
            }
        }
        .sheet(isPresented: $showingMovieDetail) {
            if let movie = selectedMovie {
                MovieDetailSheet(
                    movie: movie,
                    namespace: heroAnimation,
                    isPresented: $showingMovieDetail,
                    source: .suggestion,
                    onSelectForTonight: {
                        selectMovieForTonight(movie)
                    }
                )
            }
        }
        .alert("Film sélectionné", isPresented: $showingSelectAlert) {
            Button("OK") {}
        } message: {
            Text("Ce film a été sélectionné pour ce soir !")
        }
    }

    private func selectMovieForTonight(_: Movie) {
        // Cette fonction sera appelée quand l'utilisateur veut sélectionner un film pour ce soir
        // Pour l'instant, on affiche juste une alerte
        showingSelectAlert = true
        showingMovieDetail = false
    }

    private var likedMoviesView: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("Chargement des films aimés...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.likedMovies.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Films Aimés")
                        .font(.title2.bold())

                    Text("Les films que vous aimez apparaîtront ici")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.likedMovies) { interaction in
                            FavoriteMovieCard(interaction: interaction)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var favoritesView: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("Chargement des favoris...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.favoriteMovies.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("Films Favoris")
                        .font(.title2.bold())

                    Text("Les films que vous marquez comme favoris apparaîtront ici")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.favoriteMovies) { interaction in
                            FavoriteMovieCard(interaction: interaction)
                        }
                    }
                    .padding()
                }
            }
        }
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private var suggestionsView: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("Chargement des suggestions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.lastSuggestions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)

                    Text("Dernières Suggestions")
                        .font(.title2.bold())

                    Text("Les dernières suggestions de l'IA apparaîtront ici une fois que vous aurez fait des recherches")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 16) {
                        ForEach(viewModel.lastSuggestions) { movie in
                            SuggestionCard(movie: movie) {
                                selectedMovie = movie
                                showingMovieDetail = true
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct SuggestionCard: View {
    let movie: Movie
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Poster du film
                AsyncImage(url: movie.posterURL) { image in
                    image
                        .resizable()
                        .aspectRatio(2 / 3, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(2 / 3, contentMode: .fill)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.title2)
                        )
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Titre du film
                Text(movie.title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WatchlistView()
}
