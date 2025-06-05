//
//  MovieConfirmationView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct MovieConfirmationView: View {
    let movie: Movie
    let onConfirm: () -> Void
    let onSearchAgain: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("AI a trouvé ce film pour vous")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Que pensez-vous de cette suggestion ?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Movie Card
                ScrollView {
                    MovieCardView(movie: movie)
                        .padding(.horizontal)
                        .frame(height: 300)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    // Confirm Button
                    AIActionButton(title: "Perfect ! C'est parti", icon: "checkmark.circle.fill") {
                        onConfirm()
                        dismiss()
                    }

                    // Search Again Button
                    Button(action: {
                        onSearchAgain()
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Chercher un autre film")
                        }
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding()
                        .frame(width: 250)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.primary.opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                )
                        )
                    }
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
        .onAppear {
            triggerHaptic()
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    NavigationView {
        MovieConfirmationView(
            movie: MockMovie.sample,
            onConfirm: {},
            onSearchAgain: {}
        )
    }
}
