import Combine
import FirebaseAuth
import Foundation

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Injected private var notificationService: NotificationServiceProtocol
    @Injected private var dailyNotificationService: DailyNotificationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotificationObservers()
        Task {
            await synchronizeAndLoadNotifications()
        }
    }

    private func setupNotificationObservers() {
        // Listen for new notifications
        NotificationCenter.default.publisher(for: .newNotificationReceived)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.synchronizeAndLoadNotifications()
                }
            }
            .store(in: &cancellables)

        // Listen for recommendation generated notifications
        NotificationCenter.default.publisher(for: .recommendationsGenerated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                Task {
                    if let movies = notification.object as? [Movie] {
                        await self?.createRecommendationNotification(movieCount: movies.count)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func synchronizeAndLoadNotifications() async {
        // First synchronize system notifications with Firestore
        await dailyNotificationService.synchronizeSystemNotifications()

        // Clean up any duplicate notifications
        await cleanupDuplicateNotifications()

        // Then load all notifications
        await loadNotifications()

        // Update system badge count on main thread
        Task { @MainActor in
            dailyNotificationService.updateBadgeCount(unreadCount)
        }
    }

    private func cleanupDuplicateNotifications() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            let allNotifications = try await notificationService.getNotifications(for: userId)

            // Group by title, message, and date to find duplicates
            var uniqueNotifications: [String: AppNotification] = [:]
            var duplicatesToDelete: [String] = []

            for notification in allNotifications {
                let dateString = DateFormatter().string(from: notification.timestamp)
                let key = "\(notification.title)-\(notification.message)-\(dateString)-\(notification.type.rawValue)"

                if uniqueNotifications[key] == nil {
                    uniqueNotifications[key] = notification
                } else {
                    // Keep the most recent one, delete the older one
                    let existing = uniqueNotifications[key]!
                    if notification.timestamp > existing.timestamp {
                        duplicatesToDelete.append(existing.id)
                        uniqueNotifications[key] = notification
                    } else {
                        duplicatesToDelete.append(notification.id)
                    }
                }
            }

            // Delete duplicates
            for duplicateId in duplicatesToDelete {
                try? await notificationService.deleteNotification(duplicateId, for: userId)
                dailyNotificationService.removeSystemNotification(duplicateId)
            }

            if !duplicatesToDelete.isEmpty {
                print("🧹 Cleaned up \(duplicatesToDelete.count) duplicate notifications")
            }

        } catch {
            print("❌ Error cleaning up duplicates: \(error)")
        }
    }

    func loadNotifications() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No authenticated user for notifications")
            return
        }

        do {
            Task { @MainActor in
                isLoading = true
                errorMessage = nil
            }

            let fetchedNotifications = try await notificationService.getNotifications(for: userId)
            let fetchedUnreadCount = try await notificationService.getUnreadCount(for: userId)

            Task { @MainActor in
                notifications = fetchedNotifications
                unreadCount = fetchedUnreadCount
            }

            print("✅ Loaded \(notifications.count) notifications, \(unreadCount) unread")
        } catch {
            print("❌ Error loading notifications: \(error)")
            Task { @MainActor in
                errorMessage = "Failed to load notifications"
            }
        }

        Task { @MainActor in
            isLoading = false
        }
    }

    func markAsRead(_ notificationId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await notificationService.markAsRead(notificationId, for: userId)

                // Remove corresponding system notification
                dailyNotificationService.removeSystemNotification(notificationId)

                // Update local state
                Task { @MainActor in
                    if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                        notifications[index].isRead = true
                        unreadCount = max(0, unreadCount - 1)

                        // Update system badge count
                        dailyNotificationService.updateBadgeCount(unreadCount)
                    }
                }
            } catch {
                print("❌ Error marking notification as read: \(error)")
            }
        }
    }

    func markAllAsRead() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await notificationService.markAllAsRead(for: userId)

                // Remove all corresponding system notifications
                for notification in notifications where !notification.isRead {
                    dailyNotificationService.removeSystemNotification(notification.id)
                }

                // Update local state
                Task { @MainActor in
                    for index in notifications.indices {
                        notifications[index].isRead = true
                    }
                    unreadCount = 0

                    // Update system badge count
                    dailyNotificationService.updateBadgeCount(0)
                }
            } catch {
                print("❌ Error marking all notifications as read: \(error)")
            }
        }
    }

    func deleteNotification(_ notificationId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await notificationService.deleteNotification(notificationId, for: userId)

                // Remove corresponding system notification
                dailyNotificationService.removeSystemNotification(notificationId)

                // Update local state
                Task { @MainActor in
                    if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                        let wasUnread = !notifications[index].isRead
                        notifications.remove(at: index)

                        if wasUnread {
                            unreadCount = max(0, unreadCount - 1)

                            // Update system badge count
                            dailyNotificationService.updateBadgeCount(unreadCount)
                        }
                    }
                }
            } catch {
                print("❌ Error deleting notification: \(error)")
            }
        }
    }

    // MARK: - Create Notifications

    func createRecommendationNotification(movieCount: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await notificationService.createDailyRecommendationNotification(
                    for: userId,
                    movieCount: movieCount
                )

                // Refresh notifications to include the new one
                await loadNotifications()

                // Post notification for badge animation
                Task { @MainActor in
                    NotificationCenter.default.post(name: .newNotificationReceived, object: nil)
                }
            } catch {
                print("❌ Error creating recommendation notification: \(error)")
            }
        }
    }

    func createWatchConfirmation(movieTitle: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await notificationService.createMovieWatchConfirmation(
                    for: userId,
                    movieTitle: movieTitle
                )

                await loadNotifications()

                Task { @MainActor in
                    NotificationCenter.default.post(name: .newNotificationReceived, object: nil)
                }
            } catch {
                print("❌ Error creating watch confirmation: \(error)")
            }
        }
    }

    func createWatchReminder(movieTitle: String, reminderTime: Date) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await notificationService.createWatchReminder(
                    for: userId,
                    movieTitle: movieTitle,
                    reminderTime: reminderTime
                )

                await loadNotifications()

                Task { @MainActor in
                    NotificationCenter.default.post(name: .newNotificationReceived, object: nil)
                }
            } catch {
                print("❌ Error creating watch reminder: \(error)")
            }
        }
    }
}
