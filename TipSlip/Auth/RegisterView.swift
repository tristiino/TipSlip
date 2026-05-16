import SwiftUI

struct RegisterView: View {

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RegisterViewModel()

    var body: some View {
        VStack(spacing: Spacing.s24) {
            Spacer()

            Text("Create Account")
                .font(.tipSlip(.title))
                .foregroundStyle(Colors.textPrimary)

            Spacer()

            VStack(spacing: Spacing.s16) {
                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.tipSlip(.caption))
                        .foregroundStyle(Colors.danger)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await viewModel.register(using: authService) }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account").font(.tipSlip(.bodyEmphasis))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(Colors.brandPrimary)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, Spacing.s24)

            Button("Already have an account? Sign In") {
                dismiss()
            }
            .font(.tipSlip(.body))
            .foregroundStyle(Colors.brandPrimary)
            .padding(.bottom, Spacing.s32)
        }
        .background(Colors.backgroundPrimary)
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environment(AuthService())
    }
}
