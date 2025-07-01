//
//  ContentView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var userProfileService = UserProfileService()
    @StateObject private var homeViewModel: HomeViewModel

    init() {
        // Create services
        let userMovieService = UserMovieService()

        // We'll set userProfileService in the initializer using a temporary var
        // to share the same instance between StateObject and HomeViewModel
        let tempUserProfileService = UserProfileService()
        _userProfileService = StateObject(wrappedValue: tempUserProfileService)

        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            userMovieService: userMovieService,
            userProfileService: tempUserProfileService
        ))
    }

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(appStateManager)
                .environmentObject(homeViewModel)
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
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.cyan)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager())
}
