//
//  HomeView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var authViewModel: AuthenticationViewModel

    @State private var actorsInput: String = ""
    @State private var genresSelected: [MovieGenre] = []
    @State private var showingProfileMenu = false
    @State private var showingDeleteAlert = false

    init() {
        // Initialize authViewModel with a placeholder, will be updated in onAppear
        _authViewModel = StateObject(wrappedValue: AuthenticationViewModel())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)

            VStack {
                headerView

                Spacer()

                if let movie = viewModel.selectedMovie {
                    MovieCardView(movie: movie)
                        .onAppear {
                            triggerHaptic()
                        }
                } else {
                    emptyStateView
                }

                Spacer()
            }
            .padding()
            .blur(radius: viewModel.isLoading ? 10 : 0)
            .onAppear {
                if authViewModel.appStateManager == nil {
                    authViewModel.appStateManager = appStateManager
                }
                viewModel.setAuthViewModel(authViewModel)
                viewModel.fetchUser()
            }

            if viewModel.isLoading {
                AISearchingView()
            }
        }
        .animation(.easeInOut, value: viewModel.isLoading)
        .overlay(
            Group {
                if let message = viewModel.toastMessage, viewModel.showToast {
                    ToastView(message: message, icon: "checkmark.seal.fill", onDismiss: { viewModel.toastMessage = nil }, isShowing: $viewModel.showToast)
                }
            }, alignment: .bottom
        )
        .sheet(isPresented: $showingProfileMenu) {
            ProfileMenuView(
                authViewModel: authViewModel,
                onSignOut: {
                    authViewModel.signOut()
                    showingProfileMenu = false
                },
                onDeleteAccount: {
                    showingDeleteAlert = true
                }
            )
            .presentationDetents([.medium])
        }
        .alert("Supprimer le compte", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                Task {
                    let success = await authViewModel.deleteAccount()
                    if success {
                        showingProfileMenu = false
                    }
                }
            }
        } message: {
            Text("Cette action est irréversible. Toutes vos données seront supprimées et vous devrez refaire l'onboarding.")
        }
        .fullScreenCover(isPresented: $viewModel.showMovieConfirmation) {
            if let movie = viewModel.suggestedMovie {
                NavigationView {
                    MovieConfirmationView(
                        movie: movie,
                        onConfirm: {
                            viewModel.confirmMovie()
                        },
                        onSearchAgain: {
                            viewModel.searchAgain()
                        }
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showGenreSelection) {
            NavigationView {
                GenreActorSelectionView(
                    selectedGenres: $viewModel.selectedGenres,
                    actorsInput: $actorsInput,
                    onStartSearch: {
                        Task {
                            viewModel.isLoading = true
                            try await viewModel.findTonightMovie()
                        }
                    }
                )
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Hi \(viewModel.userName),")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("What are you in the mood for tonight ?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {
                showingProfileMenu = true
            }) {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "movieclapper")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundStyle(.ultraThickMaterial)

            Text("No movie selected yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text("Tap below to let AI find the perfect movie for tonight !")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            AIActionButton(title: "Which Movie tonight ?") {
                viewModel.showGenreSelection = true
            }
        }
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 10)
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppStateManager())
}

struct WaveRenderer: TextRenderer {
    var strength: Double
    var frequency: Double
    var animatableData: Double {
        get { strength }
        set { strength = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                for (index, glyph) in run.enumerated() {
                    let yOffset = strength * sin(Double(index) * frequency)
                    var copy = context
                    copy.translateBy(x: 0, y: yOffset)
                    copy.draw(glyph, options: .disablesSubpixelQuantization)
                }
            }
        }
    }
}
