//
//  ProfileMenuView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 26/05/2025.
//

import SwiftUI

struct ProfileMenuView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User Info Section
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)

                    Text(authViewModel.displayName.isEmpty ? "Utilisateur" : authViewModel.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let email = authViewModel.user?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 20)

                Divider()

                // Menu Options
                VStack(spacing: 16) {
                    MenuButton(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "Se déconnecter",
                        color: .orange
                    ) {
                        onSignOut()
                    }

                    MenuButton(
                        icon: "trash",
                        title: "Supprimer le compte",
                        color: .red
                    ) {
                        onDeleteAccount()
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Fermer") {
                dismiss()
            })
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileMenuView(
        authViewModel: AuthenticationViewModel(),
        onSignOut: {},
        onDeleteAccount: {}
    )
}
