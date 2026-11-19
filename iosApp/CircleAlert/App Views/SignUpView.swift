import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Join CircleAlert to start creating tracking groups and safe zones.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 24)

                        VStack(spacing: 16) {
                            CustomTextField(
                                title: "Full Name",
                                icon: "person.fill",
                                text: $viewModel.displayName,
                                autocapitalization: .words
                            )

                            CustomTextField(
                                title: "Email Address",
                                icon: "envelope.fill",
                                text: $viewModel.email,
                                keyboardType: .emailAddress
                            )

                            CustomTextField(
                                title: "Password (min 6 characters)",
                                icon: "lock.fill",
                                text: $viewModel.password,
                                isSecure: true
                            )

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            PrimaryButton(
                                title: "Complete Registration",
                                icon: "checkmark.circle.fill",
                                isLoading: viewModel.isLoading
                            ) {
                                viewModel.isSignUp = true
                                Task {
                                    await viewModel.authenticate()
                                    if viewModel.errorMessage == nil {
                                        dismiss()
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
