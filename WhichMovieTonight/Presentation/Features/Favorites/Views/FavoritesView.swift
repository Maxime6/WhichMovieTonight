//
//  FavoritesView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var showingMovieDetail = false
    @State private var selectedUserMovie: UserMovie?
    @Namespace private var heroAnimation

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main Content
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.hasFavorites {
                    emptyStateView
                } else if !viewModel.hasFilteredFavorites {
                    emptySearchView
                } else {
                    favoritesGridView
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(DesignSystem.primaryCyan.opacity(0.1), for: .navigationBar)
            .searchable(text: $viewModel.searchText, prompt: "Search movies...")
            .refreshable {
                await viewModel.refreshFavorites()
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
                        Task {
                            await viewModel.toggleWatchlist(userMovie)
                        }
                        selectedUserMovie = nil
                    }
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.primaryCyan))

            Text("Loading your favorites...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "heart",
            title: "No Favorites Yet",
            subtitle: "Start building your collection by exploring AI recommendations",
            actionTitle: "Get Recommendations",
            actionIcon: "star.fill",
            onAction: {
                // Navigate to home tab
                // This would need to be handled by the parent view
            }
        )
    }

    // MARK: - Empty Search View

    private var emptySearchView: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No movies found",
            subtitle: "Try adjusting your search terms",
            showSparkles: false
        )
    }

    // MARK: - Favorites Grid View

    private var favoritesGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16),
            ], spacing: 16) {
                ForEach(viewModel.sortedAndFilteredFavorites) { userMovie in
                    FavoriteMovieCard(
                        userMovie: userMovie,
                        namespace: heroAnimation,
                        onTap: {
                            selectedUserMovie = userMovie
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
    FavoritesView()
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
