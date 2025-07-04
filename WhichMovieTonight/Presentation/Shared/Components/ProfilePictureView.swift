//
//  ProfilePictureView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import FirebaseStorage
import PhotosUI
import SwiftUI

struct ProfilePictureView: View {
    let size: CGFloat
    let profilePictureURL: String?
    let displayName: String
    let showEditIcon: Bool
    var selectedItem: Binding<PhotosPickerItem?>? = nil

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .stroke(.primary.opacity(0.1), lineWidth: 1)
                )
                .frame(width: size, height: size)

            // Content
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Fallback to initials or SF Symbol
                if !displayName.isEmpty {
                    Text(displayName.prefix(1).uppercased())
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: size, height: size)
                        .background(Circle().fill(.ultraThinMaterial))
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: size * 0.6))
                        .foregroundColor(.secondary)
                        .frame(width: size, height: size)
                        .background(Circle().fill(.ultraThinMaterial))
                }
            }

            // Edit icon overlay (only if selectedItem is provided)
            if showEditIcon, let selectedItem = selectedItem {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PhotosPicker(selection: selectedItem, matching: .images) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: size * 0.3))
                                .foregroundColor(.cyan)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: size * 0.3, height: size * 0.3)
                                )
                        }
                        .offset(x: size * 0.1, y: size * 0.1)
                    }
                }
                .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .onAppear { loadProfilePicture() }
        .onChange(of: profilePictureURL) { _, _ in loadProfilePicture() }
    }

    private func loadProfilePicture() {
        guard let urlString = profilePictureURL,
              let url = URL(string: urlString)
        else {
            image = nil
            return
        }

        isLoading = true

        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data, let uiImage = UIImage(data: data) {
                    image = uiImage
                } else {
                    image = nil
                }
            }
        }.resume()
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfilePictureView(
            size: 60,
            profilePictureURL: nil,
            displayName: "John",
            showEditIcon: true,
            selectedItem: .constant(nil)
        )

        ProfilePictureView(
            size: 60,
            profilePictureURL: nil,
            displayName: "",
            showEditIcon: true,
            selectedItem: .constant(nil)
        )
    }
    .padding()
}
