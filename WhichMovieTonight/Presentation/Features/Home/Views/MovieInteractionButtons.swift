//
//  MovieInteractionButtons.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseAuth
import SwiftUI

struct MovieInteractionButtons: View {
    let movie: Movie
    let userMovie: UserMovie? // Optional UserMovie data when available
    let onInteractionUpdate: (() -> Void)?

    @State private var isLiked = false
    @State private var isDisliked = false
    @State private var isFavorite = false
    @State private var isSeen = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let userMovieService: UserMovieServiceProtocol

    init(
        movie: Movie,
        userMovie: UserMovie? = nil,
        onInteractionUpdate: (() -> Void)? = nil,
        userMovieService: UserMovieServiceProtocol = UserMovieService()
    ) {
        self.movie = movie
        self.userMovie = userMovie
        self.onInteractionUpdate = onInteractionUpdate
        self.userMovieService = userMovieService
    }

    var body: some View {
        VStack(spacing: 16) {
            // Main Interaction Buttons
            HStack(spacing: 24) {
                // Like Button
                InteractionButton(
                    icon: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup",
                    label: "Like",
                    color: isLiked ? .green : .primary,
                    isLoading: isLoading
                ) {
                    Task {
                        await toggleLike()
                    }
                }

                // Dislike Button
                InteractionButton(
                    icon: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                    label: "Dislike",
                    color: isDisliked ? .red : .primary,
                    isLoading: isLoading
                ) {
                    Task {
                        await toggleDislike()
                    }
                }

                // Favorite Button
                InteractionButton(
                    icon: isFavorite ? "heart.fill" : "heart",
                    label: "Favorite",
                    color: isFavorite ? .pink : .primary,
                    isLoading: isLoading
                ) {
                    Task {
                        await toggleFavorite()
                    }
                }

                // Seen Button
                InteractionButton(
                    icon: isSeen ? "checkmark.circle.fill" : "checkmark.circle",
                    label: "Seen",
                    color: isSeen ? .purple : .primary,
                    isLoading: isLoading
                ) {
                    Task {
                        await markAsSeen()
                    }
                }
            }

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .task {
            await loadCurrentInteractionState()
        }
    }

    // MARK: - Private Methods

    private func loadCurrentInteractionState() async {
        // If we already have UserMovie data, use it directly
        if let userMovie = userMovie {
            print("🎯 Using provided UserMovie data for: \(userMovie.movie.title)")
            print("   - userId: \(userMovie.userId)")
            print("   - isLiked: \(userMovie.isLiked)")
            print("   - isDisliked: \(userMovie.isDisliked)")
            print("   - isFavorite: \(userMovie.isFavorite)")
            print("   - isSeen: \(userMovie.isSeen)")

            await MainActor.run {
                isLiked = userMovie.isLiked
                isDisliked = userMovie.isDisliked
                isFavorite = userMovie.isFavorite
                isSeen = userMovie.isSeen
            }
            return
        }

        print("🔄 No UserMovie provided, fetching from service for: \(movie.title)")

        // Fallback: fetch from service only when UserMovie is not provided
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user ID available")
            return
        }

        do {
            if let userMovie = try await userMovieService.getUserMovie(userId: userId, movieId: movie.id) {
                print("✅ Fetched UserMovie from service: \(userMovie.movie.title)")
                await MainActor.run {
                    isLiked = userMovie.isLiked
                    isDisliked = userMovie.isDisliked
                    isFavorite = userMovie.isFavorite
                    isSeen = userMovie.isSeen
                }
            } else {
                print("⚠️ No UserMovie found in service for: \(movie.title)")
            }
        } catch {
            print("❌ Error loading interaction state: \(error)")
        }
    }

    private func toggleLike() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.id) { userMovie in
                if userMovie.isLiked {
                    userMovie.isLiked = false
                    userMovie.likedAt = nil
                } else {
                    userMovie.markAsLiked()
                }
            }

            await MainActor.run {
                isLiked.toggle()
                if isLiked {
                    isDisliked = false // Can't be both liked and disliked
                }
            }

            onInteractionUpdate?()

        } catch {
            print("❌ Error toggling like: \(error)")
            await MainActor.run {
                errorMessage = "Failed to update like status"
            }
        }

        isLoading = false
    }

    private func toggleDislike() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.id) { userMovie in
                if userMovie.isDisliked {
                    userMovie.isDisliked = false
                    userMovie.dislikedAt = nil
                } else {
                    userMovie.markAsDisliked()
                }
            }

            await MainActor.run {
                isDisliked.toggle()
                if isDisliked {
                    isLiked = false // Can't be both liked and disliked
                }
            }

            onInteractionUpdate?()

        } catch {
            print("❌ Error toggling dislike: \(error)")
            await MainActor.run {
                errorMessage = "Failed to update dislike status"
            }
        }

        isLoading = false
    }

    private func toggleFavorite() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.id) { userMovie in
                userMovie.toggleFavorite()
            }

            await MainActor.run {
                isFavorite.toggle()
            }

            onInteractionUpdate?()

        } catch {
            print("❌ Error toggling favorite: \(error)")
            await MainActor.run {
                errorMessage = "Failed to update favorite status"
            }
        }

        isLoading = false
    }

    private func markAsSeen() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await userMovieService.updateMovieInteraction(userId: userId, movieId: movie.id) { userMovie in
                userMovie.markAsSeen()
            }

            await MainActor.run {
                isSeen = true
            }

            onInteractionUpdate?()

        } catch {
            print("❌ Error marking as seen: \(error)")
            await MainActor.run {
                errorMessage = "Failed to mark as seen"
            }
        }

        isLoading = false
    }
}

// MARK: - Interaction Button Component

struct InteractionButton: View {
    let icon: String
    let label: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: color))
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }

                Text(label)
                    .font(.caption)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        MovieInteractionButtons(
            movie: Movie.preview,
            userMovie: UserMovie(userId: "preview", movie: Movie.preview, isLiked: true, isFavorite: true)
        )

        MovieInteractionButtons(
            movie: Movie.preview
        )
    }
    .padding()
}
