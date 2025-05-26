//
//  GenreActorSelectionView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct GenreActorSelectionView: View {
    @Binding var selectedGenres: [MovieGenre]
    @Binding var actorsInput: String
    let onStartSearch: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Personnalisez votre recherche")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Aidez l'IA à trouver le film parfait pour vous")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 32) {
                        // Genre Selection
                        VStack(spacing: 16) {
                            Text("Genres préférés")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            MovieGenreSelectionView(tags: MovieGenre.allCases) { tag, isSelected in
                                MovieGenreCapsule(tag: tag.rawValue, isSelected: isSelected)
                            } didChangeSelection: { selection in
                                selectedGenres = selection
                            }
                        }

                        // Actors Input
                        VStack(spacing: 12) {
                            Text("Acteurs favoris (optionnel)")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            TextEditor(text: $actorsInput)
                                .frame(height: 100)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.primary.opacity(0.2), lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemBackground))
                                        )
                                )
                                .overlay(
                                    Group {
                                        if actorsInput.isEmpty {
                                            Text("Ex: Leonardo DiCaprio, Scarlett Johansson...")
                                                .foregroundColor(.secondary)
                                                .font(.subheadline)
                                                .allowsHitTesting(false)
                                                .padding(.leading, 16)
                                                .padding(.top, 20)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                        }
                    }
                    .padding(.horizontal)
                }

                // Action Button
                AIActionButton(title: "Lancer la recherche IA") {
                    onStartSearch()
                    dismiss()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        GenreActorSelectionView(
            selectedGenres: .constant([]),
            actorsInput: .constant(""),
            onStartSearch: {}
        )
    }
}
