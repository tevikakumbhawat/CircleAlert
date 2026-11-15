import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateGroupViewModel()
    @State private var copiedToClipboard: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if !viewModel.isCreated {
                            // Creation form
                            VStack(spacing: 8) {
                                Text("New Tracking Group")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Set a name for your tracking group. You'll receive a 6-digit invitation code to share with members.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.top, 24)

                            VStack(spacing: 16) {
                                CustomTextField(
                                    title: "Group Name (e.g. Field Team, Family)",
                                    icon: "person.3.fill",
                                    text: $viewModel.groupName,
                                    autocapitalization: .words
                                )

                                if let error = viewModel.errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                PrimaryButton(
                                    title: "Create Group & Generate Code",
                                    icon: "sparkles",
                                    isLoading: viewModel.isLoading
                                ) {
                                    Task {
                                        await viewModel.createGroup()
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .padding(20)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                            .padding(.horizontal, 20)
                        } else {
                            // Success & Invite Code Presentation
                            VStack(spacing: 24) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.green)
                                    .padding(.top, 20)

                                VStack(spacing: 6) {
                                    Text("Group Created!")
                                        .font(.title2)
                                        .fontWeight(.bold)

                                    Text(viewModel.groupName)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }

                                VStack(spacing: 12) {
                                    Text("Share Invitation Code")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 8) {
                                        ForEach(Array(viewModel.generatedInviteCode), id: \.self) { char in
                                            Text(String(char))
                                                .font(.system(size: 26, weight: .bold, design: .monospaced))
                                                .frame(width: 44, height: 52)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(10)
                                        }
                                    }

                                    Button(action: {
                                        UIPasteboard.general.string = viewModel.generatedInviteCode
                                        copiedToClipboard = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            copiedToClipboard = false
                                        }
                                    }) {
                                        Label(
                                            copiedToClipboard ? "Copied!" : "Copy Invitation Code",
                                            systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc.fill"
                                        )
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                                .padding(.horizontal, 20)

                                PrimaryButton(
                                    title: "Done",
                                    icon: "checkmark"
                                ) {
                                    dismiss()
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.isCreated ? "" : "Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
