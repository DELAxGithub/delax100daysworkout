import Foundation
import SwiftData

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
    
    init() {
        // 環境変数またはXcodeの設定からAPIキーを取得
        if let apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] {
            self.claudeAPIKey = apiKey
        } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let apiKey = plist["CLAUDE_API_KEY"] as? String {
            self.claudeAPIKey = apiKey
        } else {
            self.claudeAPIKey = ""
            print("⚠️ CLAUDE_API_KEY not found. AI features will not work.")
        }
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
        
        // レスポンスを解析
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
        // JSON部分を抽出
        guard let jsonStart = response.range(of: "{"),
              let jsonEnd = response.range(of: "}", options: .backwards) else {
            throw AIServiceError.parseError
        }
        
        let jsonString = String(response[jsonStart.lowerBound...jsonEnd.upperBound])
        
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AIServiceError.parseError
        }
        
        // recommendedChanges の解析
        guard let changesArray = json["recommendedChanges"] as? [[String: Any]] else {
            throw AIServiceError.parseError
        }
        
        let changes = try changesArray.map { changeDict -> PlanChange in
            guard let dayOfWeek = changeDict["dayOfWeek"] as? Int,
                  let changeTypeString = changeDict["changeType"] as? String,
                  let taskTitle = changeDict["taskTitle"] as? String,
                  let newDetailsDict = changeDict["newDetails"] as? [String: Any],
                  let reason = changeDict["reason"] as? String else {
                throw AIServiceError.parseError
            }
            
            let changeType: PlanChange.ChangeType
            switch changeTypeString {
            case "modify": changeType = .modify
            case "add": changeType = .add
            case "remove": changeType = .remove
            case "intensity": changeType = .intensity
            default: throw AIServiceError.parseError
            }
            
            // TargetDetails を構築
            let newDetails = TargetDetails(
                exercises: newDetailsDict["exercises"] as? [String],
                targetSets: newDetailsDict["targetSets"] as? Int,
                targetReps: newDetailsDict["targetReps"] as? Int,
                targetPower: newDetailsDict["targetPower"] as? Int,
                duration: newDetailsDict["duration"] as? Int,
                intensity: nil, // 必要に応じて解析を追加
                targetDuration: newDetailsDict["targetDuration"] as? Int,
                targetForwardBend: newDetailsDict["targetForwardBend"] as? Double,
                targetSplitAngle: newDetailsDict["targetSplitAngle"] as? Double
            )
            
            return PlanChange(
                dayOfWeek: dayOfWeek,
                changeType: changeType,
                taskTitle: taskTitle,
                oldDetails: nil, // 必要に応じて追加
                newDetails: newDetails,
                reason: reason
            )
        }
        
        let reasoning = json["reasoning"] as? String ?? "分析結果なし"
        let confidence = json["confidence"] as? Double ?? 0.5
        
        return WeeklyPlanSuggestion(
            recommendedChanges: changes,
            reasoning: reasoning,
            estimatedCost: 0.01, // 実際のコストを計算
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
            return "Claude API キーが設定されていません"
        case .invalidURL:
            return "無効なURL"
        case .invalidResponse:
            return "無効なレスポンス"
        case .apiError(let code):
            return "API エラー: \(code)"
        case .parseError:
            return "レスポンスの解析に失敗しました"
        }
    }
}