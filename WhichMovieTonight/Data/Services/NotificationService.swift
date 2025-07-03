//
//  NotificationService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseAnalytics
import Foundation
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    // MARK: - Published Properties

    @Published var isNotificationsEnabled = false
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Private Properties

    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard

    // Notification identifiers
    private let dailyNotificationIdentifier = "daily-movie-recommendations"

    // UserDefaults keys
    private let lastNotificationDateKey = "lastNotificationDate"
    private let lastNotificationMessageKey = "lastNotificationMessage"
    private let lastNotificationTimeKey = "lastNotificationTime"

    // MARK: - Notification Messages

    private let notificationMessages = [
        "🍿 Your AI movie buddy misses you! Come get some fresh recommendations!",
        "🎬 Popcorn's ready! Time to discover your next movie crush!",
        "🎪 Your daily dose of cinematic awesomeness is ready!",
    ]

    // MARK: - Initialization

    init() {
        checkNotificationPermissionStatus()
    }

    // MARK: - Permission Management

    /// Request notification permissions from the user
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])

            await MainActor.run {
                isNotificationsEnabled = granted
                permissionStatus = granted ? .authorized : .denied
            }

            if granted {
                print("✅ Notification permissions granted")
                await scheduleDailyNotification()
            } else {
                print("❌ Notification permissions denied")
            }

            return granted
        } catch {
            print("❌ Error requesting notification permissions: \(error)")
            return false
        }
    }

    /// Check current notification permission status
    func checkNotificationPermissionStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.permissionStatus = settings.authorizationStatus
                self?.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Badge Management

    /// Clear the app badge immediately when app opens
    func clearAppBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("🧹 App badge cleared")
    }

    /// Set the app badge to a specific number (only used when sending notifications)
    private func setAppBadge(_ number: Int) {
        UIApplication.shared.applicationIconBadgeNumber = number
        print("📱 App badge set to \(number)")
    }

    // MARK: - Daily Notification Scheduling

    /// Schedule the daily notification with random time and message
    func scheduleDailyNotification() async {
        guard isNotificationsEnabled else {
            print("⚠️ Cannot schedule notification - permissions not granted")
            return
        }

        // Remove any existing daily notifications
        await removeDailyNotification()

        // Generate random time between 10:00 AM and 11:30 AM
        let randomTime = generateRandomNotificationTime()
        let randomMessage = notificationMessages.randomElement() ?? notificationMessages[0]

        // Store the scheduled time and message for tracking
        userDefaults.set(randomTime, forKey: lastNotificationTimeKey)
        userDefaults.set(randomMessage, forKey: lastNotificationMessageKey)

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "WhichMovieTonight"
        content.body = randomMessage
        content.sound = .default
        content.badge = 1 // Set badge to 1 when notification is sent

        // Create trigger for the random time
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: randomTime,
            repeats: false
        )

        // Create notification request
        let request = UNNotificationRequest(
            identifier: dailyNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        // Schedule the notification
        do {
            try await notificationCenter.add(request)
            print("✅ Daily notification scheduled for \(randomTime)")

            // Track notification scheduling in analytics
            await trackNotificationScheduled(time: randomTime, message: randomMessage)

        } catch {
            print("❌ Error scheduling daily notification: \(error)")
        }
    }

    /// Remove the daily notification
    func removeDailyNotification() async {
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyNotificationIdentifier])
        print("🗑️ Daily notification removed")
    }

    /// Generate a random time between 10:00 AM and 11:30 AM
    private func generateRandomNotificationTime() -> DateComponents {
        let calendar = Calendar.current
        let now = Date()

        // Get tomorrow's date
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            // Fallback to today if tomorrow calculation fails
            return DateComponents(hour: 10, minute: 30)
        }

        // Generate random hour between 10 and 11
        let randomHour = Int.random(in: 10 ... 11)

        // Generate random minute
        let randomMinute: Int
        if randomHour == 10 {
            // If hour is 10, minute can be 0-59
            randomMinute = Int.random(in: 0 ... 59)
        } else {
            // If hour is 11, minute can only be 0-30 (to stay within 11:30 limit)
            randomMinute = Int.random(in: 0 ... 30)
        }

        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = randomHour
        components.minute = randomMinute
        components.second = 0

        return components
    }

    // MARK: - Notification Handling

    /// Handle when user taps on notification
    func handleNotificationTap() {
        // Clear badge immediately when notification is tapped
        clearAppBadge()

        // Track notification tap in analytics
        Task {
            await trackNotificationTapped()
        }

        print("👆 Notification tapped - badge cleared and analytics tracked")
    }

    /// Handle when app opens from notification
    func handleAppOpenedFromNotification() {
        // Clear badge immediately when app opens
        clearAppBadge()

        // Track app opened from notification in analytics
        Task {
            await trackAppOpenedFromNotification()
        }

        print("📱 App opened from notification - badge cleared and analytics tracked")
    }

    // MARK: - Analytics Tracking

    /// Track when notification is scheduled
    private func trackNotificationScheduled(time: DateComponents, message: String) async {
        let timeString = "\(time.hour ?? 0):\(String(format: "%02d", time.minute ?? 0))"

        Analytics.logEvent("notification_scheduled", parameters: [
            "time": timeString,
            "message": message,
        ])

        print("📊 Analytics: notification_scheduled - time: \(timeString), message: \(message)")
    }

    /// Track when notification is tapped
    private func trackNotificationTapped() async {
        let message = userDefaults.string(forKey: lastNotificationMessageKey) ?? "unknown"
        let time = userDefaults.string(forKey: lastNotificationTimeKey) ?? "unknown"

        Analytics.logEvent("notification_tapped", parameters: [
            "message": message,
            "scheduled_time": time,
        ])

        print("📊 Analytics: notification_tapped - message: \(message), time: \(time)")
    }

    /// Track when app is opened from notification
    func trackAppOpenedFromNotification() async {
        Analytics.logEvent("app_opened_from_notification", parameters: [:])
        print("📊 Analytics: app_opened_from_notification")
    }

    /// Track when recommendations are generated after notification
    func trackRecommendationsGeneratedAfterNotification() async {
        Analytics.logEvent("recommendations_generated_after_notification", parameters: [:])
        print("📊 Analytics: recommendations_generated_after_notification")
    }

    // MARK: - Settings Helper

    /// Get a user-friendly description of notification status
    var notificationStatusDescription: String {
        switch permissionStatus {
        case .authorized:
            return "Notifications are enabled"
        case .denied:
            return "Enable notifications to never miss your daily movie recommendations"
        case .notDetermined:
            return "Allow notifications for daily movie recommendations"
        case .provisional:
            return "Provisional notifications enabled"
        case .ephemeral:
            return "Ephemeral notifications enabled"
        @unknown default:
            return "Unknown notification status"
        }
    }

    /// Check if we should show permission reminder in settings
    var shouldShowPermissionReminder: Bool {
        return permissionStatus == .denied
    }
}
