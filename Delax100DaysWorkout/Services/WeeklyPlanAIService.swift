import Foundation
import SwiftData
import OSLog

struct AIAnalysisRequest {
    let weeklyStats: WeeklyStats
    let progress: Progress
    let currentTemplate: WeeklyTemplate
    let userPreferences: UserPreferences?
}

struct UserPreferences {
    let preferredWorkoutDays: [Int] // 0-6 (Sunday-Saturday)
    let availableTime: Int // minutes per day
    let fitnessGoals: [String]
    let limitations: [String]
}

struct WeeklyPlanSuggestion {
    let recommendedChanges: [PlanChange]
    let reasoning: String
    let estimatedCost: Double
    let confidence: Double // 0-1
}

struct PlanChange {
    let dayOfWeek: Int
    let changeType: ChangeType
    let taskTitle: String
    let oldDetails: TargetDetails?
    let newDetails: TargetDetails
    let reason: String
    
    enum ChangeType {
        case modify
        case add
        case remove
        case intensity
    }
}

class WeeklyPlanAIService {
    private let claudeAPIKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    // APIキー状態の列挙型
    enum APIKeyStatus {
        case valid
        case missing
        case invalid
        case untested
    }
    
    private var _apiKeyStatus: APIKeyStatus = .untested
    
    init() {
        // APIキーを複数のソースから取得を試行
        if let apiKey = Self.getAPIKey() {
            self.claudeAPIKey = apiKey
        } else {
            self.claudeAPIKey = ""
            Logger.error.error("CLAUDE_API_KEY not found. AI features will not work.")
        }
        
        // 初期診断
        diagnosAPIKey()
    }
    
    // APIキー取得の優先順位
    private static func getAPIKey() -> String? {
        // 1. UserDefaults（設定画面で入力）
        let userDefaults = UserDefaults.standard
        if let savedKey = userDefaults.string(forKey: "claude_api_key"), !savedKey.isEmpty {
            return savedKey
        }
        
        // 2. 環境変数
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 3. Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let plistKey = plist["CLAUDE_API_KEY"] as? String,
           !plistKey.isEmpty && !plistKey.contains("<!-- ") {
            return plistKey
        }
        
        return nil
    }
    
    // APIキーの保存（設定画面で使用）
    static func saveAPIKey(_ key: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(key, forKey: "claude_api_key")
    }
    
    // APIキーの削除
    static func clearAPIKey() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "claude_api_key")
    }
    
    // MARK: - API Key Diagnosis
    
    var apiKeyStatus: APIKeyStatus {
        return _apiKeyStatus
    }
    
    var apiKeyStatusDescription: String {
        switch _apiKeyStatus {
        case .valid:
            return "APIキーは有効です"
        case .missing:
            return "APIキーが設定されていません"
        case .invalid:
            return "APIキーが無効です"
        case .untested:
            return "APIキーの状態を確認中..."
        }
    }
    
    private func diagnosAPIKey() {
        if claudeAPIKey.isEmpty {
            _apiKeyStatus = .missing
        } else if !isValidAPIKeyFormat(claudeAPIKey) {
            _apiKeyStatus = .invalid
        } else {
            _apiKeyStatus = .untested
        }
    }
    
    private func isValidAPIKeyFormat(_ key: String) -> Bool {
        // Claude APIキーの形式をチェック（sk-ant-から始まる）
        return key.hasPrefix("sk-ant-") && key.count > 20
    }
    
    // APIキーのテスト機能
    func testAPIKey() async -> APIKeyStatus {
        guard !claudeAPIKey.isEmpty else {
            _apiKeyStatus = .missing
            return _apiKeyStatus
        }
        
        guard isValidAPIKeyFormat(claudeAPIKey) else {
            _apiKeyStatus = .invalid
            return _apiKeyStatus
        }
        
        // 簡単なテストリクエストを送信
        do {
            _ = try await callClaudeAPI(prompt: "Hello")
            _apiKeyStatus = .valid
        } catch {
            if case AIServiceError.apiError(401) = error {
                _apiKeyStatus = .invalid
            } else {
                // その他のエラーは一時的な問題の可能性
                _apiKeyStatus = .untested
            }
        }
        
        return _apiKeyStatus
    }
    
    // メイン機能：週次プラン分析と提案
    func analyzeAndSuggestWeeklyPlan(request: AIAnalysisRequest) async throws -> WeeklyPlanSuggestion {
        guard !claudeAPIKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        // プロンプトを生成
        let prompt = buildAnalysisPrompt(request: request)
        
        // Claude APIを呼び出し
        let response = try await callClaudeAPI(prompt: prompt)
        
        // レスポンスを解析 - エラーを表面化
        return try parseAIResponse(response: response)
    }
    
    // コスト見積もり
    func estimateCost(request: AIAnalysisRequest) -> Double {
        let prompt = buildAnalysisPrompt(request: request)
        let inputTokens = estimateTokens(text: prompt)
        
        // Claude Sonnet 4の料金（$3/$15 per 1M tokens）
        let inputCost = Double(inputTokens) * 3.0 / 1_000_000
        let estimatedOutputTokens = 1000 // 予想される出力トークン数
        let outputCost = Double(estimatedOutputTokens) * 15.0 / 1_000_000
        
        return inputCost + outputCost
    }
    
    // MARK: - Private Methods
    
    private func buildAnalysisPrompt(request: AIAnalysisRequest) -> String {
        let stats = request.weeklyStats
        let progress = request.progress
        let template = request.currentTemplate
        
        return """
        あなたは経験豊富なフィットネストレーナーです。以下のユーザーの週次データを分析し、来週のトレーニングプランを最適化してください。

        ## 現在の週次統計
        - 完了率: \(String(format: "%.1f", stats.completionRate * 100))%
        - 総ワークアウト数: \(stats.completedWorkouts)/\(stats.totalWorkouts)
        
        ### サイクリング統計
        - 完了率: \(String(format: "%.1f", stats.cyclingStats.completionRate * 100))%
        - 平均パワー: \(Int(stats.cyclingStats.averageMetric))W
        - 改善点: \(stats.cyclingStats.improvements.joined(separator: ", "))
        
        ### 筋トレ統計
        - 完了率: \(String(format: "%.1f", stats.strengthStats.completionRate * 100))%
        - 平均負荷: \(Int(stats.strengthStats.averageMetric))kg
        - 改善点: \(stats.strengthStats.improvements.joined(separator: ", "))
        
        ### 柔軟性統計
        - 完了率: \(String(format: "%.1f", stats.flexibilityStats.completionRate * 100))%
        - 平均角度: \(Int(stats.flexibilityStats.averageMetric))°
        - 改善点: \(stats.flexibilityStats.improvements.joined(separator: ", "))

        ## 全体的な進捗
        - 現在のストリーク: \(progress.currentStreak)日
        - 最長ストリーク: \(progress.longestStreak)日
        - 週平均ワークアウト: \(String(format: "%.1f", progress.weeklyAverage))回
        
        ## 現在の週次プラン
        \(formatCurrentTemplate(template))

        ## 分析と提案のガイドライン
        1. **完了率分析**: 80%未満の場合は負荷軽減、90%以上で向上傾向なら強度アップを検討
        2. **バランス重視**: 3つのトレーニングタイプのバランスを保つ
        3. **漸進性原則**: 急激な変更は避け、5-10%の調整に留める
        4. **継続性重視**: ストリークが途切れないよう現実的な目標設定
        5. **個別最適化**: 各トレーニングタイプの傾向に基づいた調整

        以下のJSON形式で回答してください：

        {
          "recommendedChanges": [
            {
              "dayOfWeek": 1,
              "changeType": "modify",
              "taskTitle": "Push筋トレ",
              "newDetails": {
                "targetSets": 3,
                "targetReps": 12,
                "targetPower": null,
                "exercises": ["ベンチプレス", "ダンベルプレス"]
              },
              "reason": "前週の完了率が高く、強度を少し上げることが可能"
            }
          ],
          "reasoning": "全体的な分析結果と提案理由をここに記載",
          "confidence": 0.85
        }
        """
    }
    
    private func formatCurrentTemplate(_ template: WeeklyTemplate) -> String {
        var result = ""
        
        for day in 0...6 {
            let dayName = ["日", "月", "火", "水", "木", "金", "土"][day]
            let tasks = template.tasksForDay(day)
            
            result += "\n**\(dayName)曜日:**\n"
            
            if tasks.isEmpty {
                result += "  休息日\n"
            } else {
                for task in tasks {
                    result += "  - \(task.title): \(task.taskDescription ?? "")\n"
                    if let details = task.targetDetails {
                        if let power = details.targetPower {
                            result += "    目標パワー: \(power)W\n"
                        }
                        if let sets = details.targetSets, let reps = details.targetReps {
                            result += "    セット: \(sets)x\(reps)\n"
                        }
                        if let duration = details.targetDuration {
                            result += "    時間: \(duration)分\n"
                        }
                    }
                }
            }
        }
        
        return result
    }
    
    private func callClaudeAPI(prompt: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 2000,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.apiError(httpResponse.statusCode)
        }
        
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResponse["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIServiceError.parseError
        }
        
        return text
    }
    
    private func parseAIResponse(response: String) throws -> WeeklyPlanSuggestion {
        Logger.network.info("AI Response received: \(response)")
        
        // JSON部分を抽出 - 最も安全な方法
        guard let jsonStart = response.range(of: "{") else {
            Logger.error.error("Error: No opening brace found in response")
            throw AIServiceError.parseError
        }
        
        // 最後の }を検索
        guard let jsonEnd = response.range(of: "}", options: .backwards) else {
            Logger.error.error("Error: No closing brace found in response")
            throw AIServiceError.parseError
        }
        
        // 範囲の妥当性をチェック
        guard jsonStart.lowerBound < jsonEnd.upperBound else {
            Logger.error.error("Error: Invalid JSON range - start after end")
            throw AIServiceError.parseError
        }
        
        // 文字数での安全な抽出
        let startIndex = response.distance(from: response.startIndex, to: jsonStart.lowerBound)
        let endIndex = response.distance(from: response.startIndex, to: jsonEnd.upperBound)
        
        guard startIndex < endIndex, endIndex <= response.count else {
            Logger.error.error("Error: Invalid string indices")
            throw AIServiceError.parseError
        }
        
        let jsonString = String(response.dropFirst(startIndex).prefix(endIndex - startIndex))
        Logger.debug.debug("Extracted JSON: \(jsonString)")
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            Logger.error.error("Error: Could not convert JSON string to data")
            throw AIServiceError.parseError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            Logger.error.error("Error: Could not parse JSON data")
            throw AIServiceError.parseError
        }
        
        // recommendedChanges の解析 - フォールバック対応
        let changesArray = json["recommendedChanges"] as? [[String: Any]] ?? []
        
        let changes = changesArray.compactMap { changeDict -> PlanChange? in
            guard let dayOfWeek = changeDict["dayOfWeek"] as? Int,
                  let changeTypeString = changeDict["changeType"] as? String,
                  let taskTitle = changeDict["taskTitle"] as? String,
                  let reason = changeDict["reason"] as? String else {
                Logger.error.error("Warning: Invalid change data: \(changeDict)")
                return nil
            }
            
            let changeType: PlanChange.ChangeType
            switch changeTypeString {
            case "modify": changeType = .modify
            case "add": changeType = .add
            case "remove": changeType = .remove
            case "intensity": changeType = .intensity
            default: 
                Logger.error.error("Warning: Unknown change type: \(changeTypeString)")
                return nil
            }
            
            // TargetDetails を構築 - デフォルト値で初期化
            var newDetails = TargetDetails()
            
            if let newDetailsDict = changeDict["newDetails"] as? [String: Any] {
                newDetails.exercises = newDetailsDict["exercises"] as? [String]
                newDetails.targetSets = newDetailsDict["targetSets"] as? Int
                newDetails.targetReps = newDetailsDict["targetReps"] as? Int
                newDetails.targetPower = newDetailsDict["targetPower"] as? Int
                newDetails.duration = newDetailsDict["duration"] as? Int
                if let intensityString = newDetailsDict["intensity"] as? String {
                    newDetails.intensity = CyclingIntensity(rawValue: intensityString)
                }
                newDetails.targetDuration = newDetailsDict["targetDuration"] as? Int
                newDetails.targetForwardBend = newDetailsDict["targetForwardBend"] as? Double
                newDetails.targetSplitAngle = newDetailsDict["targetSplitAngle"] as? Double
            }
            
            return PlanChange(
                dayOfWeek: dayOfWeek,
                changeType: changeType,
                taskTitle: taskTitle,
                oldDetails: nil,
                newDetails: newDetails,
                reason: reason
            )
        }
        
        let reasoning = json["reasoning"] as? String ?? "AI分析が完了しました。現在のトレーニングプランを継続することをお勧めします。"
        let confidence = json["confidence"] as? Double ?? 0.5
        
        return WeeklyPlanSuggestion(
            recommendedChanges: changes,
            reasoning: reasoning,
            estimatedCost: 0.01,
            confidence: confidence
        )
    }
    
    private func estimateTokens(text: String) -> Int {
        // 簡易的なトークン数推定（実際にはtiktokenライブラリを使用する方が正確）
        return text.count / 4
    }
}

enum AIServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Claude API キーが設定されていません。設定画面でAPIキーを確認してください。"
        case .invalidURL:
            return "無効なURL"
        case .invalidResponse:
            return "無効なレスポンス"
        case .apiError(let code):
            switch code {
            case 401:
                return "API認証エラー: Claude APIキーが無効です。設定画面でAPIキーを確認してください。"
            case 429:
                return "APIレート制限: しばらく時間をおいてからお試しください。"
            case 500...599:
                return "Claude APIサーバーエラー: しばらく時間をおいてからお試しください。"
            default:
                return "API エラー: \(code)"
            }
        case .parseError:
            return "レスポンスの解析に失敗しました"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingAPIKey, .apiError(401):
            return "1. 設定画面を開く\n2. Claude APIキーを入力\n3. 接続テストを実行"
        case .apiError(429):
            return "数分待ってから再度お試しください"
        case .apiError(500...599):
            return "Claude APIのステータスページを確認してください"
        default:
            return nil
        }
    }
}
