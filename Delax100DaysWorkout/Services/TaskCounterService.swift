import Foundation
import SwiftData

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
            print("Error fetching counter: \(error)")
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
            print("Counter updated for \(taskType): \(counter.completionCount)")
        } catch {
            print("Error saving counter update: \(error)")
        }
    }
    
    /// WorkoutRecordの完了時にカウンターを更新
    func incrementCounter(for record: WorkoutRecord, in modelContext: ModelContext) {
        let taskType = TaskIdentificationUtils.generateTaskType(from: record)
        let counter = getOrCreateCounter(for: taskType, in: modelContext)
        
        counter.incrementCount()
        
        do {
            try modelContext.save()
            print("Counter updated for \(taskType): \(counter.completionCount)")
        } catch {
            print("Error saving counter update: \(error)")
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
            print("Error fetching counter info: \(error)")
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
            print("Target updated for \(taskType): \(counter.currentTarget)")
        } catch {
            print("Error saving target update: \(error)")
        }
    }
    
    /// 目標回数をカスタム設定
    func setCustomTarget(for taskType: String, targetCount: Int, in modelContext: ModelContext) {
        let counter = getOrCreateCounter(for: taskType, in: modelContext)
        counter.currentTarget = targetCount
        counter.isTargetAchieved = counter.completionCount >= targetCount
        
        do {
            try modelContext.save()
            print("Custom target set for \(taskType): \(counter.currentTarget)")
        } catch {
            print("Error saving custom target: \(error)")
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
                
                print("Migrated \(taskType): \(count) completions")
            }
            
            try modelContext.save()
            print("History migration completed successfully")
            
        } catch {
            print("Error during history migration: \(error)")
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
            print("Error fetching counter stats: \(error)")
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
            print("Error fetching achieved counters: \(error)")
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
            print("Error fetching active counters: \(error)")
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
                print("Counter reset for \(taskType)")
            } catch {
                print("Error resetting counter: \(error)")
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
            print("All counters reset successfully")
        } catch {
            print("Error resetting all counters: \(error)")
        }
    }
}