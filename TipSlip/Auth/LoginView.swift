import SwiftUI

struct LoginView: View {

    @Environment(AuthService.self) private var authService
    @State private var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                TipSlipLogo()
                    .accessibilityLabel("TipSlip")
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                VStack(spacing: Spacing.s12) {
                    TextField("Email or username", text: $viewModel.email)
                        .font(.bodyRegular)
                        .foregroundStyle(Color.textPrimary)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .tipInputStyle()
                        .accessibilityLabel("Email or username")

                    SecureField("Password", text: $viewModel.password)
                        .font(.bodyRegular)
                        .foregroundStyle(Color.textPrimary)
                        .textContentType(.password)
                        .tipInputStyle()
                        .accessibilityLabel("Password")

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
                .accessibilityLabel(viewModel.isLoading ? "Signing in" : "Sign In")
                .padding(.horizontal, Spacing.s16)
                .disabled(viewModel.isLoading)

                Spacer().frame(height: Spacing.s16)

                NavigationLink("Don't have an account? Register") {
                    RegisterView()
                }
                .font(.bodyRegular)
                .foregroundStyle(Color.textSecondary)
                .accessibilityLabel("Don't have an account? Go to Register")

                Spacer().frame(height: Spacing.s32)
            }
            .background(Color.bgSurface.ignoresSafeArea())
        }
    }
}

#Preview("Light") {
    LoginView()
        .environment(AuthService())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoginView()
        .environment(AuthService())
        .preferredColorScheme(.dark)
}
