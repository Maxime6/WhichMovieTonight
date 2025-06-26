//
//  MovieInteractionViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import FirebaseAuth
import Foundation

@MainActor
class MovieInteractionViewModel: ObservableObject {
    @Published var currentInteraction: UserMovieInteraction?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    // MARK: - Public Methods

    func loadInteraction(for movie: Movie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            currentInteraction = try await firestoreService.getMovieInteraction(
                movieId: movie.uniqueId,
                for: userId
            )
        } catch {
            errorMessage = "Erreur lors du chargement de l'interaction: \(error.localizedDescription)"
            print("❌ Erreur lors du chargement de l'interaction: \(error)")
        }
    }

    func toggleLike(for movie: Movie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let newLikeStatus = try await firestoreService.toggleMovieLike(movie: movie, for: userId)

            // Update current interaction
            if currentInteraction == nil {
                currentInteraction = UserMovieInteraction(
                    movieId: movie.uniqueId,
                    movieTitle: movie.title,
                    posterURL: movie.posterURL?.absoluteString
                )
            }
            currentInteraction?.likeStatus = newLikeStatus
            currentInteraction?.updatedAt = Date()

        } catch {
            errorMessage = "Erreur lors de la mise à jour du like: \(error.localizedDescription)"
            print("❌ Erreur lors du toggle like: \(error)")
        }
    }

    func toggleDislike(for movie: Movie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let newLikeStatus = try await firestoreService.toggleMovieDislike(movie: movie, for: userId)

            // Update current interaction
            if currentInteraction == nil {
                currentInteraction = UserMovieInteraction(
                    movieId: movie.uniqueId,
                    movieTitle: movie.title,
                    posterURL: movie.posterURL?.absoluteString
                )
            }
            currentInteraction?.likeStatus = newLikeStatus
            currentInteraction?.updatedAt = Date()

        } catch {
            errorMessage = "Erreur lors de la mise à jour du dislike: \(error.localizedDescription)"
            print("❌ Erreur lors du toggle dislike: \(error)")
        }
    }

    func toggleFavorite(for movie: Movie) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let newFavoriteStatus = try await firestoreService.toggleMovieFavorite(movie: movie, for: userId)

            // Update current interaction
            if currentInteraction == nil {
                currentInteraction = UserMovieInteraction(
                    movieId: movie.uniqueId,
                    movieTitle: movie.title,
                    posterURL: movie.posterURL?.absoluteString
                )
            }
            currentInteraction?.isFavorite = newFavoriteStatus
            currentInteraction?.updatedAt = Date()

        } catch {
            errorMessage = "Erreur lors de la mise à jour des favoris: \(error.localizedDescription)"
            print("❌ Erreur lors du toggle favorite: \(error)")
        }
    }

    // MARK: - Computed Properties

    var likeStatus: MovieLikeStatus {
        return currentInteraction?.likeStatus ?? .none
    }

    var isFavorite: Bool {
        return currentInteraction?.isFavorite ?? false
    }

    var likeIcon: String {
        return likeStatus == .liked ? "hand.thumbsup.fill" : "hand.thumbsup"
    }

    var dislikeIcon: String {
        return likeStatus == .disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown"
    }

    var favoriteIcon: String {
        return isFavorite ? "heart.fill" : "heart"
    }
}
