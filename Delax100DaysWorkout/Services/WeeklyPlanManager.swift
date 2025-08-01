import Foundation
import SwiftData

enum PlanUpdateStatus {
    case idle
    case analyzing
    case awaitingApproval
    case applying
    case completed
    case failed(Error)
}

struct PlanUpdateSession {
    let id: UUID
    let currentTemplate: WeeklyTemplate
    let aiSuggestion: WeeklyPlanSuggestion
    let estimatedCost: Double
    let createdAt: Date
    var status: PlanUpdateStatus
    
    init(currentTemplate: WeeklyTemplate, aiSuggestion: WeeklyPlanSuggestion, estimatedCost: Double) {
        self.id = UUID()
        self.currentTemplate = currentTemplate
        self.aiSuggestion = aiSuggestion
        self.estimatedCost = estimatedCost
        self.createdAt = Date()
        self.status = .awaitingApproval
    }
}

@Observable
class WeeklyPlanManager {
    private let modelContext: ModelContext
    private let progressAnalyzer: ProgressAnalyzer
    private let aiService: WeeklyPlanAIService
    
    var currentSession: PlanUpdateSession?
    var updateStatus: PlanUpdateStatus = .idle
    var lastUpdateDate: Date?
    
    // 設定
    var autoUpdateEnabled: Bool = true
    var maxCostPerUpdate: Double = 0.10 // $0.10 per update
    var updateFrequency: TimeInterval = 7 * 24 * 60 * 60 // 1週間
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.progressAnalyzer = ProgressAnalyzer(modelContext: modelContext)
        self.aiService = WeeklyPlanAIService()
    }
    
    // メイン機能：週次プラン更新の開始
    @MainActor
    func initiateWeeklyPlanUpdate() async {
        guard canPerformUpdate() else {
            print("週次プラン更新の条件が満たされていません")
            return
        }
        
        updateStatus = .analyzing
        
        do {
            // 現在のデータを取得
            let (records, activeTemplate) = try await fetchCurrentData()
            
            // AI分析リクエストを作成
            let analysisRequest = progressAnalyzer.generateAIAnalysisData(
                records: records,
                template: activeTemplate
            )
            
            // コスト見積もり
            let estimatedCost = aiService.estimateCost(request: analysisRequest)
            
            guard estimatedCost <= maxCostPerUpdate else {
                updateStatus = .failed(WeeklyPlanError.costExceeded(estimatedCost))
                return
            }
            
            print("週次プラン分析を開始します（予想コスト: $\(String(format: "%.4f", estimatedCost))）")
            
            // AI分析を実行
            let aiSuggestion = try await aiService.analyzeAndSuggestWeeklyPlan(request: analysisRequest)
            
            // セッションを作成
            currentSession = PlanUpdateSession(
                currentTemplate: activeTemplate,
                aiSuggestion: aiSuggestion,
                estimatedCost: estimatedCost
            )
            
            updateStatus = .awaitingApproval
            
            print("週次プラン提案が完了しました。ユーザーの承認待ちです。")
            
        } catch {
            updateStatus = .failed(error)
            print("週次プラン更新でエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    // ユーザーがAI提案を承認
    @MainActor
    func approveAISuggestion() async {
        guard let session = currentSession,
              case .awaitingApproval = session.status else {
            print("承認可能なセッションがありません")
            return
        }
        
        updateStatus = .applying
        
        do {
            // 新しいテンプレートを作成
            let newTemplate = try await createUpdatedTemplate(
                baseTemplate: session.currentTemplate,
                changes: session.aiSuggestion.recommendedChanges
            )
            
            // 現在のテンプレートを無効化
            session.currentTemplate.deactivate()
            
            // 新しいテンプレートをアクティブ化
            newTemplate.activate()
            modelContext.insert(newTemplate)
            
            // 更新履歴を保存
            try await saveUpdateHistory(session: session, appliedTemplate: newTemplate)
            
            try modelContext.save()
            
            updateStatus = .completed
            lastUpdateDate = Date()
            currentSession = nil
            
            print("週次プランが正常に更新されました")
            
        } catch {
            updateStatus = .failed(error)
            print("プラン適用でエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    // AI提案を拒否
    func rejectAISuggestion() {
        guard let session = currentSession,
              case .awaitingApproval = session.status else {
            return
        }
        
        currentSession = nil
        updateStatus = .idle
        
        print("AI提案が拒否されました")
    }
    
    // 手動更新をトリガー
    func requestManualUpdate() async {
        guard updateStatus == .idle else {
            print("既に更新処理が進行中です")
            return
        }
        
        await initiateWeeklyPlanUpdate()
    }
    
    // 自動更新の条件チェック
    func shouldPerformAutoUpdate() -> Bool {
        guard autoUpdateEnabled else { return false }
        
        guard let lastUpdate = lastUpdateDate else {
            return true // 初回更新
        }
        
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        return timeSinceLastUpdate >= updateFrequency
    }
    
    // MARK: - Private Methods
    
    private func canPerformUpdate() -> Bool {
        return updateStatus == .idle && currentSession == nil
    }
    
    private func fetchCurrentData() async throws -> ([WorkoutRecord], WeeklyTemplate) {
        // WorkoutRecordを取得（過去4週間）
        let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()
        
        let recordDescriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { record in
                record.date >= fourWeeksAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let records = try modelContext.fetch(recordDescriptor)
        
        // アクティブなテンプレートを取得
        let templateDescriptor = FetchDescriptor<WeeklyTemplate>(
            predicate: #Predicate { template in
                template.isActive == true
            }
        )
        
        let activeTemplates = try modelContext.fetch(templateDescriptor)
        
        guard let activeTemplate = activeTemplates.first else {
            throw WeeklyPlanError.noActiveTemplate
        }
        
        return (records, activeTemplate)
    }
    
    private func createUpdatedTemplate(
        baseTemplate: WeeklyTemplate,
        changes: [PlanChange]
    ) async throws -> WeeklyTemplate {
        
        let newTemplate = WeeklyTemplate(
            name: "AI最適化プラン - \(DateFormatter().string(from: Date()))",
            isActive: false
        )
        
        // 既存のタスクをコピー
        for day in 0...6 {
            let baseTasks = baseTemplate.tasksForDay(day)
            
            for baseTask in baseTasks {
                // この日のタスクに変更があるかチェック
                let relevantChanges = changes.filter { $0.dayOfWeek == day && $0.taskTitle == baseTask.title }
                
                if let change = relevantChanges.first {
                    // 変更を適用
                    let updatedTask = applyChange(to: baseTask, change: change)
                    newTemplate.addTask(updatedTask)
                } else {
                    // 変更なし、そのままコピー
                    let copiedTask = DailyTask(
                        dayOfWeek: baseTask.dayOfWeek,
                        workoutType: baseTask.workoutType,
                        title: baseTask.title,
                        description: baseTask.taskDescription,
                        targetDetails: baseTask.targetDetails,
                        isFlexible: baseTask.isFlexible,
                        sortOrder: baseTask.sortOrder
                    )
                    newTemplate.addTask(copiedTask)
                }
            }
            
            // 新しいタスクの追加
            let newTasks = changes.filter { $0.dayOfWeek == day && $0.changeType == .add }
            for change in newTasks {
                let newTask = DailyTask(
                    dayOfWeek: change.dayOfWeek,
                    workoutType: inferWorkoutType(from: change.taskTitle),
                    title: change.taskTitle,
                    description: change.reason,
                    targetDetails: change.newDetails,
                    isFlexible: true
                )
                newTemplate.addTask(newTask)
            }
        }
        
        return newTemplate
    }
    
    private func applyChange(to task: DailyTask, change: PlanChange) -> DailyTask {
        let updatedTask = DailyTask(
            dayOfWeek: task.dayOfWeek,
            workoutType: task.workoutType,
            title: task.title,
            description: change.reason,
            targetDetails: change.newDetails,
            isFlexible: task.isFlexible,
            sortOrder: task.sortOrder
        )
        
        return updatedTask
    }
    
    private func inferWorkoutType(from title: String) -> WorkoutType {
        let lowerTitle = title.lowercased()
        
        if lowerTitle.contains("筋トレ") || lowerTitle.contains("筋力") || lowerTitle.contains("strength") {
            return .strength
        } else if lowerTitle.contains("サイクリング") || lowerTitle.contains("バイク") || lowerTitle.contains("ライド") {
            return .cycling
        } else {
            return .flexibility
        }
    }
    
    private func saveUpdateHistory(session: PlanUpdateSession, appliedTemplate: WeeklyTemplate) async throws {
        // 更新履歴を保存（必要に応じてPlanUpdateHistoryモデルを作成）
        let history = PlanUpdateHistory(
            sessionId: session.id,
            oldTemplateName: session.currentTemplate.name,
            newTemplateName: appliedTemplate.name,
            aiReasoning: session.aiSuggestion.reasoning,
            appliedChanges: session.aiSuggestion.recommendedChanges.count,
            actualCost: session.estimatedCost,
            appliedAt: Date()
        )
        
        modelContext.insert(history)
    }
}

// エラー定義
enum WeeklyPlanError: Error, LocalizedError {
    case noActiveTemplate
    case costExceeded(Double)
    case analysisTimeout
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noActiveTemplate:
            return "アクティブなテンプレートが見つかりません"
        case .costExceeded(let cost):
            return "コスト上限を超過しました ($\(String(format: "%.4f", cost)))"
        case .analysisTimeout:
            return "分析がタイムアウトしました"
        case .invalidResponse:
            return "AIからの無効なレスポンスです"
        }
    }
}

// 更新履歴モデル
@Model
final class PlanUpdateHistory {
    var sessionId: UUID
    var oldTemplateName: String
    var newTemplateName: String
    var aiReasoning: String
    var appliedChanges: Int
    var actualCost: Double
    var appliedAt: Date
    
    init(sessionId: UUID, oldTemplateName: String, newTemplateName: String, 
         aiReasoning: String, appliedChanges: Int, actualCost: Double, appliedAt: Date) {
        self.sessionId = sessionId
        self.oldTemplateName = oldTemplateName
        self.newTemplateName = newTemplateName
        self.aiReasoning = aiReasoning
        self.appliedChanges = appliedChanges
        self.actualCost = actualCost
        self.appliedAt = appliedAt
    }
}