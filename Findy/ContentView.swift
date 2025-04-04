//
//  ContentView.swift
//  Findy
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    var body: some View {
        Group {
            if onboardingViewModel.isOnboardingCompleted {
                HomeView(
                    nickname: onboardingViewModel.nickname,
                    currentMood: onboardingViewModel.selectedMood ?? .happy
                )
            } else {
                OnboardingView()
                    .environmentObject(onboardingViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
