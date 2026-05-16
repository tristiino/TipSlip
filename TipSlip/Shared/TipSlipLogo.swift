import SwiftUI

struct TipSlipLogo: View {

    var body: some View {
        VStack(spacing: Spacing.s12) {
            Image("logo-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

            VStack(spacing: Spacing.s4) {
                // Split-color wordmark: "Tip" navy, "Slip" orange
                HStack(spacing: 0) {
                    Text("Tip")
                        .foregroundStyle(Colors.textPrimary)
                    Text("Slip")
                        .foregroundStyle(Colors.brandAccent)
                }
                .font(.system(size: 32, weight: .bold))

                // Tagline
                Text("TRACK YOUR TIPS")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(Colors.textSecondary)
            }
        }
    }
}

#Preview {
    ZStack {
        Colors.backgroundPrimary.ignoresSafeArea()
        TipSlipLogo()
    }
}
