import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.delax.100daysworkout"
    private let accessGroup: String? = nil
    
    private init() {}
    
    enum KeychainError: LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unhandledError(status: OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "認証情報が見つかりません"
            case .duplicateItem:
                return "認証情報が既に存在します"
            case .invalidData:
                return "無効なデータ形式です"
            case .unhandledError(let status):
                return "Keychainエラー: \(status)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query = createQuery(for: key)
        var queryWithData = query
        queryWithData[kSecValueData as String] = data
        
        let status = SecItemAdd(queryWithData as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            try update(data, for: key)
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func retrieve(for key: String) throws -> String {
        var query = createQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return value
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func delete(for key: String) throws {
        let query = createQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func exists(for key: String) -> Bool {
        let query = createQuery(for: key)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Private Methods
    
    private func createQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
    
    private func update(_ data: Data, for key: String) throws {
        let query = createQuery(for: key)
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Convenience Methods for Credentials
    
    func saveGitHubToken(_ token: String) throws {
        try save(token, for: "github_token")
    }
    
    func retrieveGitHubToken() -> String? {
        try? retrieve(for: "github_token")
    }
    
    func saveClaudeAPIKey(_ key: String) throws {
        try save(key, for: "claude_api_key")
    }
    
    func retrieveClaudeAPIKey() -> String? {
        try? retrieve(for: "claude_api_key")
    }
    
    func clearAllCredentials() {
        try? delete(for: "github_token")
        try? delete(for: "claude_api_key")
    }
    
    // MARK: - Migration from Environment Variables
    
    func migrateFromEnvironmentIfNeeded() {
        // GitHub Token migration
        if !exists(for: "github_token"),
           let envToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"],
           !envToken.isEmpty,
           !envToken.contains("your_github_token_here") {
            try? saveGitHubToken(envToken)
            print("GitHub token migrated to Keychain")
        }
        
        // Claude API Key migration
        if !exists(for: "claude_api_key"),
           let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"],
           !envKey.isEmpty,
           !envKey.contains("your_claude_api_key_here") {
            try? saveClaudeAPIKey(envKey)
            print("Claude API key migrated to Keychain")
        }
    }
}