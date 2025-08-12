import Foundation
import SwiftData
import Combine

enum PlanUpdateStatus: Equatable {
    case idle
    case analyzing
    case completed
    case failed(Error)
    
    static func == (lhs: PlanUpdateStatus, rhs: PlanUpdateStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.analyzing, .analyzing), (.completed, .completed):
            return true
        case (.failed, .failed):
            return true // エラーの詳細比較は省略
        default:
            return false
        }
    }
}

// PlanUpdateHistoryはファイル末尾の@Modelクラスで定義されています

@MainActor
class WeeklyPlanManager: ObservableObject {
    private let modelContext: ModelContext
    private let progressAnalyzer: ProgressAnalyzer
    private let aiService: WeeklyPlanAIService
    
    @Published var updateStatus: PlanUpdateStatus = .idle
    @Published var lastUpdateDate: Date?
    @Published var lastUpdateHistory: PlanUpdateHistoryInfo?
    
    // 分析統計情報
    @Published var analysisCount: Int = 0
    @Published var lastAnalysisResult: String?
    @Published var lastAnalysisDataCount: Int = 0
    @Published var monthlyAnalysisCount: Int = 0
    
    // 設定
    @Published var autoUpdateEnabled: Bool = true
    @Published var maxCostPerUpdate: Double = 1.00 // $1.00 per update (実際は$0.01-0.02)
    @Published var updateFrequency: TimeInterval = 7 * 24 * 60 * 60 // 1週間
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.progressAnalyzer = ProgressAnalyzer(modelContext: modelContext)
        self.aiService = WeeklyPlanAIService()
        loadAnalysisStatistics()
    }
    
    // メイン機能：週次プラン更新の開始
    func initiateWeeklyPlanUpdate() async {
        guard canPerformUpdate() else {
            print("週次プラン更新の条件が満たされていません")
            return
        }
        
        updateStatus = .analyzing
        
        do {
            // 現在のデータを取得
            let (records, activeTemplate) = try await fetchCurrentData()
            
            // 分析対象データ件数を記録
            lastAnalysisDataCount = records.count
            
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
            
            // 即座にプランを適用
            let newTemplate = try await createUpdatedTemplate(
                baseTemplate: activeTemplate,
                changes: aiSuggestion.recommendedChanges
            )
            
            // 現在のテンプレートを無効化
            activeTemplate.deactivate()
            
            // 新しいテンプレートをアクティブ化
            newTemplate.activate()
            modelContext.insert(newTemplate)
            
            // 履歴を保存
            lastUpdateHistory = PlanUpdateHistoryInfo(
                oldTemplate: activeTemplate,
                newTemplate: newTemplate,
                aiSuggestion: aiSuggestion
            )
            
            try modelContext.save()
            
            updateStatus = .completed
            lastUpdateDate = Date()
            
            // 分析統計を更新
            updateAnalysisStatistics(aiSuggestion)
            
            print("週次プランが自動的に更新されました。")
            
        } catch {
            updateStatus = .failed(error)
            print("週次プラン更新でエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    // 最後の更新を元に戻す
    func revertLastUpdate() async {
        guard let history = lastUpdateHistory else {
            print("戻す履歴がありません")
            return
        }
        
        updateStatus = .analyzing
        
        do {
            // 現在のテンプレートを無効化
            history.newTemplate.deactivate()
            
            // 古いテンプレートを再アクティブ化
            history.oldTemplate.activate()
            
            try modelContext.save()
            
            updateStatus = .completed
            lastUpdateHistory = nil
            
            print("プランを元に戻しました")
            
        } catch {
            updateStatus = .failed(error)
            print("プランの復元でエラーが発生しました: \(error.localizedDescription)")
        }
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
        return updateStatus == .idle
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
    
    // saveUpdateHistoryは不要になりました（履歴はlastUpdateHistoryプロパティで管理）
    
    // MARK: - Statistics Management
    
    private func loadAnalysisStatistics() {
        // UserDefaultsから統計情報を読み込み
        let defaults = UserDefaults.standard
        analysisCount = defaults.integer(forKey: "analysisCount")
        lastAnalysisResult = defaults.string(forKey: "lastAnalysisResult")
        lastAnalysisDataCount = defaults.integer(forKey: "lastAnalysisDataCount")
        
        // 今月の分析回数を計算
        updateMonthlyCount()
    }
    
    private func updateAnalysisStatistics(_ suggestion: WeeklyPlanSuggestion) {
        analysisCount += 1
        monthlyAnalysisCount += 1
        lastAnalysisResult = generateAnalysisResultSummary(suggestion)
        lastUpdateDate = Date()
        
        // UserDefaultsに保存
        let defaults = UserDefaults.standard
        defaults.set(analysisCount, forKey: "analysisCount")
        defaults.set(lastAnalysisResult, forKey: "lastAnalysisResult")
        defaults.set(lastAnalysisDataCount, forKey: "lastAnalysisDataCount")
        defaults.set(monthlyAnalysisCount, forKey: "monthlyAnalysisCount")
        
        updateMonthlyCount()
    }
    
    private func updateMonthlyCount() {
        // 簡易的に月次カウントを管理（UserDefaultsベース）
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        let lastMonth = UserDefaults.standard.integer(forKey: "lastAnalysisMonth")
        let lastYear = UserDefaults.standard.integer(forKey: "lastAnalysisYear")
        
        if currentMonth != lastMonth || currentYear != lastYear {
            // 月が変わったらカウントリセット
            monthlyAnalysisCount = 0
            UserDefaults.standard.set(currentMonth, forKey: "lastAnalysisMonth")
            UserDefaults.standard.set(currentYear, forKey: "lastAnalysisYear")
        } else {
            monthlyAnalysisCount = UserDefaults.standard.integer(forKey: "monthlyAnalysisCount")
        }
    }
    
    private func generateAnalysisResultSummary(_ suggestion: WeeklyPlanSuggestion) -> String {
        let changeCount = suggestion.recommendedChanges.count
        
        if changeCount == 0 {
            return "現在のプランは最適です"
        } else {
            let changeTypes = suggestion.recommendedChanges.map { $0.changeType }
            let modifyCount = changeTypes.filter { $0 == .modify }.count
            let addCount = changeTypes.filter { $0 == .add }.count
            let removeCount = changeTypes.filter { $0 == .remove }.count
            
            var summary = "\(changeCount)つの改善提案"
            if modifyCount > 0 { summary += "・調整\(modifyCount)件" }
            if addCount > 0 { summary += "・追加\(addCount)件" }
            if removeCount > 0 { summary += "・削除\(removeCount)件" }
            
            return summary
        }
    }
    
    // 分析情報のフォーマット用ヘルパー
    var analysisDataDescription: String {
        if lastAnalysisDataCount == 0 {
            return "分析データなし"
        } else {
            return "過去4週間のワークアウト \(lastAnalysisDataCount)件を分析"
        }
    }
    
    var analysisResultDescription: String {
        return lastAnalysisResult ?? "未分析"
    }
    
    var monthlyUsageDescription: String {
        return "今月 \(monthlyAnalysisCount)回分析実行"
    }
    
    // 最後の更新内容を取得
    var lastUpdateSuggestion: WeeklyPlanSuggestion? {
        return lastUpdateHistory?.aiSuggestion
    }
    
    // 元に戻すことが可能かどうか
    var canRevert: Bool {
        return lastUpdateHistory != nil && updateStatus == .completed
    }
    
    deinit {
        // Cleanup if needed
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

// 更新履歴を表す簡単な構造体
struct PlanUpdateHistoryInfo {
    let id: UUID
    let oldTemplate: WeeklyTemplate
    let newTemplate: WeeklyTemplate
    let aiSuggestion: WeeklyPlanSuggestion
    let appliedAt: Date
    
    init(oldTemplate: WeeklyTemplate, newTemplate: WeeklyTemplate, aiSuggestion: WeeklyPlanSuggestion) {
        self.id = UUID()
        self.oldTemplate = oldTemplate
        self.newTemplate = newTemplate
        self.aiSuggestion = aiSuggestion
        self.appliedAt = Date()
    }
}