//
//  TestMovieInteractions.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct TestMovieInteractions: View {
    let testMovie = Movie.preview
    @StateObject private var viewModel = MovieInteractionViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Test des Interactions Film")
                .font(.title.bold())

            // Movie info
            VStack {
                Text(testMovie.title)
                    .font(.headline)

                if let posterURL = testMovie.posterURL {
                    AsyncImage(url: posterURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .fill(.gray.opacity(0.2))
                    }
                    .frame(width: 120, height: 180)
                    .cornerRadius(8)
                }
            }

            // Interaction buttons
            MovieInteractionButtons(movie: testMovie)

            // Current status
            VStack(alignment: .leading, spacing: 8) {
                Text("Status actuel:")
                    .font(.headline)

                Text("Like: \(viewModel.likeStatus.rawValue)")
                Text("Favori: \(viewModel.isFavorite ? "Oui" : "Non")")

                if viewModel.isLoading {
                    ProgressView("Chargement...")
                }

                if let error = viewModel.errorMessage {
                    Text("Erreur: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .task {
            await viewModel.loadInteraction(for: testMovie)
        }
    }
}

#Preview {
    TestMovieInteractions()
}
