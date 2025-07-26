//
//  MovieDetailSheet.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct MovieDetailSheet: View {
    let movie: Movie
    let userMovie: UserMovie?
    let namespace: Namespace.ID
    @Binding var isPresented: Bool
    let source: MovieDetailSource
    let onAddToWatchlist: (() -> Void)?
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    // Hero poster section
                    heroSection

                    // Movie details
                    movieDetailsSection
                }
            }
            .background(Color(.systemBackground))
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            if let url = movie.posterURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 240)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        posterPlaceholder
                    @unknown default:
                        posterPlaceholder
                    }
                }
            } else {
                posterPlaceholder
            }

            quickInfoRow
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
            .fill(.gray.opacity(0.2))
            .frame(width: 160, height: 240)
            .overlay {
                Image(systemName: "film")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(DesignSystem.primaryGradient)
            }
            .subtleShadow()
    }

    private var movieDetailsSection: some View {
        VStack(spacing: 24) {
            MovieInteractionButtons(movie: movie, userMovie: userMovie)

            genresSection

            synopsisSection

            castCrewSection

            streamingSection

            // Add to Watchlist button at the bottom
            addToWatchlistButton
        }
        .padding()
    }

    private var quickInfoRow: some View {
        VStack(spacing: 10) {
            Text(movie.title)
                .font(.title.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 20) {
                if let imdbRating = movie.imdbRating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text(imdbRating)
                    }
                }

                if let year = movie.year {
                    VStack(spacing: 4) {
                        Text(year)
                    }
                }

                if let runtime = movie.runtime {
                    VStack(spacing: 4) {
                        Text(runtime)
                    }
                }

                if let rated = movie.rated {
                    VStack(spacing: 4) {
                        Text(rated)
                    }
                }
            }
            .foregroundStyle(.primary)

            HStack(spacing: 8) {
                ForEach(movie.genres, id: \.self) { genre in
                    Text(genre)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Genres")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(movie.genres, id: \.self) { genre in
                    Text(genre)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial)
                        .cornerRadius(DesignSystem.mediumRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                                .stroke(DesignSystem.subtleGradient, lineWidth: 1)
                                .blur(radius: 0.5)
                        )
                }
            }
        }
    }

    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Synopsis")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            if let overview = movie.overview {
                Text(overview)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            } else {
                Text("Aucun synopsis disponible")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
    }

    private var castCrewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let director = movie.director {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Réalisateur")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(director)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            if let actors = movie.actors {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Acteurs principaux")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(actors)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
            }
        }
    }

    private var streamingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Disponible sur")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(movie.streamingPlatforms, id: \.self) { platform in
                    Text(platform)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(DesignSystem.primaryCyan.opacity(0.1))
                        .foregroundColor(DesignSystem.primaryCyan)
                        .cornerRadius(DesignSystem.smallRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                                .stroke(DesignSystem.primaryCyan.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }

    private var addToWatchlistButton: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.vertical)

            if let userMovie = userMovie, userMovie.isToWatch {
                // Remove from watchlist state
                Button(action: {
                    onAddToWatchlist?()
                }) {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("Remove from Watchlist")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            } else {
                // Add to watchlist state
                Button(action: {
                    onAddToWatchlist?()
                }) {
                    HStack {
                        Image(systemName: "bookmark")
                        Text("Add to Watchlist")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(DesignSystem.primaryGradient)
                    .cornerRadius(DesignSystem.mediumRadius)
                    .primaryShadow()
                }
            }

            Text(userMovie?.isToWatch == true ? "This movie will be removed from your watchlist" : "This movie will be added to your watchlist")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return MovieDetailSheet(
        movie: Movie.preview,
        userMovie: UserMovie(userId: "preview", movie: Movie.preview, isLiked: true, isFavorite: true),
        namespace: namespace,
        isPresented: .constant(true),
        source: .suggestion,
        onAddToWatchlist: {
            print("Added to watchlist!")
        }
    )
}
