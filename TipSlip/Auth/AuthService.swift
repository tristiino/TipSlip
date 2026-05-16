import Foundation

@Observable
@MainActor
final class AuthService {

    private(set) var isAuthenticated: Bool
    private(set) var username: String?

    init() {
        isAuthenticated = KeychainService.loadToken() != nil
        username = KeychainService.loadUsername()
    }

    func login(email: String, password: String) async throws {
        struct LoginRequest: Encodable {
            let usernameOrEmail: String
            let password: String
        }

        let response: AuthResponse = try await NetworkClient.post(
            "/auth/login",
            body: LoginRequest(usernameOrEmail: email, password: password)
        )

        KeychainService.saveToken(response.token)
        KeychainService.saveUsername(response.user.username)
        username = response.user.username
        isAuthenticated = true
    }

    func register(username: String, email: String, password: String) async throws {
        struct RegisterRequest: Encodable {
            let username: String
            let email: String
            let password: String
        }

        let response: RegisterResponse = try await NetworkClient.post(
            "/auth/register",
            body: RegisterRequest(username: username, email: email, password: password)
        )

        KeychainService.saveToken(response.token)
        KeychainService.saveUsername(response.user.username)
        self.username = response.user.username
        isAuthenticated = true
    }

    func signOut() {
        KeychainService.clearAll()
        isAuthenticated = false
        username = nil
    }
}
