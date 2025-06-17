//
//  MovieInteractionButtons.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct MovieInteractionButtons: View {
    let movie: Movie
    @StateObject private var viewModel = MovieInteractionViewModel()

    var body: some View {
        HStack(spacing: 24) {
            // Like button
            Button {
                Task {
                    await viewModel.toggleLike(for: movie)
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.likeIcon)
                        .font(.title2)
                        .foregroundColor(viewModel.likeStatus == .liked ? .blue : .gray)

                    Text("J'aime")
                        .font(.caption)
                        .foregroundColor(viewModel.likeStatus == .liked ? .blue : .gray)
                }
            }
            .disabled(viewModel.isLoading)

            // Dislike button
            Button {
                Task {
                    await viewModel.toggleDislike(for: movie)
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.dislikeIcon)
                        .font(.title2)
                        .foregroundColor(viewModel.likeStatus == .disliked ? .red : .gray)

                    Text("J'aime pas")
                        .font(.caption)
                        .foregroundColor(viewModel.likeStatus == .disliked ? .red : .gray)
                }
            }
            .disabled(viewModel.isLoading)

            // Favorite button
            Button {
                Task {
                    await viewModel.toggleFavorite(for: movie)
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.favoriteIcon)
                        .font(.title2)
                        .foregroundColor(viewModel.isFavorite ? .red : .gray)

                    Text("Favoris")
                        .font(.caption)
                        .foregroundColor(viewModel.isFavorite ? .red : .gray)
                }
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .task {
            await viewModel.loadInteraction(for: movie)
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
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
    }
}

#Preview {
    MovieInteractionButtons(movie: Movie.preview)
        .padding()
}
