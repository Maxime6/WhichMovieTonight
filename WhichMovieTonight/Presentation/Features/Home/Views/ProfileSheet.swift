//
//  ProfileSheet.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import FirebaseAuth
import PhotosUI
import SwiftUI

struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userProfileService: UserProfileService
    @State private var displayName: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingPhotoOptions = false
    @State private var isUploading = false
    @State private var showingError = false
    @State private var errorMessage = ""

    init(userProfileService: UserProfileService) {
        self.userProfileService = userProfileService
        _displayName = State(initialValue: userProfileService.displayName)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Picture Section
                VStack(spacing: 16) {
                    ProfilePictureView(
                        size: 100,
                        profilePictureURL: userProfileService.profilePictureURL,
                        memojiData: userProfileService.memojiData,
                        displayName: userProfileService.displayName
                    ) {
                        showingPhotoOptions = true
                    }

                    Button("Change Photo") {
                        showingPhotoOptions = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.cyan)
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
                        HStack {
                            Text("Watching frequency")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(userProfileService.movieWatchingFrequency.displayText)
                                .foregroundColor(.primary)
                        }

                        HStack {
                            Text("Movie mood")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(userProfileService.movieMoodPreference.displayText)
                                .foregroundColor(.primary)
                        }
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding()
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
            .confirmationDialog("Change Profile Picture", isPresented: $showingPhotoOptions) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                }

                Button("Use Memoji") {
                    // TODO: Implement Memoji selection
                }

                if userProfileService.profilePictureURL != nil || userProfileService.memojiData != nil {
                    Button("Remove Photo", role: .destructive) {
                        removeProfilePicture()
                    }
                }

                Button("Cancel", role: .cancel) {}
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
    }

    private func saveChanges() {
        Task {
            do {
                if let userId = Auth.auth().currentUser?.uid {
                    if displayName != userProfileService.displayName {
                        try await userProfileService.updateDisplayName(displayName, userId: userId)
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

    private func loadTransferable(from imageSelection: PhotosPickerItem?) async {
        do {
            if let data = try await imageSelection?.loadTransferable(type: Data.self),
               let image = UIImage(data: data)
            {
                isUploading = true

                if let userId = Auth.auth().currentUser?.uid {
                    try await userProfileService.uploadProfilePicture(userId: userId, image: image)

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

    private func removeProfilePicture() {
        Task {
            do {
                if let userId = Auth.auth().currentUser?.uid {
                    try await userProfileService.deleteProfilePicture(userId: userId)

                    // Haptic feedback for success
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
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
