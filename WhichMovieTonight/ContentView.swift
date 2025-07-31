//
//  ContentView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var ratingManager = AppRatingManager()

    init() {
        // Create services
        let userMovieService = UserMovieService()

        // Initialize with placeholder - will be updated in onAppear
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            userMovieService: userMovieService,
            appStateManager: AppStateManager(userProfileService: UserProfileService())
        ))
    }

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(appStateManager)
                .environmentObject(homeViewModel)
                .environmentObject(userProfileService)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            NewWatchlistView()
                .environmentObject(appStateManager)
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Watchlist")
                }
                .tag(1)

            WatchlistView()
                .environmentObject(appStateManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("My Collection")
                }
                .tag(2)

            FavoritesView()
                .environmentObject(appStateManager)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
                .tag(3)

            SettingsView()
                .environmentObject(appStateManager)
                .environmentObject(userProfileService)
                .environmentObject(notificationService)
                .environmentObject(ratingManager)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(DesignSystem.primaryCyan)
        .tint(DesignSystem.primaryCyan)
        .onAppear {
            // Track app usage for rating prompts
            ratingManager.incrementAppUsage()

            // Update HomeViewModel with the correct AppStateManager from environment
            homeViewModel.updateAppStateManager(appStateManager)
        }
        .overlay {
            if ratingManager.shouldShowRatingPopup {
                AppRatingView(ratingManager: ratingManager)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
