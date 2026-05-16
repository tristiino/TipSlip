import Foundation

struct AuthResponse: Decodable {
    let token: String
    let user: UserDto
}

struct UserDto: Decodable {
    let id: Int
    let email: String
    let username: String
}

struct RegisterResponse: Decodable {
    let token: String
    let user: UserDto
}
