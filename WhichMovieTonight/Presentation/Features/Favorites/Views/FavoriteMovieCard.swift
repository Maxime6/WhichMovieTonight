//
//  FavoriteMovieCard.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct FavoriteMovieCard: View {
    let userMovie: UserMovie
    let namespace: Namespace.ID
    let onTap: () -> Void

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

            // Movie Info Section
            VStack(spacing: 8) {
                // Title & Year with Rating
                VStack(alignment: .leading, spacing: 4) {
                    Text(userMovie.movie.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    HStack {
                        Text(userMovie.movie.formattedReleaseYear)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        // Rating
                        if let rating = userMovie.movie.imdbRating, !rating.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                                Text(rating)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }

                // Date Added to Favorites
                if let favoriteDate = userMovie.favoriteAt {
                    Text("Added \(favoriteDate.formatted(.dateTime.month().year()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    let sampleMovie = Movie(
        title: "Inception",
        overview: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.",
        posterURL: URL(string: "https://example.com/poster.jpg"),
        releaseDate: Date(),
        genres: ["Sci-Fi", "Action", "Thriller"],
        streamingPlatforms: ["Netflix"],
        director: "Christopher Nolan",
        actors: "Leonardo DiCaprio, Joseph Gordon-Levitt",
        runtime: "148 min",
        imdbRating: "8.8",
        imdbID: "tt1375666",
        year: "2010",
        rated: "PG-13",
        awards: "4 Oscars"
    )

    var sampleUserMovie = UserMovie(
        userId: "user123",
        movie: sampleMovie,
        isFavorite: true
    )
//    sampleUserMovie.favoriteAt = Date().addingTimeInterval(-86400 * 30)  30 days ago

    FavoriteMovieCard(
        userMovie: sampleUserMovie,
        namespace: Namespace().wrappedValue,
        onTap: {}
    )
    .frame(width: 160)
    .padding()
}
