import AuthenticationServices
import CryptoKit
import FirebaseAuth
import SwiftUI

struct ValuePropositionView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var userProfileService: UserProfileService
    @State private var isAuthenticating = false
    @State private var showAuthError = false
    @State private var authErrorMessage = ""
    @State private var currentNonce: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon and title
            VStack(spacing: 24) {
                Image("WMTLogoV1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                Text("Welcome to WMT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }

            // Value proposition
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "wand.and.stars",
                    title: "AI Movie Buddy",
                    description: "Get personalized movie recommendations powered by AI"
                )

                FeatureRow(
                    icon: "tv.fill",
                    title: "All Platforms",
                    description: "Centralize your streaming platforms in one place"
                )

                FeatureRow(
                    icon: "star.fill",
                    title: "Smart Discovery",
                    description: "Find hidden gems and rediscover classics"
                )
            }
            .padding(.horizontal)

            Spacer()

            // Apple Sign-In button
            VStack(spacing: 16) {
                SignInWithAppleButton(.continue) { request in
                    handleSignInWithAppleRequest(request)
                } onCompletion: { result in
                    handleSignInWithAppleCompletion(result)
                }
                .frame(height: 50)
                .clipShape(Capsule())
                .disabled(isAuthenticating)

                if isAuthenticating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Signing in...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .alert("Authentication Failed", isPresented: $showAuthError) {
            Button("Try Again", role: .cancel) {}
        } message: {
            Text(authErrorMessage)
        }
    }

    // MARK: - Apple Sign-In Methods

    private func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }

    private func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        isAuthenticating = true

        if case let .failure(error) = result {
            authErrorMessage = error.localizedDescription
            showAuthError = true
            isAuthenticating = false
        } else if case let .success(authorization) = result {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await authenticateWithFirebase(appleIDCredential: appleIDCredential)
                }
            }
        }
    }

    private func authenticateWithFirebase(appleIDCredential: ASAuthorizationAppleIDCredential) async {
        guard let nonce = currentNonce else {
            await MainActor.run {
                authErrorMessage = "Invalid authentication state"
                showAuthError = true
                isAuthenticating = false
            }
            return
        }

        guard let appleIDToken = appleIDCredential.identityToken else {
            await MainActor.run {
                authErrorMessage = "Unable to fetch identity token"
                showAuthError = true
                isAuthenticating = false
            }
            return
        }

        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            await MainActor.run {
                authErrorMessage = "Unable to serialize token"
                showAuthError = true
                isAuthenticating = false
            }
            return
        }

        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idTokenString,
            rawNonce: nonce
        )

        do {
            let result = try await Auth.auth().signIn(with: credential)
            await updateDisplayName(for: result.user, with: appleIDCredential)

            // After successful authentication, let AppStateManager handle the routing
            await MainActor.run {
                isAuthenticating = false
                // AppStateManager will automatically determine if user needs onboarding or can go to main app
                Task {
                    await appStateManager.handleSuccessfulAuthentication()
                }
            }
        } catch {
            await MainActor.run {
                authErrorMessage = error.localizedDescription
                showAuthError = true
                isAuthenticating = false
            }
        }
    }

    private func updateDisplayName(for user: User, with appleIDCredential: ASAuthorizationAppleIDCredential) async {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            return // Don't overwrite existing display name
        }

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = appleIDCredential.displayName()

        do {
            try await changeRequest.commitChanges()
        } catch {
            print("Unable to update display name: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

extension ASAuthorizationAppleIDCredential {
    func displayName() -> String {
        return [fullName?.givenName ?? "", fullName?.familyName ?? ""]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

#Preview {
    ValuePropositionView()
        .environmentObject(AppStateManager(userProfileService: UserProfileService()))
        .environmentObject(UserProfileService())
}
