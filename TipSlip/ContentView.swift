import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService

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

            // Temporary settings placeholder with sign out
            ZStack {
                Colors.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: Spacing.s24) {
                    Text("Settings")
                        .font(.tipSlip(.title))
                        .foregroundStyle(Colors.textPrimary)

                    if let username = authService.username {
                        Text("Signed in as \(username)")
                            .font(.tipSlip(.footnote))
                            .foregroundStyle(Colors.textSecondary)
                    }

                    Button("Sign Out") {
                        authService.signOut()
                    }
                    .font(.tipSlip(.bodyEmphasis))
                    .foregroundStyle(Colors.danger)
                }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(Colors.brandPrimary)
    }
}

#Preview("Light") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
