import Combine
import FirebaseAuth
import Foundation

// MARK: - NotificationCenter Extensions

extension NSNotification.Name {
    static let newNotificationReceived = NSNotification.Name("newNotificationReceived")
}

// MARK: - Notification Service Protocol

protocol NotificationServiceProtocol {
    func createNotification(_ notification: AppNotification) async throws
    func createNotificationWithoutSystemSync(_ notification: AppNotification) async throws
    func getNotifications(for userId: String) async throws -> [AppNotification]
    func getUnreadCount(for userId: String) async throws -> Int
    func markAsRead(_ notificationId: String, for userId: String) async throws
    func markAllAsRead(for userId: String) async throws
    func deleteNotification(_ notificationId: String, for userId: String) async throws

    // Convenience methods for creating specific notification types
    func createDailyRecommendationNotification(for userId: String, movieCount: Int) async throws
    func createMovieWatchConfirmation(for userId: String, movieTitle: String) async throws
    func createWatchReminder(for userId: String, movieTitle: String, reminderTime: Date) async throws
}

// MARK: - Notification Service Implementation

final class NotificationService: NotificationServiceProtocol {
    @Injected private var firestoreService: FirestoreServiceProtocol
    @Injected private var dailyNotificationService: DailyNotificationServiceProtocol

    // MARK: - Core Methods

    func createNotification(_ notification: AppNotification) async throws {
        // Create Firestore notification
        try await firestoreService.saveNotification(notification)
        print("✅ Notification created in Firestore: \(notification.title)")

        // Create corresponding system notification (for in-app notifications)
        // Note: This won't show as a system banner since the app is in foreground
        await dailyNotificationService.createSystemNotificationForFirestore(notification)

        // Post local notification for immediate UI updates
        Task { @MainActor in
            NotificationCenter.default.post(name: .newNotificationReceived, object: notification)
        }
    }

    func createNotificationWithoutSystemSync(_ notification: AppNotification) async throws {
        // Create only Firestore notification (used when syncing from system notifications)
        try await firestoreService.saveNotification(notification)
        print("✅ Notification created in Firestore without system sync: \(notification.title)")

        // Post local notification for immediate UI updates
        Task { @MainActor in
            NotificationCenter.default.post(name: .newNotificationReceived, object: notification)
        }
    }

    func getNotifications(for userId: String) async throws -> [AppNotification] {
        let notifications = try await firestoreService.getNotifications(for: userId)
        // Sort by timestamp, newest first
        return notifications.sorted { $0.timestamp > $1.timestamp }
    }

    func getUnreadCount(for userId: String) async throws -> Int {
        let notifications = try await getNotifications(for: userId)
        return notifications.filter { !$0.isRead }.count
    }

    func markAsRead(_ notificationId: String, for userId: String) async throws {
        try await firestoreService.markNotificationAsRead(notificationId, for: userId)
        print("✅ Notification marked as read: \(notificationId)")
    }

    func markAllAsRead(for userId: String) async throws {
        try await firestoreService.markAllNotificationsAsRead(for: userId)
        print("✅ All notifications marked as read for user: \(userId)")
    }

    func deleteNotification(_ notificationId: String, for userId: String) async throws {
        try await firestoreService.deleteNotification(notificationId, for: userId)
        print("✅ Notification deleted: \(notificationId)")
    }

    // MARK: - Convenience Methods

    func createDailyRecommendationNotification(for userId: String, movieCount: Int) async throws {
        let notification = AppNotification(
            userId: userId,
            type: .dailyRecommendations,
            title: "🎬 Your daily picks are ready!",
            message: "Discover \(movieCount) new movies selected just for you"
        )

        try await createNotification(notification)
    }

    func createMovieWatchConfirmation(for userId: String, movieTitle: String) async throws {
        let notification = AppNotification(
            userId: userId,
            type: .movieWatchConfirmation,
            title: "Did you watch \(movieTitle)?",
            message: "Let us know if you enjoyed your movie selection!",
            actionData: ["movieTitle": movieTitle]
        )

        try await createNotification(notification)
    }

    func createWatchReminder(for userId: String, movieTitle: String, reminderTime: Date) async throws {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: reminderTime)

        let notification = AppNotification(
            userId: userId,
            type: .watchMovieReminder,
            title: "Time to watch \(movieTitle)!",
            message: "Your movie night starts at \(timeString)",
            actionData: ["movieTitle": movieTitle, "reminderTime": timeString]
        )

        try await createNotification(notification)
    }
}
