import Foundation
import Combine

final class JoinGroupViewModel: ObservableObject {
    @Published var inviteCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var joinedGroup: TrackingGroupModel?
    @Published var isSuccess: Bool = false

    private let firebaseService = FirebaseService.shared

    func joinGroup() async {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6 else {
            await MainActor.run {
                self.errorMessage = "Please enter a valid 6-character invite code."
            }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let group = try await firebaseService.joinGroup(inviteCode: code)
            await MainActor.run {
                self.joinedGroup = group
                self.isSuccess = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
