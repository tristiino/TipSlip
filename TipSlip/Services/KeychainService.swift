import Foundation
import Security

enum KeychainService {

    private static let service = "org.tiptrackerapp.ios.jwt"
    private static let tokenKey = "jwt_token"
    private static let usernameKey = "username"

    static func saveToken(_ token: String) {
        save(token, forKey: tokenKey)
    }

    static func loadToken() -> String? {
        load(forKey: tokenKey)
    }

    static func saveUsername(_ username: String) {
        save(username, forKey: usernameKey)
    }

    static func loadUsername() -> String? {
        load(forKey: usernameKey)
    }

    static func clearAll() {
        delete(forKey: tokenKey)
        delete(forKey: usernameKey)
    }

    // MARK: - Private

    private static func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(forKey: key)

        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecAttrAccount:     key,
            kSecValueData:       data,
            kSecAttrAccessible:  kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func load(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
