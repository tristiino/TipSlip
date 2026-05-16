import SwiftUI

@main
struct TipSlipApp: App {

    @State private var authService      = AuthService()
    @State private var settingsService  = SettingsService()
    @State private var tipService       = TipService()
    @State private var biometricService = BiometricService()

    @Environment(\.scenePhase) private var scenePhase
    @State private var wasInBackground = false
    @State private var showBiometricPrompt = false

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
            .environment(biometricService)
            .preferredColorScheme(colorScheme(for: settingsService.settings?.theme))
            .task {
                if authService.isAuthenticated {
                    await settingsService.load()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .sessionExpired)) { _ in
                authService.signOut()
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated && biometricService.isAvailable
                    && !UserDefaults.standard.bool(forKey: "biometricPromptShown") {
                    showBiometricPrompt = true
                    UserDefaults.standard.set(true, forKey: "biometricPromptShown")
                }
            }
            .alert("Enable \(biometricService.biometricLabel)?", isPresented: $showBiometricPrompt) {
                Button("Enable") { biometricService.isEnabled = true }
                Button("Not Now", role: .cancel) { }
            } message: {
                Text("Lock TipSlip when you leave and unlock instantly with \(biometricService.biometricLabel).")
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .background:
                    wasInBackground = true
                case .active:
                    if wasInBackground && authService.isAuthenticated {
                        biometricService.lock()
                    }
                    wasInBackground = false
                default:
                    break
                }
            }
            // Full-screen lock overlay — sits on top of everything when locked
            .overlay {
                if biometricService.isLocked {
                    BiometricLockView()
                        .environment(biometricService)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: biometricService.isLocked)
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
