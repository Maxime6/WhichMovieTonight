import Foundation

enum OnboardingStep: Int, CaseIterable {
    case valueProposition = 0
    case personalInfo = 1
    case genreSelection = 2
    case actorSelection = 3
    case streamingPlatforms = 4
    case notifications = 5
    case complete = 6

    var title: String {
        switch self {
        case .valueProposition:
            return "Welcome to WMT"
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
        case .valueProposition, .personalInfo, .genreSelection, .streamingPlatforms, .notifications, .complete:
            return true
        case .actorSelection:
            return false
        }
    }

    var canGoBack: Bool {
        switch self {
        case .valueProposition:
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
