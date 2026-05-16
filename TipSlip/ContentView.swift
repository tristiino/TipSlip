import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            AddTipView()
                .tabItem {
                    Label("Add Tip", systemImage: "plus.circle.fill")
                }

            SettingsView()
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
