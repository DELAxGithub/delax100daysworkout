import Foundation
import SwiftData
import SwiftUI
import OSLog

@MainActor
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
    
    func loadTodaysTasks() {
        // アクティブなテンプレートを取得
        let templateDescriptor = FetchDescriptor<WeeklyTemplate>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            let templates = try modelContext.fetch(templateDescriptor)
            
            if let template = templates.first {
                activeTemplate = template
                
                // 履歴を取得してタスクを調整
                let historyDescriptor = FetchDescriptor<WorkoutRecord>(
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                let history = (try? modelContext.fetch(historyDescriptor)) ?? []
                
                // TaskSuggestionManagerを使用してタスクを取得
                todaysTasks = taskSuggestionManager.getTodaysTasks(
                    template: template,
                    history: history
                )
            } else {
                // デフォルトテンプレートを作成
                createDefaultTemplate()
            }
            
            // 今日の完了済みタスクを確認
            checkCompletedTasks()
            updateProgress()
        } catch {
            Logger.error.error("Error loading tasks: \(error.localizedDescription)")
        }
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
            Logger.error.error("Error creating default template: \(error.localizedDescription)")
        }
    }
    
    private func checkCompletedTasks() {
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
            Logger.error.error("Error checking completed tasks: \(error.localizedDescription)")
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
        
        // 基本的な詳細データを設定（simplified）
        switch task.workoutType {
        case .cycling:
            if let targetDetails = task.targetDetails {
                record.cyclingData = SimpleCyclingData(
                    zone: .z2,
                    duration: targetDetails.duration ?? 0,
                    power: targetDetails.targetPower
                )
            }
        case .strength:
            // Quick record - basic data only
            record.strengthData = SimpleStrengthData(
                muscleGroup: .chest,
                customName: nil,
                weight: 0,
                reps: 10,
                sets: 3
            )
        case .flexibility, .pilates, .yoga:
            if let targetDetails = task.targetDetails {
                record.flexibilityData = SimpleFlexibilityData(
                    type: .general,
                    duration: targetDetails.targetDuration ?? 20,
                    measurement: nil
                )
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
            Logger.error.error("Error saving quick completion: \(error.localizedDescription)")
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
            
            // 連続記録チェックは簡単化のため無効化
            
            // 進捗分析
            let progress = progressAnalyzer.analyzeProgress(records: allRecords)
            if progress.currentStreak == 3 || progress.currentStreak == 5 {
                let message = progressAnalyzer.generateMotivationalMessage(progress: progress)
                Logger.general.info("Motivational: \(message)") // TODO: 実際の通知実装
            }
            
            try modelContext.save()
        } catch {
            Logger.error.error("Error checking achievements: \(error.localizedDescription)")
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
            
            // WorkoutRecords削除（詳細データはJSONで保存されているため削除不要）
            for record in records {
                modelContext.delete(record)
            }
            
            try modelContext.save()
            
            // UIを更新
            completedTasks.remove(task.id)
            updateProgress()
            
        } catch {
            Logger.error.error("Error deleting task: \(error.localizedDescription)")
        }
    }
}