//
//  ProfilePictureView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import FirebaseStorage
import SwiftUI

struct ProfilePictureView: View {
    let size: CGFloat
    let profilePictureURL: String?
    let displayName: String
    let showEditIcon: Bool
    let onTap: () -> Void

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        size: CGFloat,
        profilePictureURL: String?,
        displayName: String,
        showEditIcon: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.size = size
        self.profilePictureURL = profilePictureURL
        self.displayName = displayName
        self.showEditIcon = showEditIcon
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(.primary.opacity(0.1), lineWidth: 1)
                    )

                // Content
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size - 4, height: size - 4)
                        .clipShape(Circle())
                } else {
                    // Fallback to initials or SF Symbol
                    if !displayName.isEmpty {
                        Text(displayName.prefix(1).uppercased())
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: size * 0.6))
                            .foregroundColor(.secondary)
                    }
                }

                // Edit Icon Overlay
                if showEditIcon {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: size * 0.3))
                                .foregroundColor(.cyan)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: size * 0.3, height: size * 0.3)
                                )
                                .offset(x: size * 0.1, y: size * 0.1)
                        }
                    }
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadProfilePicture()
        }
        .onChange(of: profilePictureURL) { _, _ in
            loadProfilePicture()
        }
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
            showEditIcon: true
        ) {
            print("Tapped profile picture")
        }

        ProfilePictureView(
            size: 60,
            profilePictureURL: nil,
            displayName: "",
            showEditIcon: true
        ) {
            print("Tapped profile picture")
        }
    }
    .padding()
}
