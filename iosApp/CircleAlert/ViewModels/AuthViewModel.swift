import Foundation
import Combine

final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var displayName: String = ""
    @Published var isSignUp: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let firebaseService = FirebaseService.shared

    func authenticate() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            if isSignUp {
                _ = try await firebaseService.signUp(
                    email: email,
                    password: password,
                    displayName: displayName
                )
            } else {
                _ = try await firebaseService.signIn(
                    email: email,
                    password: password
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            self.isLoading = false
        }
    }
}
