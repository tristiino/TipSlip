import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            PlaceholderView(title: "Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            PlaceholderView(title: "Add Tip")
                .tabItem {
                    Label("Add Tip", systemImage: "plus.circle.fill")
                }

            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: Spacing.s24) {
                    Text("Settings")
                        .font(.titleLarge)
                        .foregroundStyle(Color.textPrimary)

                    if let username = authService.username {
                        Text("Signed in as \(username)")
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Button("Sign Out") {
                        authService.signOut()
                    }
                    .font(.bodyMedium)
                    .foregroundStyle(Color.semanticDanger)
                }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(colorScheme == .dark ? Color.brandAccent : Color.brandPrimary)
    }
}

#Preview("Light") {
    ContentView()
        .environment(AuthService())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .environment(AuthService())
        .preferredColorScheme(.dark)
}
