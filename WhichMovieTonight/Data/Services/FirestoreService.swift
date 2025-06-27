//
//  FirestoreService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - Firestore Service Protocol

protocol FirestoreServiceProtocol {
    // User Movie Interactions
    func getUserMovieInteractions(for userId: String) async throws -> UserMovieInteractions?
    func saveUserMovieInteraction(_ interaction: UserMovieInteraction, for userId: String) async throws
    func markMovieAsSeen(_ movie: SeenMovie, for userId: String) async throws
    func getSeenMovies(for userId: String) async throws -> [SeenMovie]

    // Selected Movie for Tonight
    func saveSelectedMovieForTonight(_ movie: MovieFirestore, for userId: String) async throws
    func getSelectedMovieForTonight(for userId: String) async throws -> MovieFirestore?
    func removeSelectedMovieForTonight(for userId: String) async throws

    // User Movie Data (New simple approach)
    func getUserMovieData(for userId: String) async throws -> UserMovieData?
    func saveUserMovieData(_ userData: UserMovieData, for userId: String) async throws
    func updateUserMovieData(_ userData: UserMovieData, for userId: String) async throws
}

// MARK: - Firestore Service Implementation

final class FirestoreService: FirestoreServiceProtocol {
    private let db = Firestore.firestore()
    private let collection = "userMovieData"
    private let interactionsCollection = "userMovieInteractions"
    private let seenMoviesCollection = "seenMovies"

    // MARK: - User Movie Data (New simple approach)

    func getUserMovieData(for userId: String) async throws -> UserMovieData? {
        do {
            let document = try await db.collection(collection).document(userId).getDocument()

            if document.exists {
                do {
                    let userData = try document.data(as: UserMovieData.self)
                    print("✅ User movie data loaded for \(userId)")
                    return userData
                } catch {
                    // Migration: If decoding fails with old data structure, create new empty data
                    print("🔄 Migration: Old data structure detected, creating new empty UserMovieData for \(userId)")
                    print("Migration error details: \(error)")

                    // Create new empty user data and save it
                    let newUserData = UserMovieData(userId: userId)
                    try await saveUserMovieData(newUserData, for: userId)

                    print("✅ New UserMovieData created and saved for \(userId)")
                    return newUserData
                }
            } else {
                print("📝 No user movie data found for \(userId)")
                return nil
            }
        } catch {
            if error.localizedDescription.contains("offline") {
                print("📱 App is offline - user movie data will load when connection is restored")
                return nil
            }
            print("❌ Error loading user movie data: \(error)")
            throw error
        }
    }

    func saveUserMovieData(_ userData: UserMovieData, for userId: String) async throws {
        do {
            try await db.collection(collection).document(userId).setData([
                "id": userData.id,
                "userId": userData.userId,
                "currentPicks": userData.currentPicks.map { try Firestore.Encoder().encode($0) },
                "generationHistory": userData.generationHistory.map { try Firestore.Encoder().encode($0) },
                "selectedMovieForTonight": userData.selectedMovieForTonight != nil ? Firestore.Encoder().encode(userData.selectedMovieForTonight!) : FieldValue.delete(),
                "createdAt": userData.createdAt,
                "updatedAt": Date(),
            ])

            print("✅ User movie data saved for \(userId)")
        } catch {
            print("❌ Error saving user movie data: \(error)")
            throw error
        }
    }

    func updateUserMovieData(_ userData: UserMovieData, for userId: String) async throws {
        do {
            try await db.collection(collection).document(userId).setData([
                "id": userData.id,
                "userId": userData.userId,
                "currentPicks": userData.currentPicks.map { try Firestore.Encoder().encode($0) },
                "generationHistory": userData.generationHistory.map { try Firestore.Encoder().encode($0) },
                "selectedMovieForTonight": userData.selectedMovieForTonight != nil ? Firestore.Encoder().encode(userData.selectedMovieForTonight!) : FieldValue.delete(),
                "createdAt": userData.createdAt,
                "updatedAt": Date(),
            ])

            print("✅ User movie data updated for \(userId)")
        } catch {
            print("❌ Error updating user movie data: \(error)")
            throw error
        }
    }

    // MARK: - Selected Movie for Tonight

    func saveSelectedMovieForTonight(_ movie: MovieFirestore, for userId: String) async throws {
        try await db.collection("selectedMovieForTonight").document(userId).setData([
            "userId": userId,
            "selectedMovie": Firestore.Encoder().encode(movie),
            "createdAt": Date(),
        ])
        print("✅ Selected movie for tonight saved for user: \(userId)")
    }

    func getSelectedMovieForTonight(for userId: String) async throws -> MovieFirestore? {
        let document = try await db.collection("selectedMovieForTonight").document(userId).getDocument()

        guard document.exists, let data = document.data() else {
            return nil
        }

        if let movieData = data["selectedMovie"] {
            return try Firestore.Decoder().decode(MovieFirestore.self, from: movieData)
        }

        return nil
    }

    func removeSelectedMovieForTonight(for userId: String) async throws {
        try await db.collection("selectedMovieForTonight").document(userId).delete()
        print("✅ Selected movie for tonight removed for user: \(userId)")
    }

    // MARK: - User Movie Interactions

    func getUserMovieInteractions(for userId: String) async throws -> UserMovieInteractions? {
        do {
            let document = try await db.collection(interactionsCollection).document(userId).getDocument()

            guard document.exists, let data = document.data() else {
                print("📄 No interactions found for user \(userId)")
                return nil
            }

            let interactionsData = data["interactions"] as? [String: [String: Any]] ?? [:]
            let interactions = try interactionsData.compactMapValues { interactionData in
                try Firestore.Decoder().decode(UserMovieInteraction.self, from: interactionData)
            }

            var userInteractions = UserMovieInteractions(userId: userId)
            userInteractions.interactions = interactions

            print("✅ User interactions loaded for \(userId)")
            return userInteractions
        } catch {
            print("❌ Error loading user interactions: \(error)")
            throw error
        }
    }

    func saveUserMovieInteraction(_ interaction: UserMovieInteraction, for userId: String) async throws {
        do {
            var userInteractions = try await getUserMovieInteractions(for: userId) ?? UserMovieInteractions(userId: userId)

            var updatedInteraction = interaction
            updatedInteraction.updatedAt = Date()
            userInteractions.interactions[interaction.movieId] = updatedInteraction
            userInteractions.updatedAt = Date()

            try await db.collection(interactionsCollection).document(userId).setData([
                "userId": userInteractions.userId,
                "interactions": userInteractions.interactions.mapValues { try Firestore.Encoder().encode($0) },
                "createdAt": userInteractions.createdAt,
                "updatedAt": userInteractions.updatedAt,
            ])

            print("✅ Movie interaction saved for user \(userId)")
        } catch {
            print("❌ Error saving movie interaction: \(error)")
            throw error
        }
    }

    // MARK: - Seen Movies

    func markMovieAsSeen(_ movie: SeenMovie, for userId: String) async throws {
        do {
            let documentId = "\(userId)_\(movie.movieId)"

            try await db.collection(seenMoviesCollection).document(documentId).setData([
                "userId": movie.userId,
                "movieId": movie.movieId,
                "title": movie.title,
                "seenAt": movie.seenAt,
            ])

            print("✅ Movie marked as seen for user \(userId)")
        } catch {
            print("❌ Error marking movie as seen: \(error)")
            throw error
        }
    }

    func getSeenMovies(for userId: String) async throws -> [SeenMovie] {
        do {
            let query = db.collection(seenMoviesCollection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "seenAt", descending: true)

            let snapshot = try await query.getDocuments()

            let seenMovies = try snapshot.documents.compactMap { document in
                try document.data(as: SeenMovie.self)
            }

            print("✅ \(seenMovies.count) seen movies loaded for user \(userId)")
            return seenMovies
        } catch {
            print("❌ Error loading seen movies: \(error)")
            throw error
        }
    }
}
