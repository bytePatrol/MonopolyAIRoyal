import Foundation
import Security

// MARK: - Keychain Service

enum KeychainService {
    private static let service = "com.monopolyai.MonopolyAIRoyalV7"

    // MARK: - Account Keys

    enum Account: String {
        case openRouterPrimary    = "openrouter_primary"
        case openRouterFallback1  = "openrouter_fallback_1"
        case openRouterFallback2  = "openrouter_fallback_2"
        case openRouterFallback3  = "openrouter_fallback_3"
        case elevenLabs           = "elevenlabs"
    }

    // MARK: - Store

    @discardableResult
    static func store(key: String, account: Account) -> Bool {
        let data = Data(key.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account.rawValue,
            kSecValueData:   data,
        ]
        // Remove existing
        SecItemDelete(query as CFDictionary)
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Retrieve

    static func retrieve(account: Account) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account.rawValue,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    // MARK: - Delete

    @discardableResult
    static func delete(account: Account) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account.rawValue,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    // MARK: - Convenience: All OpenRouter Keys

    static func allOpenRouterKeys() -> [String] {
        let accounts: [Account] = [.openRouterPrimary, .openRouterFallback1, .openRouterFallback2, .openRouterFallback3]
        return accounts.compactMap { retrieve(account: $0) }.filter { !$0.isEmpty }
    }
}
