import Foundation

enum AppError: LocalizedError {
    case badRequest(String)
    case unauthorized
    case forbidden
    case notFound
    case conflict(String)
    case validation([String])
    case server
    case offline
    case timeout
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .badRequest:  return "We couldn't complete that. Please check your input and try again."
        case .unauthorized: return "Your session expired. Please sign in again."
        case .forbidden:   return "You don't have access to that."
        case .notFound:    return "We couldn't find that."
        case .conflict:    return "That already exists."
        case .validation:  return "Some fields need attention."
        case .server:      return "Something went wrong on our side. We're working on it."
        case .offline:     return "You're offline. Try again when you reconnect."
        case .timeout:     return "This is taking too long. Tap to retry."
        case .decoding:    return "We received an unexpected response."
        }
    }
}
