import FirebaseAuth
import PhotosUI
import SwiftUI

struct ProfilePhotoPicker: View {
    @EnvironmentObject var userProfileService: UserProfileService
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            // Profile photo display
            ZStack {
                Circle()
                    .fill(DesignSystem.subtleGradient)
                    .frame(width: 120, height: 120)

                if let profilePictureURL = userProfileService.profilePictureURL,
                   let url = URL(string: profilePictureURL)
                {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignSystem.verticalGradient)
                }

                // Upload indicator
                if isUploading {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 100, height: 100)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }

            // Photo picker button
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: userProfileService.profilePictureURL != nil ? "pencil.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(userProfileService.profilePictureURL != nil ? "Change Photo" : "Add Photo")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cyan.opacity(0.1))
                )
            }
            .disabled(isUploading)

            // Info text
            Text("You can add a profile photo now or later in the app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .onChange(of: selectedItem) { item in
            Task {
                await uploadPhoto(item: item)
            }
        }
        .alert("Upload Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func uploadPhoto(item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isUploading = true

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                throw NSError(domain: "PhotoError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
            }

            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
            }

            // Upload using existing UserProfileService
            _ = try await userProfileService.uploadProfilePicture(userId: userId, image: image)

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isUploading = false
    }
}

#Preview {
    ProfilePhotoPicker()
        .environmentObject(UserProfileService())
}
