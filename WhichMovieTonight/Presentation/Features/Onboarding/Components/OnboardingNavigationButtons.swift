import SwiftUI

struct OnboardingNavigationButtons: View {
    let canGoBack: Bool
    let canProceed: Bool
    let canSkip: Bool
    let isLastStep: Bool
    let isLoading: Bool
    let validationMessage: String?
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Validation message
            if let message = validationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Navigation buttons
            HStack(spacing: 16) {
                // Back button
                if canGoBack {
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    .disabled(isLoading)
                }

                // Next/Complete button
                Button(action: onNext) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isLastStep ? "Complete" : "Next")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        if !isLastStep && !isLoading {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                            .fill(
                                canProceed && !isLoading
                                    ? DesignSystem.primaryGradient
                                    : LinearGradient(
                                        colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                    )
                }
                .disabled(!canProceed || isLoading)
            }

            // Skip button (only for optional steps)
            if canSkip && !isLastStep {
                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingNavigationButtons(
            canGoBack: true,
            canProceed: true,
            canSkip: false,
            isLastStep: false,
            isLoading: false,
            validationMessage: nil,
            onBack: {},
            onNext: {},
            onSkip: {}
        )

        OnboardingNavigationButtons(
            canGoBack: false,
            canProceed: false,
            canSkip: false,
            isLastStep: false,
            isLoading: false,
            validationMessage: "Please select at least 1 genre",
            onBack: {},
            onNext: {},
            onSkip: {}
        )

        OnboardingNavigationButtons(
            canGoBack: true,
            canProceed: true,
            canSkip: true,
            isLastStep: false,
            isLoading: false,
            validationMessage: nil,
            onBack: {},
            onNext: {},
            onSkip: {}
        )
    }
    .padding()
}
