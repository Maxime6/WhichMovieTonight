import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedGenres: Set<MovieGenre> = []
    @Published var selectedPlatforms: Set<StreamingPlatform> = []
    @Published var selectedMood: Mood?
    @Published var currentStep: OnboardingStep = .welcome
    @Published var nickname: String = ""
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @Published var isOnboardingCompleted = false

    // MARK: - Computed Properties

    private var calendar: Calendar { Calendar.current }

    var age: Int {
        calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    var minimumDate: Date {
        calendar.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    }

    var maximumDate: Date {
        calendar.date(byAdding: .year, value: -3, to: Date()) ?? Date()
    }

    // MARK: - Onboarding Steps

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case nickname
        case birthDate
        case genres
        case platforms
        case mood
        case completed

        var title: String {
            switch self {
            case .welcome: return "Welcome to Findy"
            case .nickname: return "What's Your Name?"
            case .birthDate: return "When Were You Born?"
            case .genres: return "Select Your Favorite Genres"
            case .platforms: return "Your Streaming Services"
            case .mood: return "How Do You Feel Today?"
            case .completed: return "All Set!"
            }
        }

        var description: String {
            switch self {
            case .welcome:
                return "Let's personalize your movie recommendations"
            case .nickname:
                return "Choose a nickname we'll use to address you"
            case .birthDate:
                return "This helps us recommend age-appropriate content"
            case .genres:
                return "Choose at least 3 movie genres you enjoy watching"
            case .platforms:
                return "Select the streaming platforms you have access to"
            case .mood:
                return "Help us find the perfect movie for your current mood"
            case .completed:
                return "You're ready to discover your next favorite movie!"
            }
        }
    }

    // MARK: - Computed Properties

    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .nickname:
            return nickname.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
        case .birthDate:
            return birthDate <= maximumDate && birthDate >= minimumDate
        case .genres:
            return selectedGenres.count >= 3
        case .platforms:
            return !selectedPlatforms.isEmpty
        case .mood:
            return selectedMood != nil
        case .completed:
            return true
        }
    }

    var progress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    // MARK: - Methods

    func nextStep() {
        guard canProceed else { return }
        guard let nextIndex = OnboardingStep.allCases.firstIndex(where: { $0 == currentStep })?.advanced(by: 1),
              let nextStep = OnboardingStep(rawValue: nextIndex)
        else {
            return
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentStep = nextStep
        }
    }

    func previousStep() {
        guard let previousIndex = OnboardingStep.allCases.firstIndex(where: { $0 == currentStep })?.advanced(by: -1),
              let previousStep = OnboardingStep(rawValue: previousIndex)
        else {
            return
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentStep = previousStep
        }
    }

    func toggleGenre(_ genre: MovieGenre) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedGenres.contains(genre) {
                selectedGenres.remove(genre)
            } else {
                selectedGenres.insert(genre)
            }
        }
    }

    func togglePlatform(_ platform: StreamingPlatform) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedPlatforms.contains(platform) {
                selectedPlatforms.remove(platform)
            } else {
                selectedPlatforms.insert(platform)
            }
        }
    }

    func selectMood(_ mood: Mood) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedMood = mood
        }
    }

    func completeOnboarding() {
        // TODO: Save user preferences
        withAnimation {
            isOnboardingCompleted = true
        }
    }
}
