//
//  DailyNotificationService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation
import UserNotifications

protocol DailyNotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleDailyRecommendationNotification()
    func scheduleRecommendationGeneration()
    func cancelAllNotifications()
    func handleNotificationResponse(_ response: UNNotificationResponse)
    func setupBackgroundTasks()
}

final class DailyNotificationService: DailyNotificationServiceProtocol {
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
        content.title = "🎬 Vos films du jour sont prêts !"
        content.body = "Découvrez 5 nouveaux films sélectionnés spécialement pour vous"
        content.sound = .default
        content.badge = 1

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

        // Ajouter la notification
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

        // Ajouter la notification
        center.add(request) { error in
            if let error = error {
                print("❌ Erreur lors de la programmation de la génération: \(error)")
            } else {
                print("✅ Génération de recommandations programmée pour 6h")
            }
        }
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
            // L'app s'ouvre avec les recommandations déjà prêtes

        default:
            break
        }
    }

    // MARK: - Background Task Support

    func setupBackgroundTasks() {
        // Cette méthode pourra être utilisée plus tard pour configurer les tâches en arrière-plan
        // si nous implémentons BGTaskScheduler pour une génération vraiment en arrière-plan
        print("ℹ️ Configuration des tâches en arrière-plan (à implémenter)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let shouldGenerateRecommendations = Notification.Name("shouldGenerateRecommendations")
    static let recommendationsGenerated = Notification.Name("recommendationsGenerated")
    static let selectedMovieExpired = Notification.Name("selectedMovieExpired")
}
