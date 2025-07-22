//
//  AISearchBar.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct AISearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let onSearch: () -> Void
    let isSearching: Bool
    let validationMessage: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Search input field
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .onSubmit {
                        if canSearch {
                            onSearch()
                        }
                    }

                // Search button
                Button(action: {
                    if canSearch {
                        onSearch()
                    }
                }) {
                    Image(systemName: isSearching ? "stop.circle.fill" : "paperplane.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(canSearch ? DesignSystem.primaryCyan : .gray)
                }
                .disabled(!canSearch || isSearching)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Animated mesh gradient glow
                    AnimatedMeshGradient()
                        .clipShape(.capsule)
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                                .stroke(.white, lineWidth: 3)
                                .blur(radius: 2)
                                .blendMode(.overlay)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                                .stroke(.white, lineWidth: 1)
                                .blur(radius: 1)
                                .blendMode(.overlay)
                        }

                    // Background
                    RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                    .stroke(DesignSystem.primaryCyan.opacity(0.5), lineWidth: 1)
            )
            .primaryShadow()

            // Validation message
            if let validationMessage = validationMessage, !validationMessage.isEmpty {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private var canSearch: Bool {
        let words = searchText.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces)
        return words.count >= 2 && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    VStack(spacing: 20) {
        AISearchBar(
            searchText: .constant(""),
            placeholder: "Ask AI to find a movie...",
            onSearch: { print("Search tapped") },
            isSearching: false,
            validationMessage: nil
        )

        AISearchBar(
            searchText: .constant("action"),
            placeholder: "Ask AI to find a movie...",
            onSearch: { print("Search tapped") },
            isSearching: false,
            validationMessage: "Be more specific! Try describing the mood, genre, or actors you're looking for..."
        )

        AISearchBar(
            searchText: .constant("action movie with Tom Cruise"),
            placeholder: "Ask AI to find a movie...",
            onSearch: { print("Search tapped") },
            isSearching: true,
            validationMessage: nil
        )
    }
    .padding()
    .background(Color.black)
}
