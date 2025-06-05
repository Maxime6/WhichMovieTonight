//
//  LastSuggestionsView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct LastSuggestionsView: View {
    let suggestions: [Movie]
    let onMovieSelected: (Movie) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Dernières suggestions")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(suggestions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)

            if suggestions.isEmpty {
                Text("Aucune suggestion pour le moment")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(suggestions) { movie in
                            SuggestionMovieCard(movie: movie) {
                                onMovieSelected(movie)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct SuggestionMovieCard: View {
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
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LastSuggestionsView(
        suggestions: [
            Movie.preview,
            Movie.preview,
            Movie.preview,
        ],
        onMovieSelected: { _ in }
    )
    .padding()
}
