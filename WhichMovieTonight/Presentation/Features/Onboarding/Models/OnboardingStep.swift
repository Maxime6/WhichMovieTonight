import Foundation

enum OnboardingStep: Int, CaseIterable {
    case personalInfo = 0
    case genreSelection = 1
    case actorSelection = 2
    case streamingPlatforms = 3
    case notifications = 4
    case complete = 5

    var title: String {
        switch self {
        case .personalInfo:
            return "Tell us about yourself"
        case .genreSelection:
            return "Select your favorite genres"
        case .actorSelection:
            return "Add your favorite actors"
        case .streamingPlatforms:
            return "Choose your streaming platforms"
        case .notifications:
            return "Stay connected"
        case .complete:
            return "You're all set!"
        }
    }

    var isRequired: Bool {
        switch self {
        case .personalInfo, .genreSelection, .streamingPlatforms, .notifications, .complete:
            return true
        case .actorSelection:
            return false
        }
    }

    var canGoBack: Bool {
        switch self {
        case .personalInfo:
            return false // Can't go back from first step
        default:
            return true
        }
    }

    var canSkip: Bool {
        switch self {
        case .actorSelection:
            return true
        default:
            return false
        }
    }

    var progress: Double {
        return Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}
