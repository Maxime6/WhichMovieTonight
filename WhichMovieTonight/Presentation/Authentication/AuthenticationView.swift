//
//  AuthenticationView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 26/05/2025.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    
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
    }
}

#Preview {
    AuthenticationView()
}
