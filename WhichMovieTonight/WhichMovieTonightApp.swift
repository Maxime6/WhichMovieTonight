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

        // Set up notification delegate
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
        print("📱 Notification received in foreground: \(notification.request.identifier)")

        // Show notification even when app is in foreground
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👤 User tapped notification: \(response.notification.request.identifier)")

        // Handle notification tap
        if response.notification.request.identifier == "daily-movie-recommendations" {
            // Clear badge and track analytics
            // Note: We can't access the shared NotificationService here, so we'll handle this in RootView
            print("📱 Daily notification tapped - will be handled in RootView")
        }

        completionHandler()
    }
}

@main
struct WhichMovieTonightApp: App {
    @UIApplicationDelegateAdaptor(Appdelegate.self) var appDelegate
    @StateObject private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(notificationService)
                .task {
                    // Check notification permission status on app launch
                    await notificationService.checkNotificationPermissionStatus()
                }
        }
    }
}
