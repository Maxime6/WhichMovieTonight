//
//  MovieInteractionButtons.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct MovieInteractionButtons: View {
    let movie: Movie

    // MARK: - Native SwiftUI State

    @State private var likeStatus: MovieLikeStatus = .none
    @State private var isFavorite: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // MARK: - Services

    private let movieInteractionService = MovieInteractionService()

    // MARK: - Initializer

    init(movie: Movie) {
        self.movie = movie
    }

    // MARK: - Computed Properties

    private var likeIcon: String {
        switch likeStatus {
        case .liked: return "hand.thumbsup.fill"
        case .disliked: return "hand.thumbsup"
        case .none: return "hand.thumbsup"
        }
    }

    private var dislikeIcon: String {
        switch likeStatus {
        case .liked: return "hand.thumbsdown"
        case .disliked: return "hand.thumbsdown.fill"
        case .none: return "hand.thumbsdown"
        }
    }

    private var favoriteIcon: String {
        isFavorite ? "heart.fill" : "heart"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Like button
            Button {
                Task {
                    await toggleLike()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: likeIcon)
                        .font(.title3)
                        .foregroundColor(likeStatus == .liked ? .blue : .gray)

                    Text("J'aime")
                        .font(.caption2)
                        .foregroundColor(likeStatus == .liked ? .blue : .gray)
                }
            }
            .disabled(isLoading)

            // Dislike button
            Button {
                Task {
                    await toggleDislike()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: dislikeIcon)
                        .font(.title3)
                        .foregroundColor(likeStatus == .disliked ? .red : .gray)

                    Text("Non")
                        .font(.caption2)
                        .foregroundColor(likeStatus == .disliked ? .red : .gray)
                }
            }
            .disabled(isLoading)

            // Favorite button
            Button {
                Task {
                    await toggleFavorite()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: favoriteIcon)
                        .font(.title3)
                        .foregroundColor(isFavorite ? .red : .gray)

                    Text("Favoris")
                        .font(.caption2)
                        .foregroundColor(isFavorite ? .red : .gray)
                }
            }
            .disabled(isLoading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .task {
            await loadInteraction()
        }
        .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .opacity(isLoading ? 0.6 : 1.0)
    }

    // MARK: - Methods

    private func loadInteraction() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let interaction = try await movieInteractionService.getMovieInteraction(for: movie) {
                likeStatus = interaction.likeStatus
                isFavorite = interaction.isFavorite
            }
        } catch {
            errorMessage = "Erreur lors du chargement des interactions: \(error.localizedDescription)"
        }
    }

    private func toggleLike() async {
        isLoading = true
        defer { isLoading = false }

        do {
            likeStatus = try await movieInteractionService.toggleLike(for: movie)
        } catch {
            errorMessage = "Erreur lors de la mise à jour du like: \(error.localizedDescription)"
        }
    }

    private func toggleDislike() async {
        isLoading = true
        defer { isLoading = false }

        do {
            likeStatus = try await movieInteractionService.toggleDislike(for: movie)
        } catch {
            errorMessage = "Erreur lors de la mise à jour du dislike: \(error.localizedDescription)"
        }
    }

    private func toggleFavorite() async {
        isLoading = true
        defer { isLoading = false }

        do {
            isFavorite = try await movieInteractionService.toggleFavorite(for: movie)
        } catch {
            errorMessage = "Erreur lors de la mise à jour des favoris: \(error.localizedDescription)"
        }
    }
}

#Preview {
    MovieInteractionButtons(movie: Movie.preview)
        .padding()
}
