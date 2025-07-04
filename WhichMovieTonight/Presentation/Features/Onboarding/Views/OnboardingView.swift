//
//  OnboardingView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 21/05/2025.
//

import FirebaseAuth
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showAuthentication = false

    var body: some View {
        ZStack {
            VStack {
                TabView(selection: $viewModel.currentPage) {
                    ForEach(OnboardingSlide.slides.indices, id: \.self) { index in
                        let slide = OnboardingSlide.slides[index]
                        if slide.isGenreSelection {
                            GenreSelectionView()
                                .environmentObject(userProfileService)
                                .tag(index)
                        } else if slide.isActorSelection {
                            ActorSelectionView()
                                .environmentObject(userProfileService)
                                .tag(index)
                        } else if slide.isStreamingPlatformSelection {
                            StreamingPlatformSelectionView()
                                .environmentObject(userProfileService)
                                .tag(index)
                        } else if slide.isNotificationPermission {
                            NotificationPermissionView()
                                .environmentObject(notificationService)
                                .tag(index)
                        } else {
                            OnboardingSlideView(slide: slide)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack {
                    OnboardingActionButton(
                        title: viewModel.currentPage == OnboardingSlide.slides.count - 1 ? "Commencer" : "Suivant",
                        isDisabled: shouldDisableNextButton,
                        action: {
                            if viewModel.currentPage == OnboardingSlide.slides.count - 1 {
                                Task {
                                    await completeOnboarding()
                                }
                            } else {
                                viewModel.nextPage()
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
    }

    private var shouldDisableNextButton: Bool {
        let currentSlide = OnboardingSlide.slides[viewModel.currentPage]
        if currentSlide.isGenreSelection {
            return userProfileService.favoriteGenres.count < 3
        } else if currentSlide.isStreamingPlatformSelection {
            return userProfileService.favoriteStreamingPlatforms.isEmpty
        }
        return false
    }

    /// Complete onboarding by saving preferences to Firebase
    private func completeOnboarding() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No authenticated user found during onboarding completion")
            return
        }

        do {
            // Save user preferences to Firebase
            try await userProfileService.saveUserPreferences(userId: userId)
            print("✅ Onboarding completed - preferences saved to Firebase")

            // Update app state
            appStateManager.completeOnboarding()
        } catch {
            print("⚠️ Failed to save preferences during onboarding: \(error)")
            // Still complete onboarding - preferences are cached locally
            appStateManager.completeOnboarding()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
