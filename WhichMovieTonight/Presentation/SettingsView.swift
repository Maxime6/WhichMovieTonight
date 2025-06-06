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
    @State private var showingProfileMenu = false
    @State private var showingDeleteAlert = false

    init() {
        _authViewModel = StateObject(wrappedValue: AuthenticationViewModel())
    }

    var body: some View {
        NavigationView {
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
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .frame(width: 20)
                        Text("Favorite Genres")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        Text("Favorite Actors")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
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
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.purple)
                            .frame(width: 20)
                        Text("Help & Support")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }

                // Account Section
                Section("Account") {
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            Text("Sign Out")
                                .foregroundColor(.primary)
                        }
                    }

                    Button(action: {
                        showingDeleteAlert = true
                    }) {
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
            .onAppear {
                if authViewModel.appStateManager == nil {
                    authViewModel.appStateManager = appStateManager
                }
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        let success = await authViewModel.deleteAccount()
                        if success {
                            // Account deletion handled by AppStateManager
                        }
                    }
                }
            } message: {
                Text("This action is irreversible. All your data will be deleted and you will need to go through onboarding again.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStateManager())
}
