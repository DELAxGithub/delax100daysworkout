import Foundation

/// Unified error type for the entire application
/// Provides consistent error handling and user-friendly messages
enum AppError: LocalizedError {
    // MARK: - Network Errors
    case networkUnavailable
    case apiRequestFailed(Error)
    case unauthorized
    case serverError(statusCode: Int)
    case invalidResponse
    
    // MARK: - Data Errors
    case dataCorrupted
    case dataNotFound
    case failedToSave(Error)
    case failedToLoad(Error)
    case invalidData(reason: String)
    
    // MARK: - User Errors
    case userCancelled
    case invalidInput(field: String, reason: String)
    case permissionDenied(feature: String)
    
    // MARK: - Health Data Errors
    case healthDataNotAvailable
    case healthKitNotAuthorized
    case healthDataSyncFailed(Error)
    
    // MARK: - AI Service Errors
    case aiServiceUnavailable
    case aiRequestFailed(Error)
    case aiCostLimitExceeded
    case aiInvalidConfiguration
    
    // MARK: - GitHub Integration Errors
    case githubTokenMissing
    case githubRequestFailed(Error)
    case githubRepositoryNotFound
    
    // MARK: - Image Errors
    case imageUploadFailed(Error)
    case imageTooLarge
    case invalidImageFormat
    
    // MARK: - General Errors
    case unknown(Error)
    case notImplemented(feature: String)
    case timeout
    
    // MARK: - Error Descriptions
    var errorDescription: String? {
        switch self {
        // Network Errors
        case .networkUnavailable:
            return "インターネット接続を確認してください"
        case .apiRequestFailed:
            return "リクエストが失敗しました"
        case .unauthorized:
            return "認証が必要です"
        case .serverError(let statusCode):
            return "サーバーエラーが発生しました (コード: \(statusCode))"
        case .invalidResponse:
            return "無効なレスポンスを受信しました"
            
        // Data Errors
        case .dataCorrupted:
            return "データが破損しています"
        case .dataNotFound:
            return "データが見つかりません"
        case .failedToSave:
            return "データの保存に失敗しました"
        case .failedToLoad:
            return "データの読み込みに失敗しました"
        case .invalidData(let reason):
            return "無効なデータ: \(reason)"
            
        // User Errors
        case .userCancelled:
            return "操作がキャンセルされました"
        case .invalidInput(let field, let reason):
            return "\(field)が無効です: \(reason)"
        case .permissionDenied(let feature):
            return "\(feature)へのアクセスが拒否されました"
            
        // Health Data Errors
        case .healthDataNotAvailable:
            return "ヘルスデータが利用できません"
        case .healthKitNotAuthorized:
            return "ヘルスケアへのアクセスが許可されていません"
        case .healthDataSyncFailed:
            return "ヘルスデータの同期に失敗しました"
            
        // AI Service Errors
        case .aiServiceUnavailable:
            return "AI サービスが利用できません"
        case .aiRequestFailed:
            return "AI リクエストが失敗しました"
        case .aiCostLimitExceeded:
            return "AI 利用料の上限に達しました"
        case .aiInvalidConfiguration:
            return "AI サービスの設定が無効です"
            
        // GitHub Integration Errors
        case .githubTokenMissing:
            return "GitHub トークンが設定されていません"
        case .githubRequestFailed:
            return "GitHub リクエストが失敗しました"
        case .githubRepositoryNotFound:
            return "GitHub リポジトリが見つかりません"
            
        // Image Errors
        case .imageUploadFailed:
            return "画像のアップロードに失敗しました"
        case .imageTooLarge:
            return "画像サイズが大きすぎます"
        case .invalidImageFormat:
            return "サポートされていない画像形式です"
            
        // General Errors
        case .unknown:
            return "予期しないエラーが発生しました"
        case .notImplemented(let feature):
            return "\(feature)はまだ実装されていません"
        case .timeout:
            return "操作がタイムアウトしました"
        }
    }
    
    // MARK: - Recovery Suggestions
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Wi-Fiまたはモバイルデータ接続を確認してから、もう一度お試しください"
        case .unauthorized:
            return "設定からログインし直してください"
        case .healthKitNotAuthorized:
            return "設定アプリでヘルスケアへのアクセスを許可してください"
        case .aiCostLimitExceeded:
            return "設定から AI 利用料の上限を調整するか、来月まで待ってください"
        case .githubTokenMissing:
            return "設定から GitHub トークンを設定してください"
        case .imageTooLarge:
            return "10MB以下の画像を選択してください"
        case .dataCorrupted:
            return "アプリを再起動してください。問題が続く場合はサポートにお問い合わせください"
        case .timeout:
            return "しばらく待ってから、もう一度お試しください"
        default:
            return nil
        }
    }
    
    // MARK: - Error Details for Logging
    var underlyingError: Error? {
        switch self {
        case .apiRequestFailed(let error),
             .failedToSave(let error),
             .failedToLoad(let error),
             .healthDataSyncFailed(let error),
             .aiRequestFailed(let error),
             .githubRequestFailed(let error),
             .imageUploadFailed(let error),
             .unknown(let error):
            return error
        default:
            return nil
        }
    }
    
    // MARK: - Error Code for Analytics
    var errorCode: String {
        switch self {
        case .networkUnavailable: return "NET_001"
        case .apiRequestFailed: return "NET_002"
        case .unauthorized: return "AUTH_001"
        case .serverError: return "NET_003"
        case .invalidResponse: return "NET_004"
        case .dataCorrupted: return "DATA_001"
        case .dataNotFound: return "DATA_002"
        case .failedToSave: return "DATA_003"
        case .failedToLoad: return "DATA_004"
        case .invalidData: return "DATA_005"
        case .userCancelled: return "USER_001"
        case .invalidInput: return "USER_002"
        case .permissionDenied: return "USER_003"
        case .healthDataNotAvailable: return "HEALTH_001"
        case .healthKitNotAuthorized: return "HEALTH_002"
        case .healthDataSyncFailed: return "HEALTH_003"
        case .aiServiceUnavailable: return "AI_001"
        case .aiRequestFailed: return "AI_002"
        case .aiCostLimitExceeded: return "AI_003"
        case .aiInvalidConfiguration: return "AI_004"
        case .githubTokenMissing: return "GH_001"
        case .githubRequestFailed: return "GH_002"
        case .githubRepositoryNotFound: return "GH_003"
        case .imageUploadFailed: return "IMG_001"
        case .imageTooLarge: return "IMG_002"
        case .invalidImageFormat: return "IMG_003"
        case .unknown: return "GEN_001"
        case .notImplemented: return "GEN_002"
        case .timeout: return "GEN_003"
        }
    }
    
    // MARK: - Severity Level
    enum Severity {
        case low       // User can continue using the app
        case medium    // Some features affected
        case high      // Major functionality affected
        case critical  // App unusable
    }
    
    var severity: Severity {
        switch self {
        case .userCancelled, .notImplemented:
            return .low
        case .networkUnavailable, .invalidInput, .timeout:
            return .medium
        case .dataCorrupted, .unauthorized, .healthKitNotAuthorized:
            return .high
        case .unknown:
            return .critical
        default:
            return .medium
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert any Error to AppError
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Check for common system errors
        let nsError = error as NSError
        switch nsError.domain {
        case NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost:
                return .networkUnavailable
            case NSURLErrorTimedOut:
                return .timeout
            case NSURLErrorUserCancelledAuthentication:
                return .unauthorized
            default:
                return .apiRequestFailed(error)
            }
        default:
            return .unknown(error)
        }
    }
}