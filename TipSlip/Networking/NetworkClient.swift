import Foundation

enum NetworkClient {

    static let baseURL = "https://tiptrackerapp.org/api"

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // MARK: - Public methods

    static func get<T: Decodable>(_ path: String) async throws -> T {
        let request = try buildRequest(path: path, method: "GET", body: Optional<EmptyBody>.none)
        return try await perform(request)
    }

    static func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let request = try buildRequest(path: path, method: "POST", body: body)
        return try await perform(request)
    }

    static func put<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let request = try buildRequest(path: path, method: "PUT", body: body)
        return try await perform(request)
    }

    static func delete(_ path: String) async throws {
        let request = try buildRequest(path: path, method: "DELETE", body: Optional<EmptyBody>.none)
        let _: EmptyResponse = try await perform(request)
    }

    // MARK: - Private

    private struct EmptyBody: Encodable {}
    private struct EmptyResponse: Decodable {}

    private static func buildRequest<Body: Encodable>(
        path: String,
        method: String,
        body: Body?
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw AppError.badRequest("Invalid URL path: \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if let token = KeychainService.loadToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private static func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw AppError.offline
            case .timedOut:
                throw AppError.timeout
            default:
                throw AppError.offline
            }
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.server
        }

        switch http.statusCode {
        case 200...204:
            if let empty = EmptyResponse() as? T { return empty }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw AppError.decoding(error)
            }
        case 400:
            throw AppError.badRequest(extractMessage(from: data))
        case 401:
            KeychainService.clearAll()
            throw AppError.unauthorized
        case 403:
            throw AppError.forbidden
        case 404:
            throw AppError.notFound
        case 409:
            throw AppError.conflict(extractMessage(from: data))
        case 422:
            throw AppError.validation([extractMessage(from: data)])
        default:
            throw AppError.server
        }
    }

    private static func extractMessage(from data: Data) -> String {
        struct ErrorBody: Decodable { let message: String }
        return (try? decoder.decode(ErrorBody.self, from: data))?.message ?? "Unknown error"
    }
}
