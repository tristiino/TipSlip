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
                .accessibilityAddTraits(.isHeader)

            Spacer()

            VStack(spacing: Spacing.s12) {
                TextField("Username", text: $viewModel.username)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .tipInputStyle()
                    .accessibilityLabel("Username")

                TextField("Email", text: $viewModel.email)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .tipInputStyle()
                    .accessibilityLabel("Email address")

                SecureField("Password", text: $viewModel.password)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .textContentType(.newPassword)
                    .tipInputStyle()
                    .accessibilityLabel("Password")

                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .textContentType(.newPassword)
                    .tipInputStyle()
                    .accessibilityLabel("Confirm password")

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.semanticDanger)
                        .multilineTextAlignment(.center)
                        .accessibilityLiveRegionPolite()
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
            .accessibilityLabel(viewModel.isLoading ? "Creating account" : "Create Account")
            .padding(.horizontal, Spacing.s16)
            .disabled(viewModel.isLoading)

            Spacer().frame(height: Spacing.s16)

            Button("Already have an account? Sign In") {
                dismiss()
            }
            .font(.bodyRegular)
            .foregroundStyle(Color.textSecondary)
            .accessibilityLabel("Already have an account? Go to Sign In")

            Spacer().frame(height: Spacing.s32)
        }
        .background(Color.bgSurface.ignoresSafeArea())
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        RegisterView()
            .environment(AuthService())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        RegisterView()
            .environment(AuthService())
    }
    .preferredColorScheme(.dark)
}
