//
//  FirestoreService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

protocol FirestoreServiceProtocol {
    func saveSelectedMovie(_ movie: Movie, for userId: String) async throws
    func saveMovieSuggestion(_ movie: Movie, for userId: String) async throws
    func getUserMovieData(for userId: String) async throws -> UserMovieData?
    func clearSelectedMovie(for userId: String) async throws
}

final class FirestoreService: FirestoreServiceProtocol {
    private let db = Firestore.firestore()
    private let collection = "userMovieData"

    func saveSelectedMovie(_ movie: Movie, for userId: String) async throws {
        let movieFirestore = MovieFirestore(from: movie)

        do {
            // Récupérer les données existantes ou créer un nouveau document
            var userData = try await getUserMovieData(for: userId) ?? UserMovieData(userId: userId)

            // Mettre à jour le film sélectionné
            userData = UserMovieData(
                userId: userId,
                selectedMovie: movieFirestore,
                lastSuggestions: userData.lastSuggestions
            )

            // Sauvegarder dans Firestore
            try await db.collection(collection).document(userId).setData([
                "id": userData.id,
                "userId": userData.userId,
                "selectedMovie": Firestore.Encoder().encode(userData.selectedMovie),
                "lastSuggestions": userData.lastSuggestions.map { try Firestore.Encoder().encode($0) },
                "createdAt": userData.createdAt,
                "updatedAt": Date(),
            ])

            print("✅ Film sélectionné sauvegardé pour l'utilisateur \(userId)")
        } catch {
            print("❌ Erreur lors de la sauvegarde du film sélectionné: \(error)")
            throw error
        }
    }

    func saveMovieSuggestion(_ movie: Movie, for userId: String) async throws {
        let movieFirestore = MovieFirestore(from: movie)

        do {
            // Récupérer les données existantes ou créer un nouveau document
            var userData = try await getUserMovieData(for: userId) ?? UserMovieData(userId: userId)

            // Ajouter la nouvelle suggestion (garder les 10 dernières maximum)
            var suggestions = userData.lastSuggestions
            suggestions.insert(movieFirestore, at: 0)
            if suggestions.count > 10 {
                suggestions = Array(suggestions.prefix(10))
            }

            // Mettre à jour les données
            userData = UserMovieData(
                userId: userId,
                selectedMovie: userData.selectedMovie,
                lastSuggestions: suggestions
            )

            // Sauvegarder dans Firestore
            try await db.collection(collection).document(userId).setData([
                "id": userData.id,
                "userId": userData.userId,
                "selectedMovie": userData.selectedMovie != nil ? Firestore.Encoder().encode(userData.selectedMovie) : NSNull(),
                "lastSuggestions": userData.lastSuggestions.map { try Firestore.Encoder().encode($0) },
                "createdAt": userData.createdAt,
                "updatedAt": Date(),
            ])

            print("✅ Suggestion de film sauvegardée pour l'utilisateur \(userId)")
        } catch {
            print("❌ Erreur lors de la sauvegarde de la suggestion: \(error)")
            throw error
        }
    }

    func getUserMovieData(for userId: String) async throws -> UserMovieData? {
        do {
            let document = try await db.collection(collection).document(userId).getDocument()

            guard document.exists, let data = document.data() else {
                print("📄 Aucune donnée trouvée pour l'utilisateur \(userId)")
                return nil
            }

            let selectedMovieData = data["selectedMovie"]
            let selectedMovie: MovieFirestore?

            if selectedMovieData is NSNull {
                selectedMovie = nil
            } else if let movieData = selectedMovieData {
                selectedMovie = try Firestore.Decoder().decode(MovieFirestore.self, from: movieData)
            } else {
                selectedMovie = nil
            }

            let lastSuggestionsData = data["lastSuggestions"] as? [[String: Any]] ?? []
            let lastSuggestions = try lastSuggestionsData.compactMap { movieData in
                try Firestore.Decoder().decode(MovieFirestore.self, from: movieData)
            }

            let userData = UserMovieData(
                userId: userId,
                selectedMovie: selectedMovie,
                lastSuggestions: lastSuggestions
            )

            print("✅ Données utilisateur récupérées pour \(userId)")
            return userData
        } catch {
            print("❌ Erreur lors de la récupération des données utilisateur: \(error)")
            throw error
        }
    }

    func clearSelectedMovie(for userId: String) async throws {
        do {
            // Récupérer les données existantes
            guard var userData = try await getUserMovieData(for: userId) else {
                return
            }

            // Supprimer le film sélectionné
            userData = UserMovieData(
                userId: userId,
                selectedMovie: nil,
                lastSuggestions: userData.lastSuggestions
            )

            // Sauvegarder dans Firestore
            try await db.collection(collection).document(userId).setData([
                "id": userData.id,
                "userId": userData.userId,
                "selectedMovie": NSNull(),
                "lastSuggestions": userData.lastSuggestions.map { try Firestore.Encoder().encode($0) },
                "createdAt": userData.createdAt,
                "updatedAt": Date(),
            ])

            print("✅ Film sélectionné supprimé pour l'utilisateur \(userId)")
        } catch {
            print("❌ Erreur lors de la suppression du film sélectionné: \(error)")
            throw error
        }
    }
}
