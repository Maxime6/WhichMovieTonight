//
//  OnboardingView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 21/05/2025.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            VStack {
                TabView(selection: $viewModel.currentPage) {
                    ForEach(OnboardingSlide.slides.indices, id: \.self) { index in
                        let slide = OnboardingSlide.slides[index]
                        if slide.isGenreSelection {
                            GenreSelectionView()
                                .tag(index)
                        } else if slide.isActorSelection {
                            ActorSelectionView()
                                .tag(index)
                        } else {
                            OnboardingSlideView(slide: slide)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                HStack {
                    Button {
                        viewModel.skipOnboarding()
                    } label: {
                        Text("Passer")
                    }
                    .foregroundStyle(.tertiary)

                    Spacer()

                    Button {
                        viewModel.nextPage()
                    } label: {
                        Text(viewModel.currentPage == OnboardingSlide.slides.count - 1 ? "Commencer" : "Suivant")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .onChange(of: viewModel.hasSeenOnboarding) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
