//
//  OnboardingViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 21/05/2025.
//

import Foundation

class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var hasSeenOnboarding = false
    
    func nextPage() {
        if currentPage < OnboardingSlide.slides.count - 1 {
            currentPage += 1
        } else {
            hasSeenOnboarding = true
        }
    }
    
    func skipOnboarding() {
        hasSeenOnboarding = true
    }
}
