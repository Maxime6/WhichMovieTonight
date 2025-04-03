import Foundation

// MARK: - Movie Genres

enum MovieGenre: String, CaseIterable, Identifiable {
    case action = "Action"
    case adventure = "Adventure"
    case animation = "Animation"
    case comedy = "Comedy"
    case crime = "Crime"
    case documentary = "Documentary"
    case drama = "Drama"
    case family = "Family"
    case fantasy = "Fantasy"
    case horror = "Horror"
    case mystery = "Mystery"
    case romance = "Romance"
    case scienceFiction = "Science Fiction"
    case thriller = "Thriller"
    case western = "Western"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .action: return "flame.fill"
        case .adventure: return "map.fill"
        case .animation: return "sparkles.fill"
        case .comedy: return "face.smiling.fill"
        case .crime: return "lock.fill"
        case .documentary: return "camera.fill"
        case .drama: return "theatermasks.fill"
        case .family: return "house.fill"
        case .fantasy: return "wand.and.stars"
        case .horror: return "ghost.fill"
        case .mystery: return "magnifyingglass.fill"
        case .romance: return "heart.fill"
        case .scienceFiction: return "star.fill"
        case .thriller: return "bolt.fill"
        case .western: return "sun.dust.fill"
        }
    }
}

// MARK: - Streaming Platforms

enum StreamingPlatform: String, CaseIterable, Identifiable {
    case netflix = "Netflix"
    case primeVideo = "Prime Video"
    case appleTV = "Apple TV+"
    case disneyPlus = "Disney+"
    case paramountPlus = "Paramount+"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .netflix: return "play.tv.fill"
        case .primeVideo: return "play.square.fill"
        case .appleTV: return "appletv.fill"
        case .disneyPlus: return "sparkles.tv.fill"
        case .paramountPlus: return "play.circle.fill"
        }
    }
}

// MARK: - Mood

enum Mood: String, CaseIterable, Identifiable {
    case happy = "Happy"
    case relaxed = "Relaxed"
    case excited = "Excited"
    case sad = "Sad"
    case tired = "Tired"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .happy: return "face.smiling.fill"
        case .relaxed: return "zzz"
        case .excited: return "star.fill"
        case .sad: return "cloud.rain.fill"
        case .tired: return "powersleep"
        }
    }

    var description: String {
        switch self {
        case .happy: return "I want something light and fun"
        case .relaxed: return "I want something easy to watch"
        case .excited: return "I want something thrilling"
        case .sad: return "I want something uplifting"
        case .tired: return "I want something not too intense"
        }
    }
}
