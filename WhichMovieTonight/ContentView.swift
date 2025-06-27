//
//  ContentView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var homeViewModel = HomeViewModel()

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

            SettingsView()
                .environmentObject(appStateManager)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager())
}
