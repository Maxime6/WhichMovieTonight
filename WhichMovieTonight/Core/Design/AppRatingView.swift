//
//  AppRatingView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import SwiftUI

struct AppRatingView: View {
    @ObservedObject var ratingManager: AppRatingManager
    @State private var currentRating: Int = 0
    @State private var showingFeedback = false
    @State private var showingRateButton = false

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    ratingManager.dismissRatingPopup()
                }

            // Main content
            VStack(spacing: 24) {
                if !showingFeedback {
                    // Initial rating view
                    initialRatingView
                } else {
                    // Feedback view
                    FeedbackFormView(
                        rating: currentRating,
                        onDismiss: {
                            ratingManager.dismissRatingPopup()
                        },
                        onSendEmail: {
                            // Email handling is done in FeedbackFormView
                        }
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.extraLargeRadius)
                    .fill(.regularMaterial)
                    .subtleShadow()
            )
            .padding(.horizontal, 20)
            .scaleEffect(ratingManager.shouldShowRatingPopup ? 1.0 : 0.8)
            .opacity(ratingManager.shouldShowRatingPopup ? 1.0 : 0.0)
            .animation(DesignSystem.springAnimation, value: ratingManager.shouldShowRatingPopup)
        }
        .onChange(of: currentRating) { _, newRating in
            withAnimation(DesignSystem.easeInOutAnimation) {
                showingRateButton = newRating > 0
            }
        }
    }

    private var initialRatingView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                // App icon or logo
                Image(systemName: "film.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignSystem.primaryGradient)

                Text("Enjoying MovieBuddy?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("Your feedback helps us improve and helps other movie lovers discover great films!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Star rating
            VStack(spacing: 16) {
                RatingStarsView(rating: $currentRating, starSize: 40, spacing: 12)

                if currentRating > 0 {
                    Text(ratingText)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .transition(.opacity.combined(with: .scale))
                }
            }

            // Action buttons
            VStack(spacing: 12) {
                if showingRateButton {
                    Button(action: {
                        if currentRating == 5 {
                            ratingManager.handleRatingSubmitted(rating: currentRating)
                        } else {
                            withAnimation(DesignSystem.easeInOutAnimation) {
                                showingFeedback = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: currentRating == 5 ? "star.fill" : "envelope.fill")
                            Text(currentRating == 5 ? "Rate MovieBuddy" : "Send Feedback")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Button(action: {
                    ratingManager.dismissRatingPopup()
                }) {
                    Text("Maybe Later")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var ratingText: String {
        switch currentRating {
        case 1:
            return "Not great 😔"
        case 2:
            return "Could be better 😕"
        case 3:
            return "It's okay 🙂"
        case 4:
            return "Pretty good! 😊"
        case 5:
            return "Love it! ⭐️"
        default:
            return ""
        }
    }
}

#Preview {
    AppRatingView(ratingManager: AppRatingManager())
}
