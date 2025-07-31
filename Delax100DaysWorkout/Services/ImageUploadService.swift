import Foundation
import UIKit

struct ImageUploadService {
    private let imgurClientId = "YOUR_IMGUR_CLIENT_ID" // 実際の運用時には設定が必要
    
    // MARK: - Public Methods
    
    func uploadImage(_ imageData: Data) async throws -> String {
        // 現在はローカル保存とbase64の短縮版を使用（テスト目的）
        // 将来的にImgur APIを実装予定
        return try await createLocalImageReference(imageData)
    }
    
    func optimizeImage(_ originalData: Data, maxSizeKB: Int = 500) -> Data? {
        guard let image = UIImage(data: originalData) else { return nil }
        
        // 画像サイズを調整（最大幅800px）
        let maxWidth: CGFloat = 800
        let scale = min(maxWidth / image.size.width, maxWidth / image.size.height)
        
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // 品質を調整してサイズを制限
        var compressionQuality: CGFloat = 0.8
        var compressedData = resizedImage.jpegData(compressionQuality: compressionQuality)
        
        let targetSize = maxSizeKB * 1024
        while let data = compressedData, data.count > targetSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            compressedData = resizedImage.jpegData(compressionQuality: compressionQuality)
        }
        
        return compressedData
    }
    
    // MARK: - Private Methods - Local Image Storage
    
    private func createLocalImageReference(_ imageData: Data) async throws -> String {
        // 画像を最適化して小さくする
        let optimizedData = optimizeImage(imageData, maxSizeKB: 100) ?? imageData
        
        // 一意のファイル名を生成
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "screenshot_\(timestamp).jpg"
        
        // ローカルファイルとして保存
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        try optimizedData.write(to: fileURL)
        print("[ImageUploadService] Image saved locally: \(fileURL.path)")
        
        // GitHub Issue用の情報を含む説明テキストを返す
        let imageInfo = """
        **スクリーンショット情報**
        - ファイル名: \(filename)
        - サイズ: \(optimizedData.count) bytes
        - 保存時刻: \(Date().formatted())
        - ローカルパス: \(fileURL.path)
        
        ℹ️ スクリーンショットはローカルに保存されました。
        """
        
        return imageInfo
    }
    
    // MARK: - Future Implementation - Imgur API
    
    private func uploadToImgur(_ imageData: Data) async throws -> String {
        // 将来的にimgur APIを使用する場合の実装
        // 現在は未実装
        throw ImageUploadError.notImplemented
    }
}

// MARK: - Data Models

struct GistCreateRequest: Codable {
    let description: String
    let `public`: Bool
    let files: [String: GistFile]
}

struct GistFile: Codable {
    let content: String
}

struct GistResponse: Codable {
    let id: String
    let htmlUrl: String
    let files: [String: GistFileResponse]
}

struct GistFileResponse: Codable {
    let filename: String
    let type: String?
    let size: Int
    let rawUrl: String?
}

// MARK: - Error Types

enum ImageUploadError: LocalizedError {
    case missingToken
    case uploadFailed
    case invalidResponse
    case notImplemented
    case imageTooLarge
    
    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "GitHub token is not configured"
        case .uploadFailed:
            return "Failed to upload image"
        case .invalidResponse:
            return "Invalid response from server"
        case .notImplemented:
            return "Feature not implemented"
        case .imageTooLarge:
            return "Image is too large to upload"
        }
    }
}