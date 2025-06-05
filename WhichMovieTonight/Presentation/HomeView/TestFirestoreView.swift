//
//  TestFirestoreView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseAuth
import SwiftUI

struct TestFirestoreView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var testMovie = Movie.preview

    var body: some View {
        VStack(spacing: 20) {
            Text("Test Firestore")
                .font(.title.bold())

            if let userId = Auth.auth().currentUser?.uid {
                Text("User ID: \(userId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Sauvegarder film de test") {
                Task {
                    if let userId = Auth.auth().currentUser?.uid {
                        do {
                            try await FirestoreService().saveSelectedMovie(testMovie, for: userId)
                            print("✅ Film sauvegardé")
                        } catch {
                            print("❌ Erreur: \(error)")
                        }
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button("Charger données utilisateur") {
                Task {
                    if let userId = Auth.auth().currentUser?.uid {
                        do {
                            let userData = try await FirestoreService().getUserMovieData(for: userId)
                            print("✅ Données chargées: \(userData?.selectedMovie?.title ?? "Aucun film")")
                            if let movie = userData?.selectedMovie {
                                viewModel.selectedMovie = movie.toMovie()
                            }
                        } catch {
                            print("❌ Erreur: \(error)")
                        }
                    }
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if let movie = viewModel.selectedMovie {
                Text("Film chargé: \(movie.title)")
                    .font(.headline)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    TestFirestoreView()
}
