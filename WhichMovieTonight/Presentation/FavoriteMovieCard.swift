//
//  FavoriteMovieCard.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct FavoriteMovieCard: View {
    let interaction: UserMovieInteraction

    var body: some View {
        HStack(spacing: 12) {
            // Movie poster
            AsyncImage(url: URL(string: interaction.posterURL ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 90)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                case .failure:
                    posterPlaceholder
                @unknown default:
                    posterPlaceholder
                }
            }

            // Movie info
            VStack(alignment: .leading, spacing: 4) {
                Text(interaction.movieTitle)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // Favorite indicator
                    if interaction.isFavorite {
                        Label("Favori", systemImage: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // Like status
                    if interaction.likeStatus == .liked {
                        Label("J'aime", systemImage: "hand.thumbsup.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else if interaction.likeStatus == .disliked {
                        Label("J'aime pas", systemImage: "hand.thumbsdown.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text("Ajouté le \(interaction.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.gray.opacity(0.2))
            .frame(width: 60, height: 90)
            .overlay {
                Image(systemName: "film")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    FavoriteMovieCard(
        interaction: UserMovieInteraction(
            movieId: "tt1375666",
            movieTitle: "Inception",
            posterURL: "https://picsum.photos/300/450",
            likeStatus: .liked,
            isFavorite: true
        )
    )
    .padding()
}
