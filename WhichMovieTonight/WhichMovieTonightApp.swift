//
//  WhichMovieTonightApp.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseCore
import FirebaseFirestore
import SwiftUI
import UserNotifications

class Appdelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self

        print("✅ App initialized with Firebase")

        return true
    }
}

// MARK: - Notification Delegate

extension Appdelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 Notification reçue en foreground: \(notification.request.identifier)")

        if notification.request.identifier == "generate-recommendations" {
            print("🔄 Déclenchement de la génération de recommandations")
            Task { @MainActor in
                await handleBackgroundRecommendationGeneration()
            }
            completionHandler([])
        } else {
            completionHandler([.banner, .list, .sound, .badge])
        }
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👤 Utilisateur a interagi avec la notification: \(response.notification.request.identifier)")

        // TODO: Handle notification response with simplified notification system

        completionHandler()
    }

    @MainActor
    private func handleBackgroundRecommendationGeneration() async {
        print("🎬 Démarrage de la génération de recommandations en arrière-plan")

        // Removed notification system in V1 simplification
    }
}

@main
struct WhichMovieTonightApp: App {
    @UIApplicationDelegateAdaptor(Appdelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
