import SwiftUI

struct LoginView: View {

    @Environment(AuthService.self) private var authService
    @State private var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.s24) {
                Spacer()

                VStack(spacing: Spacing.s12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Colors.brandPrimary)

                    Text("TipSlip")
                        .font(.tipSlip(.display))
                        .foregroundStyle(Colors.textPrimary)
                }

                Spacer()

                VStack(spacing: Spacing.s16) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.tipSlip(.caption))
                            .foregroundStyle(Colors.danger)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await viewModel.login(using: authService) }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In").font(.tipSlip(.bodyEmphasis))
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

                NavigationLink("Don't have an account? Register") {
                    RegisterView()
                }
                .font(.tipSlip(.body))
                .foregroundStyle(Colors.brandPrimary)
                .padding(.bottom, Spacing.s32)
            }
            .background(Colors.backgroundPrimary)
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthService())
}
