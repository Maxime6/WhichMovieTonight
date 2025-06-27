//
//  SettingsView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import FirebaseAuth
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var authViewModel: AuthenticationViewModel
    @StateObject private var userProfileService = UserProfileService()
    @State private var showingProfileMenu = false
    @State private var showingDeleteAlert = false

    init() {
        _authViewModel = StateObject(wrappedValue: AuthenticationViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Text(authViewModel.displayName.isEmpty ? "User" : authViewModel.displayName)
                                .font(.headline)
                            Text(Auth.auth().currentUser?.email ?? "No email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Preferences Section
                Section("Preferences") {
                    NavigationLink {
                        StreamingPlatformSettingsView()
                            .environmentObject(userProfileService)
                    } label: {
                        HStack {
                            Image(systemName: "tv.fill")
                                .foregroundColor(.purple)
                                .frame(width: 20)
                            VStack(alignment: .leading) {
                                Text("Plateformes de streaming")
                                if userProfileService.favoriteStreamingPlatforms.isEmpty {
                                    Text("Aucune plateforme sélectionnée")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(userProfileService.favoriteStreamingPlatforms.map { $0.rawValue }.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    NavigationLink {
                        GenreSettingsView()
                            .environmentObject(userProfileService)
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .frame(width: 20)
                            VStack(alignment: .leading) {
                                Text("Genres favoris")
                                if userProfileService.favoriteGenres.isEmpty {
                                    Text("Aucun genre sélectionné")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(userProfileService.favoriteGenres.map { $0.rawValue }.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    NavigationLink {
                        ActorSettingsView()
                            .environmentObject(userProfileService)
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            VStack(alignment: .leading) {
                                Text("Acteurs favoris")
                                if userProfileService.favoriteActors.isEmpty {
                                    Text("Aucun acteur ajouté")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(userProfileService.favoriteActors.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        Text("Notifications")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 20)
                        Text("Rate App")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Help & Support")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }

                // Account Section
                Section("Account") {
                    Button {
                        Task {
                            do {
                                try Auth.auth().signOut()
                                appStateManager.handleSignOut()
                            } catch {
                                print("Error signing out: \(error)")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .frame(width: 20)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }

                    Button {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 20)
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                // Load user preferences from Firebase when view appears
                if let userId = Auth.auth().currentUser?.uid {
                    await userProfileService.loadUserPreferences(userId: userId)
                }
            }
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let success = await authViewModel.deleteAccount()
                    if success {
                        appStateManager.handleAccountDeletion()
                    }
                }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStateManager())
}
