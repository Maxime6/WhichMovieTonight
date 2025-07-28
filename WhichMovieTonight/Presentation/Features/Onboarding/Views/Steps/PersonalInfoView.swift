import SwiftUI

struct PersonalInfoView: View {
    @EnvironmentObject var stepManager: OnboardingStepManager
    @EnvironmentObject var userProfileService: UserProfileService

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Text("Tell us about yourself")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Help us personalize your movie recommendations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Name Input
                VStack(spacing: 16) {
                    Text("What should we call you?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("Enter your name", text: $userProfileService.displayName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                }

                // Watching Frequency
                VStack(spacing: 16) {
                    Text("How often do you watch movies?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(MovieWatchingFrequency.allCases, id: \.self) { frequency in
                            FrequencyButton(
                                frequency: frequency,
                                isSelected: userProfileService.movieWatchingFrequency == frequency,
                                action: {
                                    userProfileService.movieWatchingFrequency = frequency
                                }
                            )
                        }
                    }
                }

                // Movie Mood Preference
                VStack(spacing: 16) {
                    Text("What's your movie mood?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(MovieMoodPreference.allCases, id: \.self) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: userProfileService.movieMoodPreference == mood,
                                action: {
                                    userProfileService.movieMoodPreference = mood
                                }
                            )
                        }
                    }
                }

                Spacer(minLength: 50)
            }
            .padding(.horizontal)
        }
        .dismissKeyboardOnTap()
    }
}

// MARK: - Frequency Button Component

struct FrequencyButton: View {
    let frequency: MovieWatchingFrequency
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: frequencyIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(frequency.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                    .fill(
                        isSelected
                            ? DesignSystem.primaryGradient
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var frequencyIcon: String {
        switch frequency {
        case .daily:
            return "calendar.circle.fill"
        case .twoThreeTimesWeek:
            return "calendar.badge.clock"
        case .weekly:
            return "calendar"
        case .occasionally:
            return "calendar.badge.exclamationmark"
        }
    }
}

// MARK: - Mood Button Component

struct MoodButton: View {
    let mood: MovieMoodPreference
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: moodIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(mood.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(isSelected ? .cyan : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.black : Color.gray)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var moodIcon: String {
        switch mood {
        case .discover:
            return "magnifyingglass.circle.fill"
        case .familiar:
            return "heart.circle.fill"
        case .both:
            return "star.circle.fill"
        }
    }
}

#Preview {
    PersonalInfoView()
        .environmentObject(OnboardingStepManager(userProfileService: UserProfileService()))
        .environmentObject(UserProfileService())
}
