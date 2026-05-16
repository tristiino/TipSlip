import Foundation

@Observable
@MainActor
final class LoginViewModel {

    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    func login(using authService: AuthService) async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.login(email: email, password: password)
        } catch AppError.unauthorized {
            errorMessage = "Invalid email or password. Please try again."
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isLoading = false
    }
}
