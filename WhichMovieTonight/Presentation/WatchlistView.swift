//
//  WatchlistView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import FirebaseAuth
import SwiftUI

struct WatchlistView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack {
                // Tab selector
                Picker("Watchlist Options", selection: $selectedTab) {
                    Text("Watched").tag(0)
                    Text("Favorites").tag(1)
                    Text("Suggestions").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    watchedMoviesView
                        .tag(0)

                    favoritesView
                        .tag(1)

                    suggestionsView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Watchlist")
        }
    }

    private var watchedMoviesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Watched Movies")
                .font(.title2.bold())

            Text("Your viewing history will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private var favoritesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Favorite Movies")
                .font(.title2.bold())

            Text("Movies you've marked as favorites will be saved here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private var suggestionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text("Personalized Suggestions")
                .font(.title2.bold())

            Text("AI-powered movie recommendations based on your preferences will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    WatchlistView()
}
