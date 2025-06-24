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

        // Configure Dependency Injection
        DependencyManager.registerAllDependencies()

        // Set up notification handling
        UNUserNotificationCenter.current().delegate = self

        print("✅ App initialized with Firebase and DI container")

        return true
    }
}

// MARK: - Notification Delegate

extension Appdelegate: UNUserNotificationCenterDelegate {
    // Called when app is in foreground and notification is received
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 Notification reçue en foreground: \(notification.request.identifier)")

        // Handle background recommendation generation
        if notification.request.identifier == "generate-recommendations" {
            print("🔄 Déclenchement de la génération de recommandations")
            Task { @MainActor in
                await handleBackgroundRecommendationGeneration()
            }
            // Don't show this notification to user
            completionHandler([])
        } else {
            // Show other notifications normally with modern iOS 14+ options
            completionHandler([.banner, .list, .sound, .badge])
        }
    }

    // Called when user taps on notification
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👤 Utilisateur a interagi avec la notification: \(response.notification.request.identifier)")

        // Let the DailyNotificationService handle the response
        let notificationService = DIContainer.shared.resolve(DailyNotificationServiceProtocol.self)
        notificationService.handleNotificationResponse(response)

        completionHandler()
    }

    @MainActor
    private func handleBackgroundRecommendationGeneration() async {
        print("🎬 Démarrage de la génération de recommandations en arrière-plan")

        // Post notification to trigger recommendation generation
        NotificationCenter.default.post(name: .shouldGenerateRecommendations, object: nil)
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
