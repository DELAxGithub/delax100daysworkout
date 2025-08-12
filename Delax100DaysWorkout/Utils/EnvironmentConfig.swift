import Foundation
import CryptoKit

struct EnvironmentConfig {
    private static let keychain = KeychainService.shared
    
    // MARK: - GitHub Configuration
    
    static var githubToken: String? {
        // First try Keychain, then fall back to environment variables for backward compatibility
        if let token = keychain.retrieveGitHubToken() {
            return token
        }
        
        // Migrate from environment if available
        if let envToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"],
           !envToken.isEmpty,
           !envToken.contains("your_github_token_here") {
            try? keychain.saveGitHubToken(envToken)
            return envToken
        }
        
        return nil
    }
    
    static var githubOwner: String {
        ProcessInfo.processInfo.environment["GITHUB_OWNER"] ?? "DELAxGithub"
    }
    
    static var githubRepo: String {
        ProcessInfo.processInfo.environment["GITHUB_REPO"] ?? "delax100daysworkout"
    }
    
    // MARK: - Claude API Configuration
    
    static var claudeAPIKey: String? {
        // First try Keychain, then fall back to environment variables for backward compatibility
        if let key = keychain.retrieveClaudeAPIKey() {
            return key
        }
        
        // Migrate from environment if available
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"],
           !envKey.isEmpty,
           !envKey.contains("your_claude_api_key_here") {
            try? keychain.saveClaudeAPIKey(envKey)
            return envKey
        }
        
        return nil
    }
    
    // MARK: - Environment Detection
    
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Validation
    
    static var hasValidTokens: Bool {
        guard let token = githubToken else { return false }
        return isValidGitHubToken(token)
    }
    
    static func validateTokens() -> (isValid: Bool, message: String) {
        // Validate GitHub token
        guard let githubToken = githubToken else {
            return (false, "GitHub tokenが設定されていません。設定画面から追加してください。")
        }
        
        if !isValidGitHubToken(githubToken) {
            return (false, "GitHub tokenの形式が無効です。")
        }
        
        // Validate Claude API key (optional)
        if let claudeKey = claudeAPIKey {
            if !isValidClaudeAPIKey(claudeKey) {
                return (false, "Claude API keyの形式が無効です。")
            }
        }
        
        return (true, "すべての認証情報が正しく設定されています。")
    }
    
    // MARK: - Secure Token Management
    
    static func setGitHubToken(_ token: String) throws {
        guard isValidGitHubToken(token) else {
            throw CredentialError.invalidFormat
        }
        try keychain.saveGitHubToken(token)
    }
    
    static func setClaudeAPIKey(_ key: String) throws {
        guard isValidClaudeAPIKey(key) else {
            throw CredentialError.invalidFormat
        }
        try keychain.saveClaudeAPIKey(key)
    }
    
    static func clearAllCredentials() {
        keychain.clearAllCredentials()
    }
    
    // MARK: - Token Validation
    
    private static func isValidGitHubToken(_ token: String) -> Bool {
        // GitHub personal access tokens start with 'ghp_' (fine-grained) or 'github_pat_' (classic)
        // Classic tokens are 40 characters, fine-grained are longer
        let patterns = [
            "^ghp_[a-zA-Z0-9]{36,}$",
            "^github_pat_[a-zA-Z0-9_]{36,}$",
            "^[a-f0-9]{40}$" // Legacy format
        ]
        
        return patterns.contains { pattern in
            token.range(of: pattern, options: .regularExpression) != nil
        }
    }
    
    private static func isValidClaudeAPIKey(_ key: String) -> Bool {
        // Claude API keys typically start with 'sk-ant-'
        return key.hasPrefix("sk-ant-") && key.count > 20
    }
    
    // MARK: - Security Hash (for logging purposes only)
    
    static func hashForLogging(_ credential: String) -> String {
        // Only show first 4 and last 4 characters for debugging
        guard credential.count > 8 else { return "****" }
        let prefix = credential.prefix(4)
        let suffix = credential.suffix(4)
        return "\(prefix)****\(suffix)"
    }
}

// MARK: - Errors

enum CredentialError: LocalizedError {
    case invalidFormat
    case storageFailure
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "認証情報の形式が無効です"
        case .storageFailure:
            return "認証情報の保存に失敗しました"
        case .notFound:
            return "認証情報が見つかりません"
        }
    }
}