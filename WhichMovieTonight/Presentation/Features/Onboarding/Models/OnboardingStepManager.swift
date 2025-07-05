import FirebaseAuth
import Foundation

@MainActor
class OnboardingStepManager: ObservableObject {
    @Published var currentStep: OnboardingStep = .personalInfo

    @Published var isLoading = false
    @Published var errorMessage: String?

    let userProfileService: UserProfileService

    init(userProfileService: UserProfileService) {
        self.userProfileService = userProfileService
    }

    // MARK: - Navigation

    func nextStep() {
        guard canProceedToNextStep else { return }

        if let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep)?.advanced(by: 1),
           nextIndex < OnboardingStep.allCases.count
        {
            currentStep = OnboardingStep.allCases[nextIndex]
        }
    }

    func previousStep() {
        guard currentStep.canGoBack else { return }

        if let previousIndex = OnboardingStep.allCases.firstIndex(of: currentStep)?.advanced(by: -1),
           previousIndex >= 0
        {
            currentStep = OnboardingStep.allCases[previousIndex]
        }
    }

    func skipCurrentStep() {
        guard currentStep.canSkip else { return }
        nextStep()
    }

    // MARK: - Validation

    var canProceedToNextStep: Bool {
        switch currentStep {
        case .personalInfo:
            return !userProfileService.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .genreSelection:
            return userProfileService.favoriteGenres.count >= 1
        case .actorSelection:
            return true // Optional step
        case .streamingPlatforms:
            return userProfileService.favoriteStreamingPlatforms.count >= 1
        case .notifications:
            return true // Can proceed regardless of notification choice
        case .complete:
            return false // Final step
        }
    }

    var validationMessage: String? {
        switch currentStep {
        case .personalInfo:
            return userProfileService.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Please enter your name" : nil
        case .genreSelection:
            return userProfileService.favoriteGenres.isEmpty ? "Please select at least 1 movie genre" : nil
        case .actorSelection:
            return nil // Optional step
        case .streamingPlatforms:
            return userProfileService.favoriteStreamingPlatforms.isEmpty ? "Please select at least 1 streaming platform" : nil
        case .notifications:
            return nil // Can proceed regardless
        case .complete:
            return nil
        }
    }

    // MARK: - Completion

    func completeOnboarding() async {
        isLoading = true
        errorMessage = nil

        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            isLoading = false
            return
        }

        do {
            // Save all onboarding data to Firebase
            try await userProfileService.saveUserPreferences(userId: userId)
            print("✅ Onboarding completed - preferences saved to Firebase")

            // Move to complete step
            currentStep = .complete

        } catch {
            print("⚠️ Failed to save preferences during onboarding: \(error)")
            errorMessage = "Failed to save your preferences. Please try again."
        }

        isLoading = false
    }

    // MARK: - Progress

    var progress: Double {
        return currentStep.progress
    }

    var currentStepIndex: Int {
        return OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
    }

    var totalSteps: Int {
        return OnboardingStep.allCases.count
    }
}
