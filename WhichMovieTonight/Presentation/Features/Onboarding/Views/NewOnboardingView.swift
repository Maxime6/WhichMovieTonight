import SwiftUI

struct NewOnboardingView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var stepManager: OnboardingStepManager

    init(userProfileService: UserProfileService) {
        _stepManager = StateObject(wrappedValue: OnboardingStepManager(userProfileService: userProfileService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            VStack(spacing: 8) {
                OnboardingProgressBar(progress: stepManager.progress)

                Text("Step \(stepManager.currentStepIndex + 1) of \(stepManager.totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)

            // Current step content
            currentStepView
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            // Navigation buttons
            OnboardingNavigationButtons(
                canGoBack: stepManager.currentStep.canGoBack,
                canProceed: stepManager.canProceedToNextStep,
                canSkip: stepManager.currentStep.canSkip,
                isLastStep: stepManager.currentStep == .complete,
                isLoading: stepManager.isLoading,
                validationMessage: stepManager.validationMessage,
                onBack: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        stepManager.previousStep()
                    }
                },
                onNext: {
                    if stepManager.currentStep == .complete {
                        // Handle completion in the complete view
                        return
                    }

                    withAnimation(.easeInOut(duration: 0.3)) {
                        stepManager.nextStep()
                    }
                },
                onSkip: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        stepManager.skipCurrentStep()
                    }
                }
            )
            .padding(.bottom)
        }
        .environmentObject(stepManager)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch stepManager.currentStep {
        case .valueProposition:
            ValuePropositionView()
                .environmentObject(stepManager)

        case .personalInfo:
            PersonalInfoView()
                .environmentObject(stepManager)
                .environmentObject(userProfileService)

        case .genreSelection:
            GenreSelectionView()
                .environmentObject(userProfileService)

        case .actorSelection:
            ActorSelectionView()
                .environmentObject(userProfileService)

        case .streamingPlatforms:
            StreamingPlatformSelectionView()
                .environmentObject(userProfileService)

        case .notifications:
            NotificationPermissionView()
                .environmentObject(notificationService)

        case .complete:
            OnboardingCompleteView()
                .environmentObject(stepManager)
        }
    }
}

#Preview {
    NewOnboardingView(userProfileService: UserProfileService())
        .environmentObject(NotificationService())
}
