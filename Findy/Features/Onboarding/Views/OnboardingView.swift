import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            // Background
            FindyColors.backgroundPrimary
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: viewModel.progress)
                    .tint(FindyColors.neonBlue)
                    .padding(.horizontal)

                // Main content
                ScrollView {
                    VStack(spacing: FindyLayout.largeSpacing) {
                        // Header
                        VStack(spacing: FindyLayout.spacing) {
                            Text(viewModel.currentStep.title)
                                .font(FindyTypography.title)
                                .foregroundColor(FindyColors.textPrimary)
                                .multilineTextAlignment(.center)
                                .neonGlow()

                            Text(viewModel.currentStep.description)
                                .font(FindyTypography.body)
                                .foregroundColor(FindyColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, FindyLayout.largeSpacing)

                        // Step content
                        Group {
                            switch viewModel.currentStep {
                            case .welcome:
                                welcomeView
                            case .nickname:
                                nicknameView
                            case .birthDate:
                                birthDateView
                            case .genres:
                                genresView
                            case .platforms:
                                platformsView
                            case .mood:
                                moodView
                            case .completed:
                                completedView
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    }
                    .padding()
                }

                // Navigation buttons
                navigationButtons
                    .padding()
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: FindyLayout.spacing) {
            if viewModel.currentStep != .welcome {
                FindyButton("Back", style: .ghost) {
                    viewModel.previousStep()
                }
            }

            FindyButton(viewModel.currentStep == .completed ? "Get Started" : "Continue") {
                if viewModel.currentStep == .completed {
                    viewModel.completeOnboarding()
                } else {
                    viewModel.nextStep()
                }
            }
            .opacity(viewModel.canProceed ? 1 : 0.5)
            .disabled(!viewModel.canProceed)
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: FindyLayout.largeSpacing) {
            Image(.findyIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .foregroundColor(FindyColors.neonBlue)
                .neonGlow()

            Text("Your personal AI movie recommender")
                .font(FindyTypography.headline)
                .foregroundColor(FindyColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, FindyLayout.largeSpacing)
    }

    // MARK: - Nickname View

    private var nicknameView: some View {
        VStack(spacing: FindyLayout.largeSpacing) {
            FindyCard {
                VStack(spacing: FindyLayout.spacing) {
                    TextField("Enter your nickname", text: $viewModel.nickname)
                        .font(FindyTypography.body)
                        .foregroundColor(FindyColors.textPrimary)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Rectangle()
                        .fill(FindyColors.textSecondary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, FindyLayout.spacing)
            }

            if !viewModel.nickname.isEmpty {
                Text("We'll call you \(viewModel.nickname)!")
                    .font(FindyTypography.body)
                    .foregroundColor(FindyColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Birth Date View

    private var birthDateView: some View {
        VStack(spacing: FindyLayout.largeSpacing) {
            FindyCard {
                DatePicker(
                    "Birth Date",
                    selection: $viewModel.birthDate,
                    in: viewModel.minimumDate ... viewModel.maximumDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .environment(\.locale, .current)
            }

            if viewModel.age > 0 {
                Text("You are \(viewModel.age) years old")
                    .font(FindyTypography.body)
                    .foregroundColor(FindyColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Genres View

    private var genresView: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: FindyLayout.spacing
        ) {
            ForEach(MovieGenre.allCases) { genre in
                OnboardingSelectionButton(
                    title: genre.rawValue,
                    icon: genre.icon,
                    isSelected: viewModel.selectedGenres.contains(genre)
                ) {
                    viewModel.toggleGenre(genre)
                }
            }
        }
    }

    // MARK: - Platforms View

    private var platformsView: some View {
        VStack(spacing: FindyLayout.spacing) {
            ForEach(StreamingPlatform.allCases) { platform in
                OnboardingSelectionButton(
                    title: platform.rawValue,
                    icon: platform.icon,
                    isSelected: viewModel.selectedPlatforms.contains(platform)
                ) {
                    viewModel.togglePlatform(platform)
                }
            }
        }
    }

    // MARK: - Mood View

    private var moodView: some View {
        VStack(spacing: FindyLayout.largeSpacing) {
            ForEach(Mood.allCases) { mood in
                FindyCard(
                    glowColor: viewModel.selectedMood == mood ? FindyColors.neonBlue : .clear,
                    isInteractive: true
                ) {
                    HStack {
                        VStack(alignment: .leading, spacing: FindyLayout.spacing) {
                            Text(mood.rawValue)
                                .font(FindyTypography.headline)
                                .foregroundColor(FindyColors.textPrimary)

                            Text(mood.description)
                                .font(FindyTypography.body)
                                .foregroundColor(FindyColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: mood.icon)
                            .font(.system(size: FindyLayout.largeIconSize))
                            .foregroundColor(viewModel.selectedMood == mood ? FindyColors.neonBlue : FindyColors.textSecondary)
                    }
                }
                .onTapGesture {
                    viewModel.selectMood(mood)
                }
            }
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: FindyLayout.largeSpacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(FindyColors.neonBlue)
                .neonGlow()

            VStack(spacing: FindyLayout.spacing) {
                Text("Profile Created!")
                    .font(FindyTypography.headline)
                    .foregroundColor(FindyColors.textPrimary)

                Text("Time to discover your next favorite movie")
                    .font(FindyTypography.body)
                    .foregroundColor(FindyColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, FindyLayout.largeSpacing)
    }
}

#Preview {
    OnboardingView()
}
