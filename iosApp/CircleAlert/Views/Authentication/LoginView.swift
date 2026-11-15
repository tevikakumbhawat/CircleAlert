import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSignUpSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header Branding
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 88, height: 88)

                                Image(systemName: "location.north.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 52, height: 52)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 40)

                            Text("CircleAlert")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("Real-time Group Geofencing & Location Alerts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        // Form Card
                        VStack(spacing: 16) {
                            CustomTextField(
                                title: "Email Address",
                                icon: "envelope.fill",
                                text: $viewModel.email,
                                keyboardType: .emailAddress
                            )

                            CustomTextField(
                                title: "Password",
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
                                title: "Sign In",
                                icon: "arrow.right.circle.fill",
                                isLoading: viewModel.isLoading
                            ) {
                                Task {
                                    await viewModel.authenticate()
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 20)

                        // Quick demo tip
                        VStack(spacing: 6) {
                            Text("Technical Assignment Evaluation Mode")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            Text("Sign in with any email/password, or use the pre-configured session.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)

                        // Create Account Link
                        Button(action: { showSignUpSheet = true }) {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(.secondary)
                                Text("Create Account")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            .font(.subheadline)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .sheet(isPresented: $showSignUpSheet) {
                SignUpView()
            }
        }
    }
}
