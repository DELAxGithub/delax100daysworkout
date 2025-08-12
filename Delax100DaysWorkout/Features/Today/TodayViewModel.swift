import Foundation
import SwiftData
import SwiftUI

@Observable
class TodayViewModel {
    var todaysTasks: [DailyTask] = []
    var completedTasks: Set<PersistentIdentifier> = []
    var greeting: String = ""
    var progressPercentage: Double = 0.0
    var activeTemplate: WeeklyTemplate?
    
    private var modelContext: ModelContext
    private var taskSuggestionManager: TaskSuggestionManager
    private var progressAnalyzer: ProgressAnalyzer
    private let cacheManager = DataCacheManager.shared
    private let refreshManager = SmartRefreshManager.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.taskSuggestionManager = TaskSuggestionManager(modelContext: modelContext)
        self.progressAnalyzer = ProgressAnalyzer(modelContext: modelContext)
        loadTodaysTasks()
        updateGreeting()
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        let dayOfWeek = Calendar.current.component(.weekday, from: Date()) - 1 // 0=日曜
        let days = ["日", "月", "火", "水", "木", "金", "土"]
        let dayName = days[dayOfWeek]
        
        if hour < 12 {
            greeting = "おはようございます！\(dayName)曜日のトレーニング"
        } else if hour < 18 {
            greeting = "こんにちは！\(dayName)曜日のトレーニング"
        } else {
            greeting = "こんばんは！\(dayName)曜日のトレーニング"
        }
    }
    
    func loadTodaysTasks(forceRefresh: Bool = false) {
        Task { @MainActor in
            await loadTodaysTasksOptimized(forceRefresh: forceRefresh)
        }
    }
    
    @MainActor
    private func loadTodaysTasksOptimized(forceRefresh: Bool = false) async {
        let shouldRefresh = forceRefresh || refreshManager.shouldRefresh(
            for: "today_tasks",
            minInterval: .default
        )
        
        guard shouldRefresh else { return }
        
        refreshManager.beginRefresh(for: "today_tasks")
        defer { refreshManager.endRefresh(for: "today_tasks") }
        
        let (_, _, history, template) = await cacheManager.batchFetchDashboardData(from: modelContext)
        
        if let template = template {
            activeTemplate = template
            
            // TaskSuggestionManagerを使用してタスクを取得
            todaysTasks = taskSuggestionManager.getTodaysTasks(
                template: template,
                history: history
            )
        } else {
            // デフォルトテンプレートを作成
            createDefaultTemplate()
        }
        
        // バッチで完了済みタスクを確認
        await checkCompletedTasksOptimized()
        updateProgress()
    }
    
    private func createDefaultTemplate() {
        let defaultTemplate = WeeklyTemplate.createDefaultTemplate()
        defaultTemplate.activate()
        modelContext.insert(defaultTemplate)
        
        do {
            try modelContext.save()
            activeTemplate = defaultTemplate
            loadTodaysTasks()
        } catch {
            print("Error creating default template: \(error)")
        }
    }
    
    @MainActor
    private func checkCompletedTasksOptimized() async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let recordDescriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { record in
                record.date >= today && record.date < tomorrow && record.isCompleted
            }
        )
        
        do {
            let todaysRecords = try modelContext.fetch(recordDescriptor)
            completedTasks = Set(todaysRecords.compactMap { $0.templateTask?.id })
        } catch {
            print("Error checking completed tasks: \(error)")
        }
    }
    
    private func updateProgress() {
        guard !todaysTasks.isEmpty else {
            progressPercentage = 0
            return
        }
        
        let completedCount = todaysTasks.filter { completedTasks.contains($0.id) }.count
        progressPercentage = Double(completedCount) / Double(todaysTasks.count)
    }
    
    func quickCompleteTask(_ task: DailyTask) -> WorkoutRecord? {
        // WorkoutRecordを作成
        let record = WorkoutRecord.fromDailyTask(task)
        record.markAsCompleted()
        modelContext.insert(record)
        
        // 基本的な詳細データを設定
        switch task.workoutType {
        case .cycling:
            if let targetDetails = task.targetDetails {
                let detail = CyclingDetail(
                    distance: 0, // クイック記録では0
                    duration: targetDetails.duration ?? 0,
                    averagePower: Double(targetDetails.targetPower ?? 0),
                    intensity: targetDetails.intensity ?? .endurance
                )
                record.cyclingDetail = detail
                modelContext.insert(detail)
            }
        case .strength:
            // クイック記録では詳細なしで完了扱い
            record.strengthDetails = []
        case .flexibility:
            if let targetDetails = task.targetDetails {
                let detail = FlexibilityDetail(
                    forwardBendDistance: 0,
                    leftSplitAngle: 90,
                    rightSplitAngle: 90,
                    duration: targetDetails.targetDuration ?? 20
                )
                record.flexibilityDetail = detail
                modelContext.insert(detail)
            }
        }
        
        // 保存
        do {
            try modelContext.save()
            completedTasks.insert(task.id)
            updateProgress()
            
            // PR/実績チェック
            checkForAchievements(record)
            return record
        } catch {
            print("Error saving quick completion: \(error)")
            return nil
        }
    }
    
    private func checkForAchievements(_ record: WorkoutRecord) {
        // 履歴を取得
        let recordDescriptor = FetchDescriptor<WorkoutRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allRecords = try modelContext.fetch(recordDescriptor)
            
            // PR検出
            if let prAchievement = progressAnalyzer.detectPR(newRecord: record, history: allRecords) {
                modelContext.insert(prAchievement)
            }
            
            // 連続記録チェック
            if let streakAchievement = Achievement.checkForStreak(records: allRecords, targetDays: 7) {
                modelContext.insert(streakAchievement)
            }
            
            // 進捗分析
            let progress = progressAnalyzer.analyzeProgress(records: allRecords)
            if progress.currentStreak == 3 || progress.currentStreak == 5 {
                let message = progressAnalyzer.generateMotivationalMessage(progress: progress)
                print("Motivational: \(message)") // TODO: 実際の通知実装
            }
            
            try modelContext.save()
        } catch {
            print("Error checking achievements: \(error)")
        }
    }
    
    func refreshTasks() {
        loadTodaysTasks()
        updateGreeting()
    }
    
    func deleteCompletedTask(_ task: DailyTask) {
        // 今日の該当するWorkoutRecordを検索
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let taskId = task.id
        let recordDescriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { record in
                record.date >= today && 
                record.date < tomorrow && 
                record.templateTask?.id == taskId
            }
        )
        
        do {
            let records = try modelContext.fetch(recordDescriptor)
            
            // 関連する詳細データも削除
            for record in records {
                // CyclingDetailの削除
                if let cyclingDetail = record.cyclingDetail {
                    modelContext.delete(cyclingDetail)
                }
                
                // StrengthDetailsの削除
                if let strengthDetails = record.strengthDetails {
                    strengthDetails.forEach { modelContext.delete($0) }
                }
                
                // FlexibilityDetailの削除
                if let flexibilityDetail = record.flexibilityDetail {
                    modelContext.delete(flexibilityDetail)
                }
                
                // WorkoutRecord自体を削除
                modelContext.delete(record)
            }
            
            try modelContext.save()
            
            // UIを更新
            completedTasks.remove(task.id)
            updateProgress()
            
        } catch {
            print("Error deleting task: \(error)")
        }
    }
}