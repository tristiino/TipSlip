import Foundation

@Observable
@MainActor
final class RegisterViewModel {

    var username = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var errorMessage: String?

    func register(using authService: AuthService) async {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Username is required."
            return
        }
        guard (3...20).contains(username.count) else {
            errorMessage = "Username must be 3–20 characters."
            return
        }
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Email is required."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.register(username: username, email: email, password: password)
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isLoading = false
    }
}
