import SwiftUI

struct BiometricLockView: View {

    @Environment(BiometricService.self) private var biometric

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: Spacing.s32) {

                // Brand logo + lock icon
                ZStack(alignment: .bottomTrailing) {
                    Image("logo-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.textSecondary)
                        .background(Color.bgPrimary, in: Circle())
                        .offset(x: 6, y: 6)
                }

                VStack(spacing: Spacing.s8) {
                    Text("TipSlip Locked")
                        .font(.titleMedium)
                        .foregroundStyle(Color.textPrimary)

                    Text("Use \(biometric.biometricLabel) to continue")
                        .font(.bodyRegular)
                        .foregroundStyle(Color.textSecondary)
                }

                // Error message (shown after a failed attempt)
                if let error = biometric.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.semanticDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.s32)
                }

                // Unlock button
                Button {
                    Task { await biometric.authenticate() }
                } label: {
                    Label(
                        "Unlock with \(biometric.biometricLabel)",
                        systemImage: biometric.biometricIcon
                    )
                    .font(.bodyMedium)
                    .tipPrimaryButton()
                }
                .padding(.horizontal, Spacing.s32)
                .accessibilityLabel("Unlock with \(biometric.biometricLabel)")
            }
        }
        .task {
            // Auto-prompt on appear
            await biometric.authenticate()
        }
    }
}
