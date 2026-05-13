import SwiftUI

struct ContentView: View {
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

            PlaceholderView(title: "Settings")
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
