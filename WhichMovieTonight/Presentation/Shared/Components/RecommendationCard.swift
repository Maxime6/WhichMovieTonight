//
//  RecommendationCard.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct RecommendationCard: View {
    let movie: Movie
    let onTap: () -> Void
    let onMarkAsSeen: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 12) {
            posterView

            VStack(spacing: 8) {
                Text(movie.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                if let imdbRating = movie.imdbRating, let year = movie.year {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(imdbRating)
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        Text(year)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !movie.genres.isEmpty {
                    Text(movie.genres.prefix(2).joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)

            HStack(spacing: 12) {
                Button(action: onMarkAsSeen) {
                    Image(systemName: "eye.slash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button(action: onTap) {
                    Text("Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 160)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {}
    }

    @ViewBuilder
    private var posterView: some View {
        if let url = movie.posterURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 120, height: 180)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                case .failure:
                    posterPlaceholder

                @unknown default:
                    posterPlaceholder
                }
            }
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.gray.opacity(0.2))
            .frame(width: 120, height: 180)
            .overlay {
                Image(systemName: "film")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            RecommendationCard(
                movie: Movie.preview,
                onTap: {},
                onMarkAsSeen: {}
            )

            RecommendationCard(
                movie: Movie(
                    title: "The Dark Knight",
                    overview: "Batman fights crime in Gotham City",
                    posterURL: URL(string: "https://picsum.photos/300/450"),
                    releaseDate: Date(),
                    genres: ["Action", "Drama"],
                    streamingPlatforms: ["HBO Max"],
                    director: "Christopher Nolan",
                    actors: "Christian Bale, Heath Ledger",
                    runtime: "152 min",
                    imdbRating: "9.0",
                    imdbID: "tt0468569",
                    year: "2008",
                    rated: "PG-13",
                    awards: "Won 2 Oscars"
                ),
                onTap: {},
                onMarkAsSeen: {}
            )
        }
        .padding()
    }
}
