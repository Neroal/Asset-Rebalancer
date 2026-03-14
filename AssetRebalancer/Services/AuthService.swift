import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import Foundation
import Combine

// MARK: - Auth ViewModel
@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isSignedIn = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var authListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var appleSignInDelegate: AppleSignInDelegate?
    private var appleReauthDelegate: AppleReauthDelegate?

    init() {
        listenToAuthState()
    }

    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func listenToAuthState() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isSignedIn = user != nil
                self?.isLoading = false
            }
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase configuration error"
            return
        }

        do {
            let credential = try await getGoogleCredential(clientID: clientID)
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        handleAppleSignInRequest(request)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate(viewModel: self)
        self.appleSignInDelegate = delegate
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }

    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Apple Sign-In failed: invalid credentials"
                return
            }

            let credential = OAuthProvider.credential(
                providerID: AuthProviderID.apple,
                idToken: idTokenString,
                rawNonce: nonce
            )

            Task {
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)

                    // Update display name if provided (only on first sign-in)
                    if let fullName = appleIDCredential.fullName {
                        let displayName = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        if !displayName.isEmpty {
                            let changeRequest = authResult.user.createProfileChangeRequest()
                            changeRequest.displayName = displayName
                            try? await changeRequest.commitChanges()
                        }
                    }

                    self.user = authResult.user
                    self.errorMessage = nil
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.user = nil
            self.isSignedIn = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Account

    func deleteAccount() async {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "User not authenticated"
            return
        }

        do {
            try await reauthenticateIfNeeded(currentUser)
            try await FirestoreService.shared.deleteAllUserData()
            try await currentUser.delete()

            GIDSignIn.sharedInstance.signOut()
            UserDefaults.standard.removeObject(forKey: "hide_assets")
            UserDefaults.standard.removeObject(forKey: "app_language")
            self.user = nil
            self.isSignedIn = false
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reauthentication

    private func reauthenticateIfNeeded(_ user: User) async throws {
        guard let providerID = user.providerData.first?.providerID else { return }

        switch providerID {
        case "google.com":
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            let credential = try await getGoogleCredential(clientID: clientID)
            try await user.reauthenticate(with: credential)

        case "apple.com":
            let credential = try await getAppleCredential()
            try await user.reauthenticate(with: credential)

        default:
            break
        }
    }

    // MARK: - Credential Helpers

    /// Get a Google AuthCredential via interactive sign-in
    private func getGoogleCredential(clientID: String) async throws -> AuthCredential {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let topVC = Self.topViewController() else {
            throw NSError(domain: "AuthError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot find root view controller"])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to get Google ID token"])
        }

        return GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
    }

    /// Get an Apple AuthCredential via interactive sign-in
    private func getAppleCredential() async throws -> AuthCredential {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleCredential = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleReauthDelegate(continuation: continuation)
            self.appleReauthDelegate = delegate
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
        }

        guard let appleIDToken = appleCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw NSError(domain: "AuthError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Apple reauthentication failed"])
        }

        return OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idTokenString,
            rawNonce: nonce
        )
    }

    // MARK: - Utilities

    /// Get the topmost presented view controller
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return nil
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Shared Presentation Anchor
private func defaultPresentationAnchor() -> ASPresentationAnchor {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
        return ASPresentationAnchor()
    }
    return window
}

// MARK: - Apple Sign In Delegate (for custom button)
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            viewModel.handleAppleSignInCompletion(.success(authorization))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            viewModel.handleAppleSignInCompletion(.failure(error))
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        defaultPresentationAnchor()
    }
}

// MARK: - Apple Reauthentication Delegate (for account deletion)
class AppleReauthDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>

    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation.resume(returning: credential)
        } else {
            continuation.resume(throwing: NSError(domain: "AuthError", code: -1,
                                                  userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"]))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        defaultPresentationAnchor()
    }
}
