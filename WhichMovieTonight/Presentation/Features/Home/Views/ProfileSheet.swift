//
//  ProfileSheet.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import AuthenticationServices
import FirebaseAuth
import PhotosUI
import SwiftUI

struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userProfileService: UserProfileService
    @State private var displayName: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccessToast = false
    @State private var successMessage = ""

    init(userProfileService: UserProfileService) {
        self.userProfileService = userProfileService
        _displayName = State(initialValue: userProfileService.displayName)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Picture Section
                    VStack(spacing: 16) {
                        ProfilePictureView(
                            size: 100,
                            profilePictureURL: userProfileService.profilePictureURL,
                            displayName: userProfileService.displayName,
                            showEditIcon: true,
                            selectedItem: $selectedItem
                        )
                        // Remove photo button (only show if photo exists)
                        if userProfileService.profilePictureURL != nil {
                            Button("Remove Photo") {
                                removeProfilePicture()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }

                    // Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("Your name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: displayName) { _, newValue in
                                // Remove spaces and limit to 15 characters
                                displayName = newValue.replacingOccurrences(of: " ", with: "")
                                    .prefix(15).description
                            }
                            .overlay(
                                HStack {
                                    Spacer()
                                    Text("\(displayName.count)/15")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.trailing, 8)
                            )
                    }

                    // Preferences Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preferences")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(spacing: 12) {
                            // Watching Frequency Picker
                            HStack {
                                Text("Watching frequency")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Menu {
                                    ForEach(MovieWatchingFrequency.allCases, id: \.self) { frequency in
                                        Button(frequency.displayText) {
                                            updateWatchingFrequency(frequency)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(userProfileService.movieWatchingFrequency.displayText)
                                            .foregroundColor(.primary)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            // Movie Mood Picker
                            HStack {
                                Text("Movie mood")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Menu {
                                    ForEach(MovieMoodPreference.allCases, id: \.self) { mood in
                                        Button(mood.displayText) {
                                            updateMovieMood(mood)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(userProfileService.movieMoodPreference.displayText)
                                            .foregroundColor(.primary)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .font(.subheadline)
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedItem) { _, item in
                Task {
                    await loadTransferable(from: item)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium])
        .overlay(
            // Success Toast
            Group {
                if showingSuccessToast {
                    VStack {
                        Spacer()
                        ToastView(
                            message: successMessage,
                            icon: "checkmark.seal.fill",
                            onDismiss: { showingSuccessToast = false },
                            isShowing: $showingSuccessToast
                        )
                        .padding(.bottom, 100)
                    }
                }
            }
        )
    }

    private func saveChanges() {
        Task {
            do {
                if let userId = Auth.auth().currentUser?.uid {
                    if displayName != userProfileService.displayName {
                        try await userProfileService.updateDisplayName(displayName, userId: userId)
                        showSuccessToast("Name updated successfully")
                    }

                    // Haptic feedback for success
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()

                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func updateWatchingFrequency(_ frequency: MovieWatchingFrequency) {
        Task {
            do {
                if let userId = Auth.auth().currentUser?.uid {
                    try await userProfileService.updateMovieWatchingFrequency(frequency, userId: userId)
                    showSuccessToast("Watching frequency updated")

                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func updateMovieMood(_ mood: MovieMoodPreference) {
        Task {
            do {
                if let userId = Auth.auth().currentUser?.uid {
                    try await userProfileService.updateMovieMoodPreference(mood, userId: userId)
                    showSuccessToast("Movie mood updated")

                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func loadTransferable(from imageSelection: PhotosPickerItem?) async {
        do {
            if let data = try await imageSelection?.loadTransferable(type: Data.self),
               let image = UIImage(data: data)
            {
                isUploading = true

                if let userId = Auth.auth().currentUser?.uid {
                    try await userProfileService.uploadProfilePicture(userId: userId, image: image)
                    showSuccessToast("Profile picture updated")

                    // Haptic feedback for success
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }

                isUploading = false
            }
        } catch {
            isUploading = false
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func showSuccessToast(_ message: String) {
        successMessage = message
        showingSuccessToast = true

        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSuccessToast = false
        }
    }

    private func removeProfilePicture() {
        Task {
            do {
                if let userId = Auth.auth().currentUser?.uid {
                    try await userProfileService.deleteProfilePicture(userId: userId)
                    showSuccessToast("Profile picture removed")
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    ProfileSheet(userProfileService: UserProfileService())
}
