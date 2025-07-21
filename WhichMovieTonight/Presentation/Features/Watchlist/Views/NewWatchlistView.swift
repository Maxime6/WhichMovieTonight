//
//  NewWatchlistView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct NewWatchlistView: View {
    @StateObject private var viewModel = NewWatchlistViewModel()
    @State private var selectedUserMovie: UserMovie?
    @Namespace private var heroAnimation

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main Content
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.hasMovies {
                    emptyStateView
                } else {
                    moviesGridView
                }
            }
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(DesignSystem.primaryCyan.opacity(0.1), for: .navigationBar)
            .searchable(text: $viewModel.searchText, prompt: "Search watchlist...")
            .refreshable {
                await viewModel.refreshMovies()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortMenu
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(item: $selectedUserMovie) { userMovie in
                MovieDetailSheet(
                    movie: userMovie.movie,
                    userMovie: userMovie,
                    namespace: heroAnimation,
                    isPresented: .constant(true),
                    source: .currentMovie,
                    onAddToWatchlist: {
                        // Find UserMovie for this movie
                        if let userMovie = viewModel.userMovies.first(where: { $0.movie.id == userMovie.movie.id }) {
                            Task {
                                await viewModel.removeFromWatchlist(userMovie)
                            }
                        }
                        selectedUserMovie = nil
                    }
                )
            }
        }
        .onAppear {
            Task {
                await viewModel.loadUserMovies()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.primaryCyan))

            Text("Loading your watchlist...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "bookmark",
            title: "No Movies in Watchlist",
            subtitle: "Movies you add to your watchlist will appear here",
            actionTitle: "Search for Movies",
            actionIcon: "magnifyingglass",
            onAction: {
                // Navigate to home tab for AI search
                // This would need to be handled by the parent view
            }
        )
    }

    // MARK: - Movies Grid View

    private var moviesGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16),
            ], spacing: 16) {
                ForEach(viewModel.filteredMovies) { userMovie in
                    WatchlistMovieCard(
                        userMovie: userMovie,
                        namespace: heroAnimation,
                        onTap: {
                            selectedUserMovie = userMovie
                        },
                        onLikeToggle: {
                            Task {
                                await viewModel.toggleLike(userMovie)
                            }
                        },
                        onDislikeToggle: {
                            Task {
                                await viewModel.toggleDislike(userMovie)
                            }
                        },
                        onFavoriteToggle: {
                            Task {
                                await viewModel.toggleFavorite(userMovie)
                            }
                        },
                        onMarkSeen: {
                            Task {
                                await viewModel.markAsSeen(userMovie)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: {
                    viewModel.sortBy(option)
                }) {
                    HStack {
                        Image(systemName: option.icon)
                        Text(option.displayName)
                        if viewModel.currentSortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(viewModel.currentSortOption.displayName)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    NewWatchlistView()
}
