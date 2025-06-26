import Foundation

// MARK: - App Notification Model

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let actionData: [String: String]? // Pour stocker des données supplémentaires si besoin

    init(
        userId: String,
        type: NotificationType,
        title: String,
        message: String,
        actionData: [String: String]? = nil
    ) {
        id = UUID().uuidString
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        timestamp = Date()
        isRead = false
        self.actionData = actionData
    }

    // Custom initializer for data from Firestore
    init(
        id: String,
        userId: String,
        type: NotificationType,
        title: String,
        message: String,
        timestamp: Date,
        isRead: Bool,
        actionData: [String: String]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.actionData = actionData
    }
}

// MARK: - Notification Types

enum NotificationType: String, Codable, CaseIterable {
    case dailyRecommendations = "daily_recommendations"
    case watchMovieReminder = "watch_movie_reminder"
    case movieWatchConfirmation = "movie_watch_confirmation"
    case newMovieAvailable = "new_movie_available"
    case favoriteMovieAvailable = "favorite_movie_available"
    case customReminder = "custom_reminder"
    case systemUpdate = "system_update"

    var iconName: String {
        switch self {
        case .dailyRecommendations:
            return "film.stack"
        case .watchMovieReminder:
            return "clock.fill"
        case .movieWatchConfirmation:
            return "questionmark.circle.fill"
        case .newMovieAvailable:
            return "sparkles"
        case .favoriteMovieAvailable:
            return "heart.fill"
        case .customReminder:
            return "bell.fill"
        case .systemUpdate:
            return "gear"
        }
    }

    var color: String {
        switch self {
        case .dailyRecommendations:
            return "blue"
        case .watchMovieReminder:
            return "orange"
        case .movieWatchConfirmation:
            return "purple"
        case .newMovieAvailable:
            return "green"
        case .favoriteMovieAvailable:
            return "red"
        case .customReminder:
            return "indigo"
        case .systemUpdate:
            return "gray"
        }
    }
}

// MARK: - Notification Extensions

extension AppNotification {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(timestamp)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        if isToday {
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        }
    }
}
