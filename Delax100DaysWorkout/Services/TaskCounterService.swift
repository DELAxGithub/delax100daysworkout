import Foundation
import SwiftData
import OSLog

/// タスク完了回数カウンター管理サービス
@MainActor
class TaskCounterService: ObservableObject {
    
    static let shared = TaskCounterService()
    
    private init() {}
    
    // MARK: - Counter Management
    
    /// 種目のカウンターを取得（なければ作成）
    func getOrCreateCounter(for taskType: String, in modelContext: ModelContext) -> TaskCompletionCounter {
        let descriptor = FetchDescriptor<TaskCompletionCounter>(
            predicate: #Predicate { counter in
                counter.taskType == taskType
            }
        )
        
        do {
            let existingCounters = try modelContext.fetch(descriptor)
            if let existingCounter = existingCounters.first {
                return existingCounter
            }
        } catch {
            Logger.database.error("Error fetching counter: \(error.localizedDescription)")
        }
        
        // 新規作成
        let newCounter = TaskCompletionCounter(taskType: taskType)
        modelContext.insert(newCounter)
        
        return newCounter
    }
    
    /// DailyTaskの完了時にカウンターを更新
    func incrementCounter(for task: DailyTask, in modelContext: ModelContext) {
        let taskType = TaskIdentificationUtils.generateTaskType(from: task)
        let counter = getOrCreateCounter(for: taskType, in: modelContext)
        
        counter.incrementCount()
        
        do {
            try modelContext.save()
            Logger.database.info("Counter updated for \(taskType): \(counter.completionCount)")
        } catch {
            Logger.database.error("Error saving counter update: \(error.localizedDescription)")
        }
    }
    
    /// WorkoutRecordの完了時にカウンターを更新
    func incrementCounter(for record: WorkoutRecord, in modelContext: ModelContext) {
        let taskType = TaskIdentificationUtils.generateTaskType(from: record)
        let counter = getOrCreateCounter(for: taskType, in: modelContext)
        
        counter.incrementCount()
        
        do {
            try modelContext.save()
            Logger.database.info("Counter updated for \(taskType): \(counter.completionCount)")
        } catch {
            Logger.database.error("Error saving counter update: \(error.localizedDescription)")
        }
    }
    
    /// 種目の現在のカウンター情報を取得
    func getCounterInfo(for taskType: String, in modelContext: ModelContext) -> TaskCompletionCounter? {
        let descriptor = FetchDescriptor<TaskCompletionCounter>(
            predicate: #Predicate { counter in
                counter.taskType == taskType
            }
        )
        
        do {
            let counters = try modelContext.fetch(descriptor)
            return counters.first
        } catch {
            Logger.database.error("Error fetching counter info: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// DailyTaskのカウンター情報を取得
    func getCounterInfo(for task: DailyTask, in modelContext: ModelContext) -> TaskCompletionCounter? {
        let taskType = TaskIdentificationUtils.generateTaskType(from: task)
        return getCounterInfo(for: taskType, in: modelContext)
    }
    
    // MARK: - Target Management
    
    /// 目標回数を追加（「おかわり」機能）
    func addTarget(for taskType: String, additionalCount: Int = 50, in modelContext: ModelContext) {
        let counter = getOrCreateCounter(for: taskType, in: modelContext)
        counter.addTarget(additionalCount: additionalCount)
        
        do {
            try modelContext.save()
            Logger.database.info("Target updated for \(taskType): \(counter.currentTarget)")
        } catch {
            Logger.database.error("Error saving target update: \(error.localizedDescription)")
        }
    }
    
    /// 目標回数をカスタム設定
    func setCustomTarget(for taskType: String, targetCount: Int, in modelContext: ModelContext) {
        let counter = getOrCreateCounter(for: taskType, in: modelContext)
        counter.currentTarget = targetCount
        counter.isTargetAchieved = counter.completionCount >= targetCount
        
        do {
            try modelContext.save()
            Logger.database.info("Custom target set for \(taskType): \(counter.currentTarget)")
        } catch {
            Logger.database.error("Error saving custom target: \(error.localizedDescription)")
        }
    }
    
    // MARK: - History Migration
    
    /// 既存のWorkoutRecordから回数を自動集計・移行
    func migrateFromHistory(startDate: Date = Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 1)) ?? Date(), in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { record in
                record.date >= startDate && record.isCompleted
            },
            sortBy: [SortDescriptor(\WorkoutRecord.date, order: .forward)]
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            
            var taskTypeCounts: [String: Int] = [:]
            
            // 各WorkoutRecordから種目識別子を生成してカウント
            for record in records {
                let taskType = TaskIdentificationUtils.generateTaskType(from: record)
                taskTypeCounts[taskType, default: 0] += 1
            }
            
            // カウンターを更新
            for (taskType, count) in taskTypeCounts {
                let counter = getOrCreateCounter(for: taskType, in: modelContext)
                counter.completionCount = count
                counter.startDate = startDate
                counter.lastCompletedDate = records.last?.date
                
                // 目標達成チェック
                if counter.completionCount >= counter.currentTarget {
                    counter.isTargetAchieved = true
                }
                
                Logger.database.info("Migrated \(taskType): \(count) completions")
            }
            
            try modelContext.save()
            Logger.database.info("History migration completed successfully")
            
        } catch {
            Logger.database.error("Error during history migration: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Analytics
    
    /// 全カウンターの統計を取得
    func getAllCounterStats(in modelContext: ModelContext) -> [(taskType: String, counter: TaskCompletionCounter)] {
        let descriptor = FetchDescriptor<TaskCompletionCounter>(
            sortBy: [SortDescriptor(\TaskCompletionCounter.completionCount, order: .reverse)]
        )
        
        do {
            let counters = try modelContext.fetch(descriptor)
            return counters.map { (taskType: $0.taskType, counter: $0) }
        } catch {
            Logger.database.error("Error fetching counter stats: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 目標達成済みのカウンター一覧を取得
    func getAchievedCounters(in modelContext: ModelContext) -> [TaskCompletionCounter] {
        let descriptor = FetchDescriptor<TaskCompletionCounter>(
            predicate: #Predicate { counter in
                counter.isTargetAchieved
            },
            sortBy: [SortDescriptor(\TaskCompletionCounter.completionCount, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.database.error("Error fetching achieved counters: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 進行中のカウンター一覧を取得
    func getActiveCounters(in modelContext: ModelContext) -> [TaskCompletionCounter] {
        let descriptor = FetchDescriptor<TaskCompletionCounter>(
            predicate: #Predicate { counter in
                !counter.isTargetAchieved && counter.completionCount > 0
            },
            sortBy: [SortDescriptor(\TaskCompletionCounter.completionCount, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.database.error("Error fetching active counters: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Reset Functions
    
    /// 特定の種目のカウンターをリセット
    func resetCounter(for taskType: String, in modelContext: ModelContext) {
        if let counter = getCounterInfo(for: taskType, in: modelContext) {
            counter.completionCount = 0
            counter.isTargetAchieved = false
            counter.startDate = Date()
            counter.lastCompletedDate = nil
            counter.currentTarget = 50 // デフォルトに戻す
            
            do {
                try modelContext.save()
                Logger.database.info("Counter reset for \(taskType)")
            } catch {
                Logger.database.error("Error resetting counter: \(error.localizedDescription)")
            }
        }
    }
    
    /// 全カウンターをリセット
    func resetAllCounters(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TaskCompletionCounter>()
        
        do {
            let counters = try modelContext.fetch(descriptor)
            for counter in counters {
                counter.completionCount = 0
                counter.isTargetAchieved = false
                counter.startDate = Date()
                counter.lastCompletedDate = nil
                counter.currentTarget = 50
            }
            
            try modelContext.save()
            Logger.database.info("All counters reset successfully")
        } catch {
            Logger.database.error("Error resetting all counters: \(error.localizedDescription)")
        }
    }
}