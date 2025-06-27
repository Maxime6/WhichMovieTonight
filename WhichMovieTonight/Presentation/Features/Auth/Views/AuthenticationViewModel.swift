//
//  AuthenticationViewModel.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 26/05/2025.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation

enum AthenticationState {
  case unauthenticated
  case authenticating
  case authenticated
}

@MainActor
class AuthenticationViewModel: ObservableObject {
  @Published var user: User?
  @Published var displayName = ""
  @Published var errorMessage: String? = nil
  @Published var authenticationState: AthenticationState = .unauthenticated

  fileprivate var currentNonce: String?
  private var authStateHandler: AuthStateDidChangeListenerHandle?
  weak var appStateManager: AppStateManager?

  init(appStateManager: AppStateManager? = nil) {
    self.appStateManager = appStateManager
    registerAuthStateHandler()
    verifySignInWithAppleAuthenticationState()
  }

  func setAppStateManager(_ appStateManager: AppStateManager) {
    self.appStateManager = appStateManager
  }

  func registerAuthStateHandler() {
    if authStateHandler == nil {
      authStateHandler = Auth.auth().addStateDidChangeListener { _, user in
        self.user = user
        self.authenticationState = user == nil ? .unauthenticated : .authenticated
        self.displayName = user?.displayName ?? user?.email ?? ""

        // Notify AppStateManager of authentication success
        if user != nil {
          self.appStateManager?.handleSuccessfulAuthentication()
        }
      }
    }
  }

  func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
    request.requestedScopes = [.fullName, .email]
    let nonce = randomNonceString()
    currentNonce = nonce
    request.nonce = sha256(nonce)
  }

  func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
    if case let .failure(failure) = result {
      errorMessage = failure.localizedDescription
    } else if case let .success(success) = result {
      if let appleIDCredential = success.credential as? ASAuthorizationAppleIDCredential {
        guard let nonce = currentNonce else {
          fatalError("Invalid state: a login callback was received, but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
          print("Unable to fetch identity token")
          return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
          print("Unable to serialize token string from data : \(appleIDToken.debugDescription)")
          return
        }

        let credential = OAuthProvider.credential(providerID: .apple, idToken: idTokenString, rawNonce: nonce)

        Task {
          do {
            let result = try await Auth.auth().signIn(with: credential)
            await updateDisplayName(for: result.user, with: appleIDCredential)
          } catch {
            print("Error authenticating: \(error.localizedDescription)")
          }
        }
      }
    }
  }

  func verifySignInWithAppleAuthenticationState() {
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let providerData = Auth.auth().currentUser?.providerData
    if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
      Task {
        do {
          let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
          switch credentialState {
          case .authorized:
            break // The Apple ID credential is valid.
          case .revoked, .notFound:
            // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
            self.signOut()
          default:
            break
          }
        } catch {}
      }
    }
  }

  func signOut() {
    do {
      try Auth.auth().signOut()
      appStateManager?.handleSignOut()
    } catch {
      print(error)
      errorMessage = error.localizedDescription
    }
  }

  func deleteAccount() async -> Bool {
    do {
      try await user?.delete()
      appStateManager?.handleAccountDeletion()
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }

  func updateDisplayName(for user: User, with appleIDCredential: ASAuthorizationAppleIDCredential, force _: Bool = false) async {
    if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
      // current user is non empty, don't overwrite it
    } else {
      let changeRequest = user.createProfileChangeRequest()
      changeRequest.displayName = appleIDCredential.displayName()

      do {
        try await changeRequest.commitChanges()
        displayName = Auth.auth().currentUser?.displayName ?? ""
      } catch {
        print("Unable to update the user's displayName: \(error.localizedDescription)")
        errorMessage = error.localizedDescription
      }
    }
  }

  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
      fatalError(
        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
      )
    }

    let charset: [Character] =
      Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

    let nonce = randomBytes.map { byte in
      // Pick a random character from the set, wrapping around if needed.
      charset[Int(byte) % charset.count]
    }

    return String(nonce)
  }

  @available(iOS 13, *)
  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
      String(format: "%02x", $0)
    }.joined()

    return hashString
  }
}

extension ASAuthorizationAppleIDCredential {
  func displayName() -> String {
    return [fullName?.givenName ?? "", fullName?.familyName ?? ""]
      .compactMap { $0 }
      .joined(separator: " ")
  }
}
