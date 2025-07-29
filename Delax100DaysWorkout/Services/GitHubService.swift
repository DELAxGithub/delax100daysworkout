import Foundation

struct GitHubService {
    private let owner: String
    private let repo: String
    private let token: String?
    
    init() {
        self.owner = EnvironmentConfig.githubOwner
        self.repo = EnvironmentConfig.githubRepo
        self.token = EnvironmentConfig.githubToken
    }
    
    // MARK: - Issue Creation
    
    func createIssue(from bugReport: BugReport) async throws -> GitHubIssue {
        guard let token = token else {
            throw GitHubError.missingToken
        }
        
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/issues")!
        print("GitHub API URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let issueBody = IssueBody(
            title: generateTitle(for: bugReport),
            body: generateBody(for: bugReport),
            labels: generateLabels(for: bugReport)
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(issueBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        // デバッグ情報をログ出力
        print("GitHub API Response Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 201 {
            // エラーレスポンスの詳細を取得
            if let errorData = String(data: data, encoding: .utf8) {
                print("GitHub API Error Response: \(errorData)")
            }
            
            // ステータスコードに応じた詳細なエラー
            switch httpResponse.statusCode {
            case 401:
                throw GitHubError.unauthorized
            case 404:
                throw GitHubError.repositoryNotFound
            case 422:
                throw GitHubError.validationFailed
            default:
                throw GitHubError.failedToCreateIssue
            }
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let issue = try decoder.decode(GitHubIssue.self, from: data)
        
        // スクリーンショットがある場合は、コメントとして追加
        if let screenshot = bugReport.screenshot {
            try await addScreenshot(screenshot, to: issue.number)
        }
        
        return issue
    }
    
    // MARK: - Screenshot Upload
    
    private func addScreenshot(_ imageData: Data, to issueNumber: Int) async throws {
        // GitHubは画像の直接アップロードをサポートしていないため、
        // 実際の実装では、画像をBase64エンコードしてコメントに含めるか、
        // 外部の画像ホスティングサービスを使用する必要があります
        
        let base64Image = imageData.base64EncodedString()
        let imageMarkdown = "![Screenshot](data:image/jpeg;base64,\(base64Image))"
        
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/issues/\(issueNumber)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let comment = ["body": "## スクリーンショット\n\(imageMarkdown)"]
        request.httpBody = try JSONSerialization.data(withJSONObject: comment)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            // スクリーンショットのアップロードに失敗しても、Issueは作成済みなので続行
            print("Failed to upload screenshot")
            return
        }
        // 正常に完了
    }
    
    // MARK: - Helper Methods
    
    private func generateTitle(for bugReport: BugReport) -> String {
        let categoryName = bugReport.category.displayName
        let viewName = bugReport.currentView
        return "[\(categoryName)] \(viewName)での問題"
    }
    
    private func generateBody(for bugReport: BugReport) -> String {
        var body = """
        ## バグ報告
        
        **カテゴリ**: \(bugReport.category.displayName)
        **報告時刻**: \(ISO8601DateFormatter().string(from: bugReport.timestamp))
        **デバイス**: \(bugReport.deviceInfo.model) (\(bugReport.deviceInfo.osVersion))
        **アプリバージョン**: \(bugReport.appVersion)
        **現在の画面**: \(bugReport.currentView)
        
        """
        
        if let description = bugReport.description {
            body += """
            ### 問題の説明
            \(description)
            
            """
        }
        
        if let reproductionSteps = bugReport.reproductionSteps {
            body += """
            ### 再現手順
            \(reproductionSteps)
            
            """
        }
        
        if let expectedBehavior = bugReport.expectedBehavior {
            body += """
            ### 期待される動作
            \(expectedBehavior)
            
            """
        }
        
        if let actualBehavior = bugReport.actualBehavior {
            body += """
            ### 実際の動作
            \(actualBehavior)
            
            """
        }
        
        if !bugReport.userActions.isEmpty {
            body += """
            ### 操作履歴
            """
            for (index, action) in bugReport.userActions.enumerated() {
                body += "\n\(index + 1). [\(formatDate(action.timestamp))] \(action.action) in \(action.viewName)"
                if let details = action.details {
                    body += " - \(details.map { "\($0.key): \($0.value)" }.joined(separator: ", "))"
                }
            }
            body += "\n\n"
        }
        
        if !bugReport.logs.isEmpty {
            body += """
            ### ログ（エラー・警告のみ）
            ```
            """
            for log in bugReport.logs {
                body += "\n[\(formatDate(log.timestamp))] [\(log.level.rawValue)] \(log.message)"
                if let source = log.source {
                    body += " (\(source))"
                }
            }
            body += "\n```\n"
        }
        
        body += """
        
        ### デバイス情報
        - Model: \(bugReport.deviceInfo.model)
        - OS: \(bugReport.deviceInfo.osVersion)
        - Screen: \(bugReport.deviceInfo.screenSize)
        - App Version: \(bugReport.appVersion)
        
        ---
        *このIssueは自動的に作成されました*
        """
        
        return body
    }
    
    private func generateLabels(for bugReport: BugReport) -> [String] {
        var labels = ["bug", "auto-generated"]
        
        // カテゴリに基づくラベル
        switch bugReport.category {
        case .buttonNotWorking, .displayIssue:
            labels.append("ui-bug")
        case .appFreeze, .dataNotSaved:
            labels.append("critical")
        case .other:
            break
        }
        
        // 自動修正候補の判定
        switch bugReport.category {
        case .buttonNotWorking:
            labels.append("auto-fix-candidate")
            print("Added auto-fix-candidate label for button not working issue")
        case .displayIssue:
            // 表示問題も自動修正候補に
            labels.append("auto-fix-candidate")
            print("Added auto-fix-candidate label for display issue")
        default:
            break
        }
        
        return labels
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Data Models

struct IssueBody: Encodable {
    let title: String
    let body: String
    let labels: [String]
}

struct GitHubIssue: Decodable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let htmlUrl: String
    let state: String
    let labels: [GitHubLabel]
}

struct GitHubLabel: Decodable {
    let id: Int
    let name: String
    let color: String
}

// MARK: - Errors

enum GitHubError: LocalizedError {
    case missingToken
    case failedToCreateIssue
    case invalidResponse
    case unauthorized
    case repositoryNotFound
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "GitHubトークンが設定されていません"
        case .failedToCreateIssue:
            return "Issueの作成に失敗しました"
        case .invalidResponse:
            return "無効なレスポンスを受信しました"
        case .unauthorized:
            return "GitHubトークンが無効です。トークンの権限とスコープを確認してください"
        case .repositoryNotFound:
            return "リポジトリが見つかりません。オーナー名とリポジトリ名を確認してください"
        case .validationFailed:
            return "Issueのデータ検証に失敗しました"
        }
    }
}