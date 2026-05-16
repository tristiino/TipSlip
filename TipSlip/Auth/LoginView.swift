import SwiftUI

struct LoginView: View {

    @Environment(AuthService.self) private var authService
    @State private var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                TipSlipLogo()

                Spacer()

                VStack(spacing: Spacing.s12) {
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
                        .textContentType(.password)
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
                    Task { await viewModel.login(using: authService) }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In").font(.bodyMedium)
                        }
                    }
                    .tipSecondaryButton()
                }
                .padding(.horizontal, Spacing.s16)
                .disabled(viewModel.isLoading)

                Spacer().frame(height: Spacing.s16)

                NavigationLink("Don't have an account? Register") {
                    RegisterView()
                }
                .font(.bodyRegular)
                .foregroundStyle(Color.textSecondary)

                Spacer().frame(height: Spacing.s32)
            }
            .background(Color.bgSurface.ignoresSafeArea())
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthService())
}
