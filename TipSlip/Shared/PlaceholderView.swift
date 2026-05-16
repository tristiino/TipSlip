import SwiftUI

struct PlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: Spacing.s16) {
                Text(title)
                    .font(.titleMedium)
                    .foregroundStyle(Color.textPrimary)

                Text("Coming in Phase 2")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}
