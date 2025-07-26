//
//  FeedbackFormView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import MessageUI
import SwiftUI

struct FeedbackFormView: View {
    let rating: Int
    let onDismiss: () -> Void
    let onSendEmail: () -> Void

    @State private var selectedFeedback: String?
    @State private var showingEmailComposer = false

    private let feedbackOptions = [
        "Too many ads",
        "Not enough movies",
        "Hard to use",
        "Slow performance",
        "Missing features",
        "Other",
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(DesignSystem.primaryGradient)

                Text("Help us improve MovieBuddy!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("We'd love to hear what we can do better. Your feedback helps make MovieBuddy amazing for everyone.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Quick feedback buttons
            VStack(spacing: 12) {
                Text("What would make MovieBuddy better?")
                    .font(.headline)
                    .padding(.top)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 12) {
                    ForEach(feedbackOptions, id: \.self) { option in
                        FeedbackButton(
                            title: option,
                            isSelected: selectedFeedback == option
                        ) {
                            selectedFeedback = option
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Action buttons
            VStack(spacing: 12) {
                if selectedFeedback != nil {
                    Button(action: {
                        showingEmailComposer = true
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Send Detailed Feedback")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                    }
                    .padding(.horizontal)
                }

                Button(action: onDismiss) {
                    Text("Maybe Later")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingEmailComposer) {
            EmailFeedbackView(
                rating: rating,
                selectedFeedback: selectedFeedback ?? "No specific feedback",
                onDismiss: onDismiss
            )
        }
    }
}

struct FeedbackButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    isSelected ?
                        .cyan :
                        Color.gray.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                        .stroke(
                            isSelected ? Color.clear : Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FeedbackFormView(
        rating: 3,
        onDismiss: {},
        onSendEmail: {}
    )
}
