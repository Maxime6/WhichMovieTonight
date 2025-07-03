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
    @EnvironmentObject var notificationService: NotificationService
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

                    // Notification Settings
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            Text("Notifications")
                            Spacer()
                            Toggle("", isOn: $notificationService.isNotificationsEnabled)
                                .onChange(of: notificationService.isNotificationsEnabled) { _, newValue in
                                    handleNotificationToggle(newValue)
                                }
                        }

                        // Permission status description
                        if notificationService.shouldShowPermissionReminder {
                            Text(notificationService.notificationStatusDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 28)
                        }
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
            .onAppear {
                // Sync notification toggle with real system permission status
                Task {
                    await notificationService.checkNotificationPermissionStatus()
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

    // MARK: - Private Methods

    private func handleNotificationToggle(_ isEnabled: Bool) {
        if isEnabled {
            // User wants to enable notifications - request permission
            Task {
                let granted = await notificationService.requestNotificationPermissions()
                if !granted {
                    // If permission denied, update the toggle state
                    await MainActor.run {
                        notificationService.isNotificationsEnabled = false
                    }
                }
            }
        } else {
            // User wants to disable notifications - remove scheduled notifications and update state
            Task {
                await notificationService.disableNotifications()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStateManager())
}
