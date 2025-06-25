//
//  ContentView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var showLaunchScreen = true

    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreen()
                    .transition(.opacity)
            } else {
                TabView {
                    HomeView()
                        .environmentObject(homeViewModel)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)

                    WatchlistView()
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Watchlist")
                        }
                        .tag(1)

                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .tag(2)
                }
                .accentColor(.blue)
                .transition(.opacity)
            }
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
    }

    private func loadInitialData() async {
        // Load essential data during launch screen
        await homeViewModel.loadInitialData()

        // Wait minimum time for good UX (but keep it short)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds minimum

        // Hide launch screen with animation
        withAnimation(.easeInOut(duration: 0.5)) {
            showLaunchScreen = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager())
}
