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

    // Movie interactions
    func saveMovieInteraction(_ interaction: UserMovieInteraction, for userId: String) async throws
    func getUserMovieInteractions(for userId: String) async throws -> UserMovieInteractions?
    func getMovieInteraction(movieId: String, for userId: String) async throws -> UserMovieInteraction?
    func toggleMovieLike(movie: Movie, for userId: String) async throws -> MovieLikeStatus
    func toggleMovieDislike(movie: Movie, for userId: String) async throws -> MovieLikeStatus
    func toggleMovieFavorite(movie: Movie, for userId: String) async throws -> Bool

    // Daily recommendations
    func saveDailyRecommendations(_ recommendations: DailyRecommendations, for userId: String) async throws
    func getDailyRecommendations(for date: Date, userId: String) async throws -> DailyRecommendations?
    func getRecentRecommendationIds(since date: Date, for userId: String) async throws -> [String]

    // Seen movies
    func markMovieAsSeen(_ seenMovie: SeenMovie, for userId: String) async throws
    func getSeenMovies(for userId: String) async throws -> [SeenMovie]

    // Notifications
    func saveNotification(_ notification: AppNotification) async throws
    func getNotifications(for userId: String) async throws -> [AppNotification]
    func markNotificationAsRead(_ notificationId: String, for userId: String) async throws
    func markAllNotificationsAsRead(for userId: String) async throws
    func deleteNotification(_ notificationId: String, for userId: String) async throws
}

final class FirestoreService: FirestoreServiceProtocol {
    private let db = Firestore.firestore()
    private let collection = "userMovieData"
    private let interactionsCollection = "userMovieInteractions"
    private let dailyRecommendationsCollection = "dailyRecommendations"
    private let seenMoviesCollection = "seenMovies"

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

    // MARK: - Movie Interactions

    func saveMovieInteraction(_ interaction: UserMovieInteraction, for userId: String) async throws {
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

            print("✅ Interaction film sauvegardée pour l'utilisateur \(userId)")
        } catch {
            print("❌ Erreur lors de la sauvegarde de l'interaction: \(error)")
            throw error
        }
    }

    func getUserMovieInteractions(for userId: String) async throws -> UserMovieInteractions? {
        do {
            let document = try await db.collection(interactionsCollection).document(userId).getDocument()

            guard document.exists, let data = document.data() else {
                print("📄 Aucune interaction trouvée pour l'utilisateur \(userId)")
                return nil
            }

            let interactionsData = data["interactions"] as? [String: [String: Any]] ?? [:]
            let interactions = try interactionsData.compactMapValues { interactionData in
                try Firestore.Decoder().decode(UserMovieInteraction.self, from: interactionData)
            }

            var userInteractions = UserMovieInteractions(userId: userId)
            userInteractions.interactions = interactions

            print("✅ Interactions utilisateur récupérées pour \(userId)")
            return userInteractions
        } catch {
            print("❌ Erreur lors de la récupération des interactions: \(error)")
            throw error
        }
    }

    func getMovieInteraction(movieId: String, for userId: String) async throws -> UserMovieInteraction? {
        let userInteractions = try await getUserMovieInteractions(for: userId)
        return userInteractions?.interactions[movieId]
    }

    func toggleMovieLike(movie: Movie, for userId: String) async throws -> MovieLikeStatus {
        let movieId = movie.uniqueId
        var interaction = try await getMovieInteraction(movieId: movieId, for: userId) ??
            UserMovieInteraction(movieId: movieId, movieTitle: movie.title, posterURL: movie.posterURL?.absoluteString)

        // Toggle like status
        switch interaction.likeStatus {
        case .none:
            interaction.likeStatus = .liked
        case .liked:
            interaction.likeStatus = .none
        case .disliked:
            interaction.likeStatus = .liked
        }

        try await saveMovieInteraction(interaction, for: userId)
        return interaction.likeStatus
    }

    func toggleMovieDislike(movie: Movie, for userId: String) async throws -> MovieLikeStatus {
        let movieId = movie.uniqueId
        var interaction = try await getMovieInteraction(movieId: movieId, for: userId) ??
            UserMovieInteraction(movieId: movieId, movieTitle: movie.title, posterURL: movie.posterURL?.absoluteString)

        // Toggle dislike status
        switch interaction.likeStatus {
        case .none:
            interaction.likeStatus = .disliked
        case .disliked:
            interaction.likeStatus = .none
        case .liked:
            interaction.likeStatus = .disliked
        }

        try await saveMovieInteraction(interaction, for: userId)
        return interaction.likeStatus
    }

    func toggleMovieFavorite(movie: Movie, for userId: String) async throws -> Bool {
        let movieId = movie.uniqueId
        var interaction = try await getMovieInteraction(movieId: movieId, for: userId) ??
            UserMovieInteraction(movieId: movieId, movieTitle: movie.title, posterURL: movie.posterURL?.absoluteString)

        // Toggle favorite status
        interaction.isFavorite.toggle()

        try await saveMovieInteraction(interaction, for: userId)
        return interaction.isFavorite
    }

    // MARK: - Daily Recommendations

    func saveDailyRecommendations(_ recommendations: DailyRecommendations, for userId: String) async throws {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateKey = dateFormatter.string(from: recommendations.date)
            let documentId = "\(userId)_\(dateKey)"

            let moviesData = try recommendations.movies.map { movie in
                try Firestore.Encoder().encode(movie)
            }

            try await db.collection(dailyRecommendationsCollection).document(documentId).setData([
                "id": recommendations.id,
                "userId": recommendations.userId,
                "date": recommendations.date,
                "movies": moviesData,
                "generatedAt": recommendations.generatedAt,
            ])

            print("✅ Recommandations quotidiennes sauvegardées pour \(userId) - \(dateKey)")
        } catch {
            print("❌ Erreur lors de la sauvegarde des recommandations quotidiennes: \(error)")
            throw error
        }
    }

    func getDailyRecommendations(for date: Date, userId: String) async throws -> DailyRecommendations? {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateKey = dateFormatter.string(from: date)
            let documentId = "\(userId)_\(dateKey)"

            let document = try await db.collection(dailyRecommendationsCollection).document(documentId).getDocument()

            guard document.exists, let data = document.data() else {
                print("📄 Aucune recommandation trouvée pour \(userId) - \(dateKey)")
                return nil
            }

            let moviesData = data["movies"] as? [[String: Any]] ?? []
            let movies = try moviesData.compactMap { movieData in
                try Firestore.Decoder().decode(MovieFirestore.self, from: movieData).toMovie()
            }

            let recommendations = DailyRecommendations(userId: userId, date: date, movies: movies.map { MovieFirestore(from: $0) })

            print("✅ Recommandations quotidiennes récupérées pour \(userId) - \(dateKey)")
            return recommendations
        } catch {
            print("❌ Erreur lors de la récupération des recommandations quotidiennes: \(error)")
            throw error
        }
    }

    func getRecentRecommendationIds(since date: Date, for userId: String) async throws -> [String] {
        do {
            let query = db.collection(dailyRecommendationsCollection)
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: date)
                .order(by: "date", descending: true)

            let snapshot = try await query.getDocuments()

            var movieIds: [String] = []

            for document in snapshot.documents {
                let data = document.data()
                let moviesData = data["movies"] as? [[String: Any]] ?? []

                for movieData in moviesData {
                    if let movieFirestore = try? Firestore.Decoder().decode(MovieFirestore.self, from: movieData) {
                        let movie = movieFirestore.toMovie()
                        let movieId = movie.imdbID ?? movie.title
                        movieIds.append(movieId)
                    }
                }
            }

            print("✅ \(movieIds.count) IDs de films récents récupérés pour \(userId)")
            return movieIds
        } catch {
            print("❌ Erreur lors de la récupération des IDs de films récents: \(error)")
            throw error
        }
    }

    // MARK: - Notifications

    func saveNotification(_ notification: AppNotification) async throws {
        do {
            let documentId = "\(notification.userId)_\(notification.id)"
            try await db.collection("notifications").document(documentId).setData([
                "id": notification.id,
                "userId": notification.userId,
                "type": notification.type.rawValue,
                "title": notification.title,
                "message": notification.message,
                "timestamp": notification.timestamp,
                "isRead": notification.isRead,
                "actionData": notification.actionData as Any,
            ])
            print("✅ Notification saved: \(notification.title)")
        } catch {
            print("❌ Error saving notification: \(error)")
            throw error
        }
    }

    func getNotifications(for userId: String) async throws -> [AppNotification] {
        do {
            // Use simpler query to avoid index requirement - we'll sort client-side
            let query = db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .limit(to: 50) // Limit to last 50 notifications

            let snapshot = try await query.getDocuments()

            var notifications: [AppNotification] = []

            for document in snapshot.documents {
                let data = document.data()

                guard let id = data["id"] as? String,
                      let userId = data["userId"] as? String,
                      let typeString = data["type"] as? String,
                      let type = NotificationType(rawValue: typeString),
                      let title = data["title"] as? String,
                      let message = data["message"] as? String,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                      let isRead = data["isRead"] as? Bool
                else {
                    print("⚠️ Failed to decode notification document: \(document.documentID)")
                    continue
                }

                let actionData = data["actionData"] as? [String: String]

                var notification = AppNotification(
                    userId: userId,
                    type: type,
                    title: title,
                    message: message,
                    actionData: actionData
                )

                // Override the auto-generated values with stored ones
                notification = AppNotification(
                    id: id,
                    userId: userId,
                    type: type,
                    title: title,
                    message: message,
                    timestamp: timestamp,
                    isRead: isRead,
                    actionData: actionData
                )

                notifications.append(notification)
            }

            print("✅ Retrieved \(notifications.count) notifications for user: \(userId)")
            return notifications
        } catch {
            print("❌ Error retrieving notifications: \(error)")
            throw error
        }
    }

    func markNotificationAsRead(_ notificationId: String, for userId: String) async throws {
        do {
            let documentId = "\(userId)_\(notificationId)"
            try await db.collection("notifications").document(documentId).updateData([
                "isRead": true,
            ])
            print("✅ Notification marked as read: \(notificationId)")
        } catch {
            print("❌ Error marking notification as read: \(error)")
            throw error
        }
    }

    func markAllNotificationsAsRead(for userId: String) async throws {
        do {
            let query = db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .whereField("isRead", isEqualTo: false)

            let snapshot = try await query.getDocuments()

            let batch = db.batch()
            for document in snapshot.documents {
                batch.updateData(["isRead": true], forDocument: document.reference)
            }

            try await batch.commit()
            print("✅ All notifications marked as read for user: \(userId)")
        } catch {
            print("❌ Error marking all notifications as read: \(error)")
            throw error
        }
    }

    func deleteNotification(_ notificationId: String, for userId: String) async throws {
        do {
            let documentId = "\(userId)_\(notificationId)"
            try await db.collection("notifications").document(documentId).delete()
            print("✅ Notification deleted: \(notificationId)")
        } catch {
            print("❌ Error deleting notification: \(error)")
            throw error
        }
    }

    // MARK: - Seen Movies

    func markMovieAsSeen(_ seenMovie: SeenMovie, for userId: String) async throws {
        do {
            let documentId = "\(userId)_\(seenMovie.movieId)"

            try await db.collection(seenMoviesCollection).document(documentId).setData([
                "id": seenMovie.id,
                "movieId": seenMovie.movieId,
                "title": seenMovie.title,
                "posterURL": seenMovie.posterURL as Any,
                "seenAt": seenMovie.seenAt,
                "userId": seenMovie.userId,
            ])

            print("✅ Film marqué comme vu: \(seenMovie.title) pour \(userId)")
        } catch {
            print("❌ Erreur lors du marquage du film comme vu: \(error)")
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
                try Firestore.Decoder().decode(SeenMovie.self, from: document.data())
            }

            print("✅ \(seenMovies.count) films vus récupérés pour \(userId)")
            return seenMovies
        } catch {
            print("❌ Erreur lors de la récupération des films vus: \(error)")
            throw error
        }
    }
}
