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
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text("Personalized Suggestions")
                .font(.title2.bold())

            Text("AI-powered movie recommendations based on your preferences will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    WatchlistView()
}
