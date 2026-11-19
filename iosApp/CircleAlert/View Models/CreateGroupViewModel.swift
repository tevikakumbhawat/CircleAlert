import Foundation
import Combine

final class CreateGroupViewModel: ObservableObject {
    @Published var groupName: String = ""
    @Published var generatedInviteCode: String = ""
    @Published var isCreated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var createdGroup: TrackingGroupModel?

    private let firebaseService = FirebaseService.shared

    func createGroup() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let group = try await firebaseService.createGroup(name: groupName)
            await MainActor.run {
                self.createdGroup = group
                self.generatedInviteCode = group.inviteCode
                self.isCreated = true
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
