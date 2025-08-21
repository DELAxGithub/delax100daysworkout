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
                record.cyclingData = SimpleCyclingData(
                    zone: .z2,
                    duration: targetDetails.targetDuration ?? 60,
                    power: targetDetails.targetPower
                )
            }
        case .strength:
            record.strengthData = SimpleStrengthData(
                muscleGroup: .chest,
                customName: nil,
                weight: 0,
                reps: 10,
                sets: 3
            )
        case .flexibility:
            if let targetDetails = task.targetDetails {
                record.flexibilityData = SimpleFlexibilityData(
                    type: .general,
                    duration: targetDetails.targetDuration ?? 20,
                    measurement: nil
                )
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
            
            // TODO: Implement streak achievement detection
            // if let streakAchievement = Achievement.checkForStreak(records: allRecords, targetDays: 7) {
            //     modelContext.insert(streakAchievement)
            // }
            
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
    
    // MARK: - QuickRecord Integration
    
    /// QuickRecordViewで記録を作成し、必要に応じてDailyTaskも作成する
    func createQuickRecordWithTask(workoutType: WorkoutType, selectedDay: Int, recordData: Any) -> (task: DailyTask?, record: WorkoutRecord?) {
        // アクティブなテンプレートを取得
        let templateDescriptor = FetchDescriptor<WeeklyTemplate>(
            predicate: #Predicate<WeeklyTemplate> { $0.isActive }
        )
        
        guard let activeTemplate = try? modelContext.fetch(templateDescriptor).first else {
            Logger.error.error("No active template found for quick record creation")
            return (nil, nil)
        }
        
        // 既存のタスクを検索
        let existingTasks = activeTemplate.tasksForDay(selectedDay)
        let matchingTask = existingTasks.first { $0.workoutType == workoutType }
        
        let task: DailyTask
        
        if let existing = matchingTask {
            // 既存のタスクを使用
            task = existing
        } else {
            // 新しいタスクを作成
            task = createNewDailyTask(workoutType: workoutType, day: selectedDay, template: activeTemplate)
        }
        
        // WorkoutRecordを作成
        let record = WorkoutRecord.fromDailyTask(task)
        record.markAsCompleted()
        record.isQuickRecord = true
        
        // レコードにデータを設定
        setRecordData(record: record, workoutType: workoutType, data: recordData)
        
        // データベースに保存
        modelContext.insert(record)
        
        do {
            try modelContext.save()
            
            // 完了済みタスクの状態を更新
            completedTasks.insert(task.id)
            
            // アチーブメントチェック
            checkForAchievements(record)
            
            Logger.general.info("Quick record created successfully: \(task.title)")
            return (task, record)
        } catch {
            Logger.error.error("Error saving quick record: \(error.localizedDescription)")
            return (nil, nil)
        }
    }
    
    /// 新しいDailyTaskを作成してテンプレートに追加
    private func createNewDailyTask(workoutType: WorkoutType, day: Int, template: WeeklyTemplate) -> DailyTask {
        let task = DailyTask(
            dayOfWeek: day,
            workoutType: workoutType,
            title: generateTaskTitle(for: workoutType),
            description: "クイック記録から追加",
            isFlexible: false
        )
        
        // ワークアウトタイプに応じてデフォルトのターゲット詳細を設定
        task.targetDetails = createDefaultTargetDetails(for: workoutType)
        
        // ソート順序を設定（同じ曜日の最大値＋1）
        let existingTasks = template.tasksForDay(day)
        task.sortOrder = (existingTasks.map { $0.sortOrder }.max() ?? -1) + 1
        
        // テンプレートにタスクを追加
        template.addTask(task)
        modelContext.insert(task)
        
        Logger.general.info("New daily task created: \(task.title) for day \(day)")
        return task
    }
    
    /// ワークアウトタイプに応じてデフォルトのTargetDetailsを作成
    private func createDefaultTargetDetails(for workoutType: WorkoutType) -> TargetDetails {
        var details = TargetDetails()
        
        switch workoutType {
        case .cycling:
            details.duration = 60
            details.intensity = .z2  // デフォルトでZ2（有酸素）
            details.targetPower = 200
            
        case .strength:
            details.targetSets = 3
            details.targetReps = 12
            details.exercises = ["基本トレーニング"]
            
        case .flexibility, .pilates, .yoga:
            details.targetDuration = 30
            if workoutType == .flexibility {
                details.targetForwardBend = 0.0
                details.targetSplitAngle = 90.0
            }
        }
        
        return details
    }
    
    /// ワークアウトタイプに基づいてタスクタイトルを生成
    private func generateTaskTitle(for workoutType: WorkoutType) -> String {
        switch workoutType {
        case .cycling:
            return "サイクリング"
        case .strength:
            return "筋トレ"
        case .flexibility:
            return "ストレッチ"
        case .pilates:
            return "ピラティス"
        case .yoga:
            return "ヨガ"
        }
    }
    
    /// WorkoutRecordにデータを設定
    private func setRecordData(record: WorkoutRecord, workoutType: WorkoutType, data: Any) {
        switch workoutType {
        case .cycling:
            if let cyclingData = data as? SimpleCyclingData {
                record.cyclingData = cyclingData
            }
        case .strength:
            if let strengthData = data as? SimpleStrengthData {
                record.strengthData = strengthData
            }
        case .flexibility, .pilates, .yoga:
            if let flexibilityData = data as? SimpleFlexibilityData {
                record.flexibilityData = flexibilityData
            }
        }
    }
    
    /// QuickRecordView完了後にスケジュールビューを更新
    func refreshAfterQuickRecord() {
        refreshCompletedTasks()
        Logger.general.info("Schedule view refreshed after quick record")
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