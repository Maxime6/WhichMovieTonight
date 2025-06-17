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
    func cancelAllNotifications()
}

final class DailyNotificationService: DailyNotificationServiceProtocol {
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification permission granted: \(granted)")
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
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

        // Planifier pour 8h chaque jour
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
                print("Erreur lors de la programmation de la notification: \(error)")
            } else {
                print("Notification quotidienne programmée pour 8h")
            }
        }
    }

    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("Toutes les notifications ont été annulées")
    }

    // MARK: - Notification Handling

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        // Cette méthode peut être appelée depuis AppDelegate ou SceneDelegate
        // pour gérer les actions sur les notifications

        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // L'utilisateur a tapé sur la notification
            print("Utilisateur a ouvert l'app via la notification")
            // Ici on pourrait poster une notification pour que l'app génère les recommandations
            NotificationCenter.default.post(name: .shouldGenerateRecommendations, object: nil)

        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let shouldGenerateRecommendations = Notification.Name("shouldGenerateRecommendations")
    static let recommendationsGenerated = Notification.Name("recommendationsGenerated")
}
