//
//  OnboardingView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 21/05/2025.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var preferencesService = UserPreferencesService()
    @Environment(\.dismiss) private var dismiss
    @State private var showAuthentication = false

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
                                showAuthentication = true
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
        .fullScreenCover(isPresented: $showAuthentication) {
            AuthenticationView()
        }
        .onChange(of: viewModel.hasSeenOnboarding) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }

    private var shouldDisableNextButton: Bool {
        let currentSlide = OnboardingSlide.slides[viewModel.currentPage]
        if currentSlide.isGenreSelection {
            return preferencesService.favoriteGenres.count < 3
        }
        return false
    }
}

#Preview {
    OnboardingView()
}
