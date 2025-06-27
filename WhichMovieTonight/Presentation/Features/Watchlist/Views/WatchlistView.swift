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
    @State private var selectedMovie: Movie?
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
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshMovies()
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
            .sheet(isPresented: $showingMovieDetail) {
                if let movie = selectedMovie {
                    MovieDetailSheet(
                        movie: movie,
                        namespace: heroAnimation,
                        isPresented: $showingMovieDetail,
                        source: .currentMovie,
                        onSelectForTonight: {
                            // Find UserMovie for this movie
                            if let userMovie = viewModel.userMovies.first(where: { $0.movie.id == movie.id }) {
                                Task {
                                    await viewModel.selectForTonight(userMovie)
                                }
                            }
                            showingMovieDetail = false
                        }
                    )
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading your movies...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "film.stack")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Movies Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Your movie collection will appear here as you interact with recommendations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Suggestion to go to Home
            NavigationLink(destination: EmptyView()) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Get Recommendations")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Empty Filter View

    private var emptyFilterView: some View {
        VStack(spacing: 16) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No \(viewModel.selectedTag.displayName) Movies")
                .font(.headline)

            Text("Try selecting a different filter or interact with more movies")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Movies Grid View

    private var moviesGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16),
            ], spacing: 16) {
                ForEach(viewModel.getMoviesSortedByInteraction()) { userMovie in
                    WatchlistMovieCard(
                        userMovie: userMovie,
                        namespace: heroAnimation,
                        onTap: {
                            selectedMovie = userMovie.movie
                            showingMovieDetail = true
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
            .cornerRadius(12, corners: [.topLeft, .topRight])
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
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    WatchlistView()
        .environmentObject(AppStateManager())
}
