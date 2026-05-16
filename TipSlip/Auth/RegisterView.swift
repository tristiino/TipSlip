import SwiftUI

struct RegisterView: View {

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RegisterViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Create Account")
                .font(.titleLarge)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            VStack(spacing: Spacing.s12) {
                TextField("Username", text: $viewModel.username)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .tipInputStyle()

                TextField("Email", text: $viewModel.email)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .tipInputStyle()

                SecureField("Password", text: $viewModel.password)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .textContentType(.newPassword)
                    .tipInputStyle()

                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .textContentType(.newPassword)
                    .tipInputStyle()

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.semanticDanger)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Spacing.s16)

            Spacer().frame(height: Spacing.s20)

            Button {
                Task { await viewModel.register(using: authService) }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create Account").font(.bodyMedium)
                    }
                }
                .tipPrimaryButton()
            }
            .padding(.horizontal, Spacing.s16)
            .disabled(viewModel.isLoading)

            Spacer().frame(height: Spacing.s16)

            Button("Already have an account? Sign In") {
                dismiss()
            }
            .font(.bodyRegular)
            .foregroundStyle(Color.textSecondary)

            Spacer().frame(height: Spacing.s32)
        }
        .background(Color.bgSurface.ignoresSafeArea())
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
