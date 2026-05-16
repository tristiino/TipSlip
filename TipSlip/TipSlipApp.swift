import SwiftUI

@main
struct TipSlipApp: App {

    @State private var authService     = AuthService()
    @State private var settingsService = SettingsService()
    @State private var tipService      = TipService()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environment(authService)
            .environment(settingsService)
            .environment(tipService)
            .preferredColorScheme(colorScheme(for: settingsService.settings?.theme))
            .task {
                if authService.isAuthenticated {
                    await settingsService.load()
                }
            }
        }
    }

    private func colorScheme(for theme: AppTheme?) -> ColorScheme? {
        switch theme {
        case .light:  return .light
        case .dark:   return .dark
        default:      return nil  // nil = follow system
        }
    }
}
