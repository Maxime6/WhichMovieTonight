//
//  DailyNotificationService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import FirebaseAuth
import Foundation
import UIKit
import UserNotifications

// MARK: - NotificationCenter Extensions for Recommendations

extension NSNotification.Name {
    static let shouldGenerateRecommendations = NSNotification.Name("shouldGenerateRecommendations")
}

protocol DailyNotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleDailyRecommendationNotification()
    func scheduleRecommendationGeneration()
    func cancelGenerationNotifications()
    func cancelAllNotifications()
    func handleNotificationResponse(_ response: UNNotificationResponse)
    func setupBackgroundTasks()

    // Synchronization methods
    func synchronizeSystemNotifications() async
    func getDeliveredNotifications() async -> [UNNotification]
    func createSystemNotificationForFirestore(_ appNotification: AppNotification) async
    func removeSystemNotification(_ appNotificationId: String)
    func updateBadgeCount(_ count: Int)
}

final class DailyNotificationService: DailyNotificationServiceProtocol {
    @Injected private var notificationService: NotificationServiceProtocol

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("✅ Notification permission granted: \(granted)")
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }

    func scheduleDailyRecommendationNotification() {
        let center = UNUserNotificationCenter.current()

        // Annuler les notifications existantes
        center.removePendingNotificationRequests(withIdentifiers: ["daily-recommendations"])

        // Créer le contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = "🎬 Your daily picks are ready!"
        content.body = "Discover 5 new movies selected just for you"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "daily_recommendations"] // Add type for handling

        // Planifier pour 8h chaque jour (les reco sont générées à 6h)
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Créer la requête
        let request = UNNotificationRequest(
            identifier: "daily-recommendations",
            content: content,
            trigger: trigger
        )

        // Ajouter la notification avec completion handler
        center.add(request) { error in
            if let error = error {
                print("❌ Erreur lors de la programmation de la notification: \(error)")
            } else {
                print("✅ Notification quotidienne programmée pour 8h")
            }
        }
    }

    func scheduleRecommendationGeneration() {
        let center = UNUserNotificationCenter.current()

        // Annuler les générations de recommandations existantes
        center.removePendingNotificationRequests(withIdentifiers: ["generate-recommendations"])

        // Créer le contenu pour la génération silencieuse
        let content = UNMutableNotificationContent()
        content.title = "Generating recommendations..."
        content.body = "Background task"
        content.sound = nil // Silencieux
        content.badge = nil
        content.userInfo = ["action": "generateRecommendations"] // Pour identifier le type d'action

        // Planifier pour 6h chaque jour (2h avant la notification)
        var dateComponents = DateComponents()
        dateComponents.hour = 6
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Créer la requête
        let request = UNNotificationRequest(
            identifier: "generate-recommendations",
            content: content,
            trigger: trigger
        )

        // Ajouter la notification avec completion handler
        center.add(request) { error in
            if let error = error {
                print("❌ Erreur lors de la programmation de la génération: \(error)")
            } else {
                print("✅ Génération de recommandations programmée pour 6h")
            }
        }
    }

    func cancelGenerationNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["generate-recommendations"])
        print("✅ Notification de génération à 6h supprimée")
    }

    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("✅ Toutes les notifications ont été annulées")
    }

    // MARK: - Notification Handling

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        // Cette méthode peut être appelée depuis AppDelegate ou SceneDelegate
        // pour gérer les actions sur les notifications

        print("📱 Notification reçue: \(response.notification.request.identifier)")

        switch response.notification.request.identifier {
        case "generate-recommendations":
            // Génération silencieuse des recommandations
            print("🔄 Déclenchement de la génération de recommandations en arrière-plan")
            NotificationCenter.default.post(name: .shouldGenerateRecommendations, object: nil)

        case "daily-recommendations":
            // L'utilisateur a tapé sur la notification des recommandations
            print("👤 Utilisateur a ouvert l'app via la notification")

            // Create a Firestore notification for tracking
            Task {
                await createFirestoreNotificationFromSystemResponse(response)
            }

        default:
            break
        }
    }

    // MARK: - Notification Synchronization

    func synchronizeSystemNotifications() async {
        // Get pending system notifications and create corresponding Firestore notifications
        let center = UNUserNotificationCenter.current()

        let requests = await center.pendingNotificationRequests()
        print("📱 Found \(requests.count) pending system notifications")

        for request in requests {
            await createFirestoreNotificationFromSystem(request)
        }
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        let center = UNUserNotificationCenter.current()

        let notifications = await center.deliveredNotifications()
        print("📬 Found \(notifications.count) delivered system notifications")
        return notifications
    }

    func createSystemNotificationForFirestore(_ appNotification: AppNotification) async {
        // Create a system notification based on an app notification
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = appNotification.title
        content.body = appNotification.message
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "notificationId": appNotification.id,
            "type": appNotification.type.rawValue,
        ]

        // Use a unique identifier that includes our app notification ID
        let identifier = "app_notification_\(appNotification.id)"

        // Trigger immediately (for notifications created within the app)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("✅ System notification created for app notification: \(appNotification.title)")
        } catch {
            print("❌ Error creating system notification: \(error)")
        }
    }

    func removeSystemNotification(_ appNotificationId: String) {
        let center = UNUserNotificationCenter.current()
        let identifier = "app_notification_\(appNotificationId)"

        // Remove both pending and delivered
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])

        print("✅ Removed system notification for: \(appNotificationId)")
    }

    func updateBadgeCount(_ count: Int) {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                try await center.setBadgeCount(count)
                print("🔢 Updated app badge count to: \(count)")
            } catch {
                print("❌ Error updating badge count: \(error)")
            }
        }
    }

    private func createFirestoreNotificationFromSystem(_ request: UNNotificationRequest) async {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }

        // Skip if this is already an app-generated notification
        if request.identifier.hasPrefix("app_notification_") { return }

        let userInfo = request.content.userInfo
        let typeString = userInfo["type"] as? String ?? "daily_recommendations"
        let type = NotificationType(rawValue: typeString) ?? .dailyRecommendations

        // Check if we already have this notification in Firestore
        let existingNotifications = try? await notificationService.getNotifications(for: userId)
        let hasExisting = existingNotifications?.contains { notification in
            notification.title == request.content.title &&
                notification.message == request.content.body &&
                Calendar.current.isDate(notification.timestamp, inSameDayAs: Date()) &&
                notification.type == type
        } ?? false

        if !hasExisting {
            let appNotification = AppNotification(
                userId: userId,
                type: type,
                title: request.content.title,
                message: request.content.body
            )

            do {
                try await notificationService.createNotification(appNotification)
                print("✅ Created Firestore notification from system notification: \(request.content.title)")
            } catch {
                print("❌ Error creating Firestore notification: \(error)")
            }
        }
    }

    private func createFirestoreNotificationFromSystemResponse(_ response: UNNotificationResponse) async {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }

        let request = response.notification.request
        let userInfo = request.content.userInfo
        let typeString = userInfo["type"] as? String ?? "daily_recommendations"
        let type = NotificationType(rawValue: typeString) ?? .dailyRecommendations

        // Check if we already have this notification in Firestore (don't duplicate)
        let existingNotifications = try? await notificationService.getNotifications(for: userId)
        let hasExisting = existingNotifications?.contains { notification in
            notification.title == request.content.title &&
                notification.message == request.content.body &&
                Calendar.current.isDate(notification.timestamp, inSameDayAs: Date()) &&
                notification.type == type
        } ?? false

        if !hasExisting {
            let appNotification = AppNotification(
                userId: userId,
                type: type,
                title: request.content.title,
                message: request.content.body
            )

            do {
                // Don't call createNotification here to avoid creating a system notification again
                try await notificationService.createNotificationWithoutSystemSync(appNotification)
                print("✅ Created Firestore notification from user interaction: \(request.content.title)")
            } catch {
                print("❌ Error creating Firestore notification from user interaction: \(error)")
            }
        }
    }

    // MARK: - Background Task Support

    func setupBackgroundTasks() {
        // Cette méthode pourra être utilisée plus tard pour configurer les tâches en arrière-plan
        // si nous implémentons BGTaskScheduler pour une génération vraiment en arrière-plan
        print("ℹ️ Configuration des tâches en arrière-plan (à implémenter)")
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let recommendationsGenerated = Notification.Name("recommendationsGenerated")
    static let selectedMovieExpired = Notification.Name("selectedMovieExpired")
}
