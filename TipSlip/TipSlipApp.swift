import SwiftUI

@main
struct TipSlipApp: App {

    @State private var authService = AuthService()

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
        }
    }
}
