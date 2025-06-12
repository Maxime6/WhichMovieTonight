//
//  OnboardingView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 21/05/2025.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var appStateManager: AppStateManager
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var preferencesService = UserPreferencesService()
    @State private var showAuthentication = false

    init(appStateManager: AppStateManager) {
        self.appStateManager = appStateManager
    }

    var body: some View {
        ZStack {
            VStack {
                TabView(selection: $viewModel.currentPage) {
                    ForEach(OnboardingSlide.slides.indices, id: \.self) { index in
                        let slide = OnboardingSlide.slides[index]
                        if slide.isGenreSelection {
                            GenreSelectionView()
                                .environmentObject(preferencesService)
                                .tag(index)
                        } else if slide.isActorSelection {
                            ActorSelectionView()
                                .environmentObject(preferencesService)
                                .tag(index)
                        } else if slide.isStreamingPlatformSelection {
                            StreamingPlatformSelectionView()
                                .environmentObject(preferencesService)
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
                                appStateManager.completeOnboarding()
                            } else {
                                viewModel.nextPage()
                            }
                        }
                    )
                    .frame(width: 200)
                }
                .padding()
            }
        }
    }

    private var shouldDisableNextButton: Bool {
        let currentSlide = OnboardingSlide.slides[viewModel.currentPage]
        if currentSlide.isGenreSelection {
            return preferencesService.favoriteGenres.count < 3
        } else if currentSlide.isStreamingPlatformSelection {
            return preferencesService.favoriteStreamingPlatforms.isEmpty
        }
        return false
    }
}

#Preview {
    OnboardingView(appStateManager: AppStateManager())
}
