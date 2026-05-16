import SwiftUI

struct TipSlipLogo: View {

    var body: some View {
        VStack(spacing: Spacing.s8) {
            Image("logo-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            VStack(spacing: Spacing.s4) {
                HStack(spacing: 0) {
                    Text("Tip")
                        .foregroundStyle(Color.textPrimary)
                    Text("Slip")
                        .foregroundStyle(Color.brandAccent)
                }
                .font(.titleLarge)

                Text("TRACK YOUR TIPS")
                    .font(.caption)
                    .kerning(0.08 * 12)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.bgPrimary.ignoresSafeArea()
        TipSlipLogo()
    }
}
