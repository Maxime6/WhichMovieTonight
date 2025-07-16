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

    init() {
        // Create services
        let userMovieService = UserMovieService()

        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            userMovieService: userMovieService
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

            WatchlistView()
                .environmentObject(appStateManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Watchlist")
                }
                .tag(1)

            FavoritesView()
                .environmentObject(appStateManager)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
                .tag(2)

            SettingsView()
                .environmentObject(appStateManager)
                .environmentObject(userProfileService)
                .environmentObject(notificationService)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(DesignSystem.primaryCyan)
        .tint(DesignSystem.primaryCyan)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
