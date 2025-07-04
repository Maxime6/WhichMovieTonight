//
//  NotificationPermissionView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var notificationService: NotificationService
    @State private var isRequestingPermission = false
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon and Animation
            VStack(spacing: 24) {
                ZStack {
                    // Background circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Bell icon with animation
                    Image(systemName: "bell.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isRequestingPermission ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRequestingPermission)
                }

                // Sparkles around the bell
                HStack(spacing: 16) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.yellow)
                            .opacity(isRequestingPermission ? 1.0 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isRequestingPermission
                            )
                    }
                }
            }

            // Content
            VStack(spacing: 16) {
                Text("Restez connecté !")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("🍿 Want to never miss amazing movie recommendations? We'll send you a few friendly reminders daily to keep your watchlist fresh! We promise not to be annoying - just helpful movie buddies! 🎬")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 16) {
                // Enable Notifications Button
                Button(action: requestNotificationPermissions) {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }

                        Text(isRequestingPermission ? "Demande en cours..." : "Activer les notifications")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isRequestingPermission)

                // Skip Button
                Button(action: skipNotificationPermission) {
                    Text("Passer pour l'instant")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                .disabled(isRequestingPermission)
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            startAnimations()
        }
        .alert("Notifications désactivées", isPresented: $showPermissionDeniedAlert) {
            Button("OK") {}
        } message: {
            Text("Vous pouvez activer les notifications plus tard dans les paramètres de l'application.")
        }
    }

    // MARK: - Private Methods

    private func startAnimations() {
        isRequestingPermission = true
    }

    private func requestNotificationPermissions() {
        isRequestingPermission = true

        Task {
            let granted = await notificationService.requestNotificationPermissions()

            await MainActor.run {
                isRequestingPermission = false

                if !granted {
                    showPermissionDeniedAlert = true
                }
            }
        }
    }

    private func skipNotificationPermission() {
        // User chose to skip - we'll show reminder in settings later
        print("⏭️ User skipped notification permission")
    }
}

#Preview {
    NotificationPermissionView()
        .environmentObject(NotificationService())
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
