import Foundation

enum AppError: LocalizedError {
    case networkUnavailable
    case dataCorrupted
    case userCancelled
    case invalidInput(String)
    case databaseError(String)
    case fileOperationFailed(String)
    case authenticationFailed
    case swiftDataOperationFailed(String)
    case permissionDenied(String)
    case operationTimeout
    case insufficientStorage
    case unknown(Error)
    
    // MARK: - Multilingual Support
    
    private var isJapanese: Bool {
        Locale.current.languageCode == "ja" || 
        Locale.preferredLanguages.first?.hasPrefix("ja") == true
    }
    
    var errorDescription: String? {
        if isJapanese {
            return japaneseErrorDescription
        } else {
            return englishErrorDescription
        }
    }
    
    private var japaneseErrorDescription: String {
        switch self {
        case .networkUnavailable:
            return "インターネット接続を確認してもう一度お試しください"
        case .dataCorrupted:
            return "データに問題があります。サポートまでお問い合わせください"
        case .userCancelled:
            return "操作がキャンセルされました"
        case .invalidInput(let message):
            return "入力エラー: \(message)"
        case .databaseError(let message):
            return "データベースエラー: \(message)"
        case .fileOperationFailed(let message):
            return "ファイル操作エラー: \(message)"
        case .authenticationFailed:
            return "認証に失敗しました。再度ログインしてください"
        case .swiftDataOperationFailed(let message):
            return "データ操作エラー: \(message)"
        case .permissionDenied(let message):
            return "アクセス許可エラー: \(message)"
        case .operationTimeout:
            return "処理がタイムアウトしました。もう一度お試しください"
        case .insufficientStorage:
            return "ストレージ容量が不足しています"
        case .unknown(let error):
            return "予期しないエラーが発生しました: \(error.localizedDescription)"
        }
    }
    
    private var englishErrorDescription: String {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again"
        case .dataCorrupted:
            return "There was a problem with your data. Please contact support"
        case .userCancelled:
            return "Operation was cancelled"
        case .invalidInput(let message):
            return "Input error: \(message)"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .fileOperationFailed(let message):
            return "File operation failed: \(message)"
        case .authenticationFailed:
            return "Authentication failed. Please login again"
        case .swiftDataOperationFailed(let message):
            return "Data operation failed: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .operationTimeout:
            return "Operation timed out. Please try again"
        case .insufficientStorage:
            return "Insufficient storage space"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        if isJapanese {
            return japaneseRecoverySuggestion
        } else {
            return englishRecoverySuggestion
        }
    }
    
    private var japaneseRecoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Wi-Fiまたはモバイルデータの接続を確認してください"
        case .dataCorrupted:
            return "アプリを再起動するか、データを再同期してください"
        case .authenticationFailed:
            return "設定画面から再ログインしてください"
        case .databaseError, .swiftDataOperationFailed:
            return "アプリを再起動してもう一度お試しください"
        case .operationTimeout:
            return "しばらく待ってからもう一度お試しください"
        case .insufficientStorage:
            return "不要なファイルを削除してからもう一度お試しください"
        case .permissionDenied:
            return "設定でアプリの権限を確認してください"
        default:
            return "問題が続く場合は、アプリを再起動してください"
        }
    }
    
    private var englishRecoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your Wi-Fi or cellular connection"
        case .dataCorrupted:
            return "Please restart the app or resync your data"
        case .authenticationFailed:
            return "Please log in again from the settings screen"
        case .databaseError, .swiftDataOperationFailed:
            return "Please restart the app and try again"
        case .operationTimeout:
            return "Please wait a moment and try again"
        case .insufficientStorage:
            return "Please free up some storage space and try again"
        case .permissionDenied:
            return "Please check app permissions in settings"
        default:
            return "If the problem persists, please restart the app"
        }
    }
}