import Foundation
import UIKit

struct ImageUploadService {
    private let imgurClientId = "YOUR_IMGUR_CLIENT_ID" // 実際の運用時には設定が必要
    
    // MARK: - Public Methods
    
    func uploadImage(_ imageData: Data) async throws -> String {
        // 本格運用時はimgur APIを使用
        // 現在はGitHub Gistを使用した代替実装
        return try await uploadToGitHubGist(imageData)
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
    
    // MARK: - Private Methods - GitHub Gist Upload
    
    private func uploadToGitHubGist(_ imageData: Data) async throws -> String {
        guard let token = EnvironmentConfig.githubToken else {
            throw ImageUploadError.missingToken
        }
        
        // 画像を最適化
        let optimizedData = optimizeImage(imageData) ?? imageData
        let base64String = optimizedData.base64EncodedString()
        
        // Gistの作成
        let gistData = GistCreateRequest(
            description: "Bug report screenshot - \(Date().formatted())",
            public: false,
            files: [
                "screenshot.txt": GistFile(content: base64String)
            ]
        )
        
        let url = URL(string: "https://api.github.com/gists")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(gistData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw ImageUploadError.uploadFailed
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let gist = try decoder.decode(GistResponse.self, from: data)
        
        // Raw URLを生成
        guard let file = gist.files.values.first,
              let rawUrl = file.rawUrl else {
            throw ImageUploadError.invalidResponse
        }
        
        return rawUrl
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