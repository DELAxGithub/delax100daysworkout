import Foundation
import SwiftData
import SwiftUI
import OSLog

@Observable
class WeeklyScheduleViewModel {
    var completedTasks: Set<PersistentIdentifier> = []
    var showingQuickRecord = false
    var quickRecordTask: DailyTask?
    var quickRecordWorkout: WorkoutRecord?
    
    // MARK: - Apple Reminders-style State Management
    var editingTasks: Set<PersistentIdentifier> = []
    var showingMoveTask: DailyTask?
    var showingDeleteConfirmation: DailyTask?
    
    private var modelContext: ModelContext
    private var taskSuggestionManager: TaskSuggestionManager
    private var progressAnalyzer: ProgressAnalyzer
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.taskSuggestionManager = TaskSuggestionManager(modelContext: modelContext)
        self.progressAnalyzer = ProgressAnalyzer(modelContext: modelContext)
        checkCompletedTasks()
    }
    
    private func checkCompletedTasks() {
        // シンプルなクエリ（Predicateなし）
        var recordDescriptor = FetchDescriptor<WorkoutRecord>()
        recordDescriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        
        do {
            let allRecords = try modelContext.fetch(recordDescriptor)
            
            // 今日の完了済み記録をアプリレベルでフィルタリング
            let today = Date()
            let todaysCompletedRecords = allRecords.filter { record in
                Calendar.current.isDate(record.date, inSameDayAs: today) && record.isCompleted
            }
            
            completedTasks = Set(todaysCompletedRecords.compactMap { $0.templateTask?.id })
        } catch {
            Logger.error.error("Error checking completed tasks: \(error.localizedDescription)")
        }
    }
    
    func quickCompleteTask(_ task: DailyTask) -> WorkoutRecord? {
        let record = WorkoutRecord.fromDailyTask(task)
        record.markAsCompleted()
        modelContext.insert(record)
        
        switch task.workoutType {
        case .cycling:
            if let targetDetails = task.targetDetails {
                let detail = CyclingDetail(
                    distance: 0,
                    duration: targetDetails.duration ?? 0,
                    averagePower: Double(targetDetails.targetPower ?? 0),
                    intensity: targetDetails.intensity ?? .endurance
                )
                record.cyclingDetail = detail
                modelContext.insert(detail)
            }
        case .strength:
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
        case .pilates:
            // ピラティス詳細は後で実装
            break
        case .yoga:
            // ヨガ詳細は後で実装
            break
        }
        
        do {
            try modelContext.save()
            completedTasks.insert(task.id)
            checkForAchievements(record)
            return record
        } catch {
            Logger.error.error("Error saving quick completion: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func checkForAchievements(_ record: WorkoutRecord) {
        let recordDescriptor = FetchDescriptor<WorkoutRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allRecords = try modelContext.fetch(recordDescriptor)
            
            if let prAchievement = progressAnalyzer.detectPR(newRecord: record, history: allRecords) {
                modelContext.insert(prAchievement)
            }
            
            if let streakAchievement = Achievement.checkForStreak(records: allRecords, targetDays: 7) {
                modelContext.insert(streakAchievement)
            }
            
            let progress = progressAnalyzer.analyzeProgress(records: allRecords)
            if progress.currentStreak == 3 || progress.currentStreak == 5 {
                let message = progressAnalyzer.generateMotivationalMessage(progress: progress)
                Logger.general.info("Motivational: \(message)")
            }
            
            try modelContext.save()
        } catch {
            Logger.error.error("Error checking achievements: \(error.localizedDescription)")
        }
    }
    
    func isTaskCompleted(_ task: DailyTask) -> Bool {
        return completedTasks.contains(task.id)
    }
    
    func markTaskAsIncomplete(_ task: DailyTask) {
        // シンプルなクエリ（Predicateなし）
        var recordDescriptor = FetchDescriptor<WorkoutRecord>()
        recordDescriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        
        do {
            let allRecords = try modelContext.fetch(recordDescriptor)
            
            // 今日の該当タスクの完了記録をアプリレベルでフィルタリング
            let today = Date()
            let todaysTaskRecords = allRecords.filter { record in
                Calendar.current.isDate(record.date, inSameDayAs: today) &&
                record.isCompleted &&
                record.templateTask?.id == task.id
            }
            
            // 該当記録を未完了に戻す（最新の記録のみ）
            if let latestRecord = todaysTaskRecords.first {
                latestRecord.isCompleted = false
                completedTasks.remove(task.id)
                
                try modelContext.save()
                Logger.general.info("Task marked as incomplete: \(task.title)")
            }
        } catch {
            Logger.error.error("Error marking task as incomplete: \(error.localizedDescription)")
        }
    }
    
    func isToday(_ day: Int) -> Bool {
        return Calendar.current.component(.weekday, from: Date()) - 1 == day
    }
    
    func refreshCompletedTasks() {
        checkCompletedTasks()
    }
    
    func addCustomTask(_ task: DailyTask, to template: WeeklyTemplate) {
        // ソート順序を設定（同じ曜日の最大値＋1）
        let existingTasks = template.tasksForDay(task.dayOfWeek)
        task.sortOrder = (existingTasks.map { $0.sortOrder }.max() ?? -1) + 1
        
        // テンプレートにタスクを追加
        template.addTask(task)
        
        // データベースに保存
        modelContext.insert(task)
        
        do {
            try modelContext.save()
            Logger.general.info("Custom task added successfully: \(task.title)")
        } catch {
            Logger.error.error("Error saving custom task: \(error.localizedDescription)")
        }
    }
    
    func moveTask(_ task: DailyTask, toDay targetDay: Int) {
        guard task.dayOfWeek != targetDay else { return }
        
        let originalDay = task.dayOfWeek
        
        // 新しい曜日のタスク数を取得してソート順序を設定
        if let template = task.template {
            let targetDayTasks = template.tasksForDay(targetDay)
            task.sortOrder = (targetDayTasks.map { $0.sortOrder }.max() ?? -1) + 1
        }
        
        // 曜日を変更
        task.dayOfWeek = targetDay
        
        do {
            try modelContext.save()
            Logger.general.info("Task '\(task.title)' moved from day \(originalDay) to day \(targetDay)")
        } catch {
            Logger.error.error("Error moving task: \(error.localizedDescription)")
            // エラーが発生した場合は元に戻す
            task.dayOfWeek = originalDay
        }
    }
    
    // MARK: - Apple Reminders-style Interaction Methods
    
    func toggleTaskCompletion(_ task: DailyTask) {
        if isTaskCompleted(task) {
            markTaskAsIncomplete(task)
            HapticManager.shared.trigger(.impact(.light))
        } else {
            let _ = quickCompleteTask(task)
            HapticManager.shared.trigger(.impact(.medium))
        }
    }
    
    func startEditingTask(_ task: DailyTask) {
        editingTasks.insert(task.id)
        HapticManager.shared.trigger(.selection)
    }
    
    func finishEditingTask(_ task: DailyTask) {
        editingTasks.remove(task.id)
        saveTaskChanges(task)
    }
    
    func isTaskEditing(_ task: DailyTask) -> Bool {
        return editingTasks.contains(task.id)
    }
    
    func duplicateTask(_ task: DailyTask) {
        let duplicatedTask = DailyTask(
            dayOfWeek: task.dayOfWeek,
            workoutType: task.workoutType,
            title: task.title + " (コピー)",
            description: task.taskDescription,
            targetDetails: task.targetDetails,
            isFlexible: task.isFlexible
        )
        
        // ソート順序を設定（元のタスクの次）
        if let template = task.template {
            let sameDayTasks = template.tasksForDay(task.dayOfWeek)
            duplicatedTask.sortOrder = task.sortOrder + 1
            
            // 後続タスクのソート順序を更新
            for laterTask in sameDayTasks where laterTask.sortOrder > task.sortOrder {
                laterTask.sortOrder += 1
            }
            
            template.addTask(duplicatedTask)
        }
        
        modelContext.insert(duplicatedTask)
        
        do {
            try modelContext.save()
            HapticManager.shared.trigger(.notification(.success))
            Logger.general.info("Task duplicated successfully: \(duplicatedTask.title)")
        } catch {
            Logger.error.error("Error duplicating task: \(error.localizedDescription)")
            HapticManager.shared.trigger(.notification(.error))
        }
    }
    
    func deleteTask(_ task: DailyTask) {
        // 完了記録も削除
        let recordDescriptor = FetchDescriptor<WorkoutRecord>()
        
        do {
            let allRecords = try modelContext.fetch(recordDescriptor)
            let relatedRecords = allRecords.filter { $0.templateTask?.id == task.id }
            
            for record in relatedRecords {
                modelContext.delete(record)
            }
            
            modelContext.delete(task)
            completedTasks.remove(task.id)
            editingTasks.remove(task.id)
            
            try modelContext.save()
            HapticManager.shared.trigger(.notification(.warning))
            Logger.general.info("Task deleted successfully: \(task.title)")
        } catch {
            Logger.error.error("Error deleting task: \(error.localizedDescription)")
            HapticManager.shared.trigger(.notification(.error))
        }
    }
    
    func showMoveTaskSheet(_ task: DailyTask) {
        showingMoveTask = task
        HapticManager.shared.trigger(.impact(.medium))
    }
    
    func confirmDeleteTask(_ task: DailyTask) {
        showingDeleteConfirmation = task
        HapticManager.shared.trigger(.impact(.heavy))
    }
    
    private func saveTaskChanges(_ task: DailyTask) {
        do {
            try modelContext.save()
            HapticManager.shared.trigger(.notification(.success))
            Logger.general.info("Task changes saved: \(task.title)")
        } catch {
            Logger.error.error("Error saving task changes: \(error.localizedDescription)")
            HapticManager.shared.trigger(.notification(.error))
        }
    }
    
    // MARK: - Drag & Drop Support
    
    func moveTasksInDay(_ day: Int, from source: IndexSet, to destination: Int) {
        // Find active template
        let templateDescriptor = FetchDescriptor<WeeklyTemplate>(
            predicate: #Predicate<WeeklyTemplate> { $0.isActive }
        )
        
        do {
            let activeTemplates = try modelContext.fetch(templateDescriptor)
            guard let template = activeTemplates.first else { return }
            
            var tasks = template.tasksForDay(day).sorted { $0.sortOrder < $1.sortOrder }
            tasks.move(fromOffsets: source, toOffset: destination)
            
            // Update sort orders
            for (index, task) in tasks.enumerated() {
                task.sortOrder = index
            }
            
            try modelContext.save()
            HapticManager.shared.trigger(.impact(.medium))
            Logger.general.info("Tasks reordered in day \(day)")
        } catch {
            Logger.error.error("Error reordering tasks: \(error.localizedDescription)")
            HapticManager.shared.trigger(.notification(.error))
        }
    }
    
    func moveTaskToPosition(draggedTaskId: String, targetTask: DailyTask, targetDay: Int) {
        
        // Find the dragged task
        let taskDescriptor = FetchDescriptor<DailyTask>()
        
        do {
            let allTasks = try modelContext.fetch(taskDescriptor)
            guard let draggedTask = allTasks.first(where: { "\($0.id)" == draggedTaskId }) else {
                Logger.error.error("Could not find dragged task with ID: \(draggedTaskId)")
                return
            }
            
            let oldDay = draggedTask.dayOfWeek
            let newDay = targetDay
            
            // If moving to different day
            if oldDay != newDay {
                // Update day of week
                draggedTask.dayOfWeek = newDay
                
                // Reorder tasks in old day
                if let template = draggedTask.template {
                    let oldDayTasks = template.tasksForDay(oldDay)
                        .filter { $0.id != draggedTask.id }
                        .sorted { $0.sortOrder < $1.sortOrder }
                    
                    for (index, task) in oldDayTasks.enumerated() {
                        task.sortOrder = index
                    }
                }
            }
            
            // Set new sort order (insert before target task)
            draggedTask.sortOrder = targetTask.sortOrder
            
            // Update sort orders for tasks after the target
            if let template = targetTask.template {
                let newDayTasks = template.tasksForDay(newDay)
                    .filter { $0.sortOrder >= targetTask.sortOrder && $0.id != draggedTask.id }
                    .sorted { $0.sortOrder < $1.sortOrder }
                
                for (index, task) in newDayTasks.enumerated() {
                    task.sortOrder = targetTask.sortOrder + index + 1
                }
            }
            
            try modelContext.save()
            HapticManager.shared.trigger(.notification(.success))
            Logger.general.info("Task '\(draggedTask.title)' moved from day \(oldDay) to day \(newDay)")
            
        } catch {
            Logger.error.error("Error moving task: \(error.localizedDescription)")
            HapticManager.shared.trigger(.notification(.error))
        }
    }
}