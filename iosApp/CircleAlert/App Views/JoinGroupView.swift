import SwiftUI

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = JoinGroupViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Join Tracking Group")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Enter the 6-character code provided by the group creator to join.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 24)

                        VStack(spacing: 16) {
                            CustomTextField(
                                title: "6-Character Invite Code",
                                icon: "key.fill",
                                text: $viewModel.inviteCode,
                                autocapitalization: .characters
                            )

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if let joined = viewModel.joinedGroup {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Successfully joined \(joined.name)!")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 8)
                            }

                            PrimaryButton(
                                title: viewModel.isSuccess ? "Joined!" : "Join Group",
                                icon: viewModel.isSuccess ? "checkmark" : "arrow.right.circle.fill",
                                isLoading: viewModel.isLoading
                            ) {
                                if viewModel.isSuccess {
                                    dismiss()
                                } else {
                                    Task {
                                        await viewModel.joinGroup()
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
