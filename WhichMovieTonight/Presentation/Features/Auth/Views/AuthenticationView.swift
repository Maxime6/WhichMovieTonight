//
//  AuthenticationView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 26/05/2025.
//

import AuthenticationServices
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var viewModel: AuthenticationViewModel = .init()

    var body: some View {
        VStack {
            Text("Page d'authentification")
                .font(.title)
            Text("À implémenter avec Firebase")
                .foregroundColor(.gray)

            SignInWithAppleButton(.continue) { request in
                viewModel.handleSignInWithAppleRequest(request)
            } onCompletion: { result in
                viewModel.handleSignInWithAppleCompletion(result)
            }
            .frame(height: 50)
            .clipShape(Capsule())
            .padding(.horizontal)
        }
        .onAppear {
            viewModel.setAppStateManager(appStateManager)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
}
