import Foundation

struct EnvironmentConfig {
    // GitHub設定
    static var githubToken: String? {
        ProcessInfo.processInfo.environment["GITHUB_TOKEN"]
    }
    
    static var githubOwner: String {
        ProcessInfo.processInfo.environment["GITHUB_OWNER"] ?? "DELAxGithub"
    }
    
    static var githubRepo: String {
        ProcessInfo.processInfo.environment["GITHUB_REPO"] ?? "delax100daysworkout"
    }
    
    // Claude API設定
    static var claudeAPIKey: String? {
        ProcessInfo.processInfo.environment["CLAUDE_API_KEY"]
    }
    
    // 環境判定
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var hasValidTokens: Bool {
        // GitHub Tokenのみ必須（Claude APIは自動修正機能でのみ使用）
        return githubToken != nil && !githubToken!.isEmpty
    }
    
    // トークンの検証
    static func validateTokens() -> (isValid: Bool, message: String) {
        if githubToken == nil {
            return (false, "GitHub tokenが設定されていません。.envファイルを確認してください。")
        }
        
        if githubToken?.contains("your_github_token_here") == true {
            return (false, "GitHub tokenがサンプル値のままです。実際のトークンを設定してください。")
        }
        
        if claudeAPIKey == nil {
            return (false, "Claude API keyが設定されていません。.envファイルを確認してください。")
        }
        
        if claudeAPIKey?.contains("your_claude_api_key_here") == true {
            return (false, "Claude API keyがサンプル値のままです。実際のキーを設定してください。")
        }
        
        return (true, "すべてのトークンが正しく設定されています。")
    }
}