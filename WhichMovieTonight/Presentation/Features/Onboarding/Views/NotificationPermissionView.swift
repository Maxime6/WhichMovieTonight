//
//  NotificationPermissionView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var userProfileService: UserProfileService
    @State private var isRequestingPermission = false
    @State private var showPermissionDeniedAlert = false
    @State private var isAnimating = false
    @State private var isPermissionGranted = false

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
                                colors: [DesignSystem.primaryCyan.opacity(0.2), DesignSystem.primaryPurple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Bell icon with animation
                    Image(systemName: "bell.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(DesignSystem.verticalGradient)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
                }

                // Sparkles around the bell
                HStack(spacing: 16) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.yellow)
                            .opacity(isAnimating ? 1.0 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
            }

            // Content
            VStack(spacing: 16) {
                Text("Keep connected !")
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
                        } else if isPermissionGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                        } else {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }

                        Text(buttonText)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        ZStack {
                            // Animated mesh gradient glow
                            AnimatedMeshGradient()
                                .clipShape(.capsule)
                                .overlay {
                                    RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                                        .stroke(.white, lineWidth: 3)
                                        .blur(radius: 2)
                                        .blendMode(.overlay)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                                        .stroke(.white, lineWidth: 1)
                                        .blur(radius: 1)
                                        .blendMode(.overlay)
                                }

                            // Background
                            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                                .fill(.ultraThinMaterial)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                            .stroke(DesignSystem.primaryCyan.opacity(0.5), lineWidth: 1)
                    )
                    .primaryShadow()
                }
                .disabled(isRequestingPermission || isPermissionGranted)

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
            startVisualAnimations()
        }
        .alert("Notifications désactivées", isPresented: $showPermissionDeniedAlert) {
            Button("OK") {}
        } message: {
            Text("Vous pouvez activer les notifications plus tard dans les paramètres de l'application.")
        }
    }

    // MARK: - Computed Properties

    private var buttonText: String {
        if isRequestingPermission {
            return "Requesting access..."
        } else if isPermissionGranted {
            return "Notifications allowed"
        } else {
            return "Allow notifications"
        }
    }

    // MARK: - Private Methods

    private func startVisualAnimations() {
        // Start visual animations immediately when view appears
        isAnimating = true
    }

    private func requestNotificationPermissions() {
        // Only set requesting state when user actually taps the button
        isRequestingPermission = true

        Task {
            let granted = await notificationService.requestNotificationPermissions()

            await MainActor.run {
                isRequestingPermission = false

                if granted {
                    isPermissionGranted = true
                } else {
                    showPermissionDeniedAlert = true
                }

                // Mark notification step as completed regardless of user choice
                userProfileService.markNotificationStepCompleted()
            }
        }
    }

    private func skipNotificationPermission() {
        // User chose to skip - we'll show reminder in settings later
        print("⏭️ User skipped notification permission")

        // Mark notification step as completed
        userProfileService.markNotificationStepCompleted()
    }
}

#Preview {
    NotificationPermissionView()
        .environmentObject(NotificationService())
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
