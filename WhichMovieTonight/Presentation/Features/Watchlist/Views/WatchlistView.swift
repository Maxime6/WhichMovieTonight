//
//  WatchlistView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var showingMovieDetail = false
    @State private var selectedUserMovie: UserMovie?
    @Namespace private var heroAnimation

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Tags Row
                if viewModel.hasMovies {
                    FilterTagsRow(
                        selectedTag: viewModel.selectedTag,
                        onTagSelected: { tag in
                            viewModel.selectTag(tag)
                        }
                    )
                    .padding(.vertical, 8)
                }

                // Main Content
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.hasMovies {
                    emptyStateView
                } else if !viewModel.hasFilteredMovies {
                    emptyFilterView
                } else {
                    moviesGridView
                }
            }
            .navigationTitle("My Collection")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(DesignSystem.primaryCyan.opacity(0.1), for: .navigationBar)
            .searchable(text: $viewModel.searchText, prompt: "Search movies...")
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
                                await viewModel.addToWatchlist(userMovie)
                            }
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

            Text("Loading your movies...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "film.stack",
            title: "No Movies Yet",
            subtitle: "Your movie collection will appear here as you interact with recommendations",
            actionTitle: "Get Recommendations",
            actionIcon: "star.fill",
            onAction: {
                // Navigate to home tab
                // This would need to be handled by the parent view
            }
        )
    }

    // MARK: - Empty Filter View

    private var emptyFilterView: some View {
        EmptyStateView(
            icon: viewModel.searchText.isEmpty ? "line.3.horizontal.decrease.circle" : "magnifyingglass",
            title: viewModel.searchText.isEmpty ? "No \(viewModel.selectedTag.displayName) Movies" : "No search results within '\(viewModel.selectedTag.displayName)'",
            subtitle: viewModel.searchText.isEmpty ? "Try selecting a different filter or interact with more movies" : "Try adjusting your search terms",
            showSparkles: false
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

// MARK: - Watchlist Movie Card

struct WatchlistMovieCard: View {
    let userMovie: UserMovie
    let namespace: Namespace.ID
    let onTap: () -> Void
    let onLikeToggle: () -> Void
    let onDislikeToggle: () -> Void
    let onFavoriteToggle: () -> Void
    let onMarkSeen: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Movie Poster
            AsyncImage(url: userMovie.movie.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Image(systemName: "film")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
            }
            .frame(height: 240)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 12
                )
            )
            .clipped()
            .matchedGeometryEffect(id: userMovie.movie.id, in: namespace)
            .onTapGesture {
                onTap()
            }

            // Movie Info & Actions
            VStack(spacing: 8) {
                // Title & Year
                VStack(alignment: .leading, spacing: 4) {
                    Text(userMovie.movie.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text(userMovie.movie.formattedReleaseYear)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Primary Tag Badge
                if userMovie.primaryTag != .all {
                    HStack {
                        Image(systemName: userMovie.primaryTag.icon)
                            .font(.caption2)
                        Text(userMovie.primaryTag.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(userMovie.primaryTag.color.opacity(0.2))
                    )
                    .foregroundColor(userMovie.primaryTag.color)
                }

                // Action Buttons
                HStack(spacing: 12) {
                    // Like/Dislike
                    HStack(spacing: 8) {
                        Button(action: onLikeToggle) {
                            Image(systemName: userMovie.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.caption)
                                .foregroundColor(userMovie.isLiked ? .green : .secondary)
                        }

                        Button(action: onDislikeToggle) {
                            Image(systemName: userMovie.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                .font(.caption)
                                .foregroundColor(userMovie.isDisliked ? .red : .secondary)
                        }
                    }

                    Spacer()

                    // Favorite
                    Button(action: onFavoriteToggle) {
                        Image(systemName: userMovie.isFavorite ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundColor(userMovie.isFavorite ? .pink : .secondary)
                    }

                    // Seen
                    Button(action: onMarkSeen) {
                        Image(systemName: userMovie.isSeen ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(userMovie.isSeen ? .purple : .secondary)
                    }
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 0
                )
            )
        }
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
}

#Preview {
    WatchlistView()
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
