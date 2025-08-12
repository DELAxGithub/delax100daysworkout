import Foundation

enum AppError: LocalizedError {
    case networkUnavailable
    case dataCorrupted
    case userCancelled
    case invalidInput(String)
    case databaseError(String)
    case fileOperationFailed(String)
    case authenticationFailed
    case unknown(Error)
    
    var errorDescription: String? {
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
        case .unknown(let error):
            return "予期しないエラーが発生しました: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Wi-Fiまたはモバイルデータの接続を確認してください"
        case .dataCorrupted:
            return "アプリを再起動するか、データを再同期してください"
        case .authenticationFailed:
            return "設定画面から再ログインしてください"
        case .databaseError:
            return "アプリを再起動してもう一度お試しください"
        default:
            return "問題が続く場合は、アプリを再起動してください"
        }
    }
}