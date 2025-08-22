import SwiftUI
import SwiftData
import OSLog

// MARK: - Home Data Store

@MainActor
@Observable
class HomeDataStore {
    // MARK: - Published Properties
    
    // Today's Tasks
    var todayTasks: [DailyTask] = []
    var todayCompletedTasks: Int = 0
    var todayTotalTasks: Int = 0
    
    // Health Data
    var todaySteps: Int = 0
    var currentWeight: Double?
    
    // FTP Data
    var currentFTP: Int?
    
    // Monthly Progress
    var monthlyWorkouts: [WorkoutRecord] = []
    
    // UI State
    var isLoading = false
    var errors: [HomeDataError] = []
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let healthKitManager: HealthKitManager
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, healthKitManager: HealthKitManager? = nil) {
        self.modelContext = modelContext
        self.healthKitManager = healthKitManager ?? HealthKitManager.shared
    }
    
    // MARK: - Public Methods
    
    func loadAllData() async {
        isLoading = true
        errors.removeAll()
        
        // 並列でデータ取得（既存ViewModel機能を統合）
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTodaysTasks() }
            group.addTask { await self.loadHealthKitData() }
            group.addTask { await self.loadFTPData() }
            group.addTask { await self.loadMonthlyWorkouts() }
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadAllData()
    }
    
    // MARK: - Today's Tasks (WeeklyScheduleViewModel統合)
    
    private func loadTodaysTasks() async {
        do {
            // アクティブなWeeklyTemplateを取得
            let templateDescriptor = FetchDescriptor<WeeklyTemplate>(
                predicate: #Predicate<WeeklyTemplate> { template in
                    template.isActive == true
                }
            )
            
            let templates = try modelContext.fetch(templateDescriptor)
            guard let activeTemplate = templates.first else {
                // アクティブなテンプレートがない場合
                todayTasks = []
                todayTotalTasks = 0
                todayCompletedTasks = 0
                errors.append(.noActiveTemplate)
                return
            }
            
            // 今日の曜日を取得 (0=Sunday, 1=Monday, etc.)
            let today = Calendar.current.component(.weekday, from: Date()) - 1
            
            // 今日のタスクをフィルタリング
            let tasks = activeTemplate.tasksForDay(today).sorted { $0.sortOrder < $1.sortOrder }
            
            // 完了済みタスクを取得（WeeklyScheduleViewModelのロジックを使用）
            let completedTaskIds = await getCompletedTaskIds()
            let completedCount = tasks.filter { completedTaskIds.contains($0.id) }.count
            
            todayTasks = tasks
            todayTotalTasks = tasks.count
            todayCompletedTasks = completedCount
            
            Logger.general.info("Today's tasks loaded: \(tasks.count) total, \(completedCount) completed")
            
        } catch {
            errors.append(.taskLoadFailed(error.localizedDescription))
            Logger.error.error("Failed to load today's tasks: \(error.localizedDescription)")
        }
    }
    
    private func getCompletedTaskIds() async -> Set<PersistentIdentifier> {
        do {
            // 今日の完了済み記録を取得（WeeklyScheduleViewModelのロジック）
            let recordDescriptor = FetchDescriptor<WorkoutRecord>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            let allRecords = try modelContext.fetch(recordDescriptor)
            let today = Date()
            
            let todaysCompletedRecords = allRecords.filter { record in
                Calendar.current.isDate(record.date, inSameDayAs: today) && record.isCompleted
            }
            
            return Set(todaysCompletedRecords.compactMap { $0.templateTask?.id })
        } catch {
            Logger.error.error("Failed to get completed task IDs: \(error.localizedDescription)")
            return Set()
        }
    }
    
    // MARK: - Health Data (HealthKitManager統合)
    
    private func loadHealthKitData() async {
        // 歩数取得
        do {
            if !healthKitManager.isAuthorized {
                errors.append(.healthKitNotAuthorized)
                return
            }
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            let steps = try await healthKitManager.getStepCount(from: startOfDay, to: endOfDay)
            todaySteps = Int(steps)
            
            Logger.general.info("Today's steps loaded: \(steps)")
            
        } catch {
            errors.append(.stepCountFailed(error.localizedDescription))
            Logger.error.error("Failed to load step count: \(error.localizedDescription)")
        }
        
        // 体重取得（最新のDailyMetricから）
        await loadLatestWeight()
    }
    
    private func loadLatestWeight() async {
        do {
            let descriptor = FetchDescriptor<DailyMetric>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let metrics = try modelContext.fetch(descriptor)
            
            if let latestMetric = metrics.first, let weight = latestMetric.weightKg {
                currentWeight = weight
                Logger.general.info("Latest weight loaded: \(weight)kg")
            } else {
                currentWeight = nil
                Logger.general.info("No weight data available")
            }
            
        } catch {
            errors.append(.weightLoadFailed(error.localizedDescription))
            Logger.error.error("Failed to load weight data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - FTP Data (SSTDashboardViewModel統合)
    
    private func loadFTPData() async {
        do {
            let descriptor = FetchDescriptor<FTPHistory>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let ftpRecords = try modelContext.fetch(descriptor)
            
            if let latestFTP = ftpRecords.first {
                currentFTP = latestFTP.ftpValue
                Logger.general.info("Latest FTP loaded: \(latestFTP.ftpValue)W")
            } else {
                currentFTP = nil
                Logger.general.info("No FTP data available")
            }
            
        } catch {
            errors.append(.ftpLoadFailed(error.localizedDescription))
            Logger.error.error("Failed to load FTP data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Monthly Workouts (ProgressChartViewModel統合)
    
    private func loadMonthlyWorkouts() async {
        do {
            // 今月の開始日を取得
            let calendar = Calendar.current
            let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            
            let descriptor = FetchDescriptor<WorkoutRecord>(
                predicate: #Predicate<WorkoutRecord> { record in
                    record.date >= startOfMonth
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            let workouts = try modelContext.fetch(descriptor)
            monthlyWorkouts = workouts
            
            Logger.general.info("Monthly workouts loaded: \(workouts.count)")
            
        } catch {
            errors.append(.workoutLoadFailed(error.localizedDescription))
            Logger.error.error("Failed to load monthly workouts: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Computed Properties
    
    var taskProgress: Double {
        guard todayTotalTasks > 0 else { return 0 }
        return Double(todayCompletedTasks) / Double(todayTotalTasks)
    }
    
    var hasHealthKitPermission: Bool {
        return healthKitManager.isAuthorized
    }
    
    var monthlyWorkoutCount: Int {
        return monthlyWorkouts.count
    }
    
    var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    var hasData: Bool {
        return todayTotalTasks > 0 || currentFTP != nil || monthlyWorkoutCount > 0
    }
    
    // MARK: - Task Completion Methods
    
    func isTaskCompleted(_ task: DailyTask) -> Bool {
        let completedTaskIds = getCompletedTaskIds()
        return completedTaskIds.contains(task.id)
    }
    
    func toggleTaskCompletion(_ task: DailyTask) {
        if isTaskCompleted(task) {
            markTaskAsIncomplete(task)
        } else {
            let _ = quickCompleteTask(task)
        }
        
        // Refresh today's task completion count
        Task {
            await loadTodaysTasks()
        }
    }
    
    private func quickCompleteTask(_ task: DailyTask) -> WorkoutRecord? {
        let record = WorkoutRecord.fromDailyTask(task)
        record.markAsCompleted()
        modelContext.insert(record)
        
        // Set basic data based on workout type
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
                muscleGroup: .core,
                weight: 0,
                reps: task.targetDetails?.targetReps ?? 10,
                sets: task.targetDetails?.targetSets ?? 3
            )
        case .flexibility:
            record.flexibilityData = SimpleFlexibilityData(
                type: .general,
                duration: task.targetDetails?.targetDuration ?? 30
            )
        case .pilates:
            record.flexibilityData = SimpleFlexibilityData(
                type: .pilates,
                duration: task.targetDetails?.targetDuration ?? 30
            )
        case .yoga:
            record.flexibilityData = SimpleFlexibilityData(
                type: .yoga,
                duration: task.targetDetails?.targetDuration ?? 30
            )
        }
        
        do {
            try modelContext.save()
            Logger.general.info("Task completed: \(task.title)")
        } catch {
            Logger.error.error("Error saving completed task: \(error.localizedDescription)")
        }
        
        return record
    }
    
    private func markTaskAsIncomplete(_ task: DailyTask) {
        var recordDescriptor = FetchDescriptor<WorkoutRecord>()
        recordDescriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        
        do {
            let allRecords = try modelContext.fetch(recordDescriptor)
            
            // Find today's completion record for this task
            let today = Date()
            let todaysTaskRecords = allRecords.filter { record in
                Calendar.current.isDate(record.date, inSameDayAs: today) &&
                record.isCompleted &&
                record.templateTask?.id == task.id
            }
            
            // Mark the latest record as incomplete
            if let latestRecord = todaysTaskRecords.first {
                latestRecord.isCompleted = false
                
                try modelContext.save()
                Logger.general.info("Task marked as incomplete: \(task.title)")
            }
        } catch {
            Logger.error.error("Error marking task as incomplete: \(error.localizedDescription)")
        }
    }
    
    private func getCompletedTaskIds() -> Set<PersistentIdentifier> {
        do {
            let recordDescriptor = FetchDescriptor<WorkoutRecord>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            let allRecords = try modelContext.fetch(recordDescriptor)
            let today = Date()
            
            let todaysCompletedRecords = allRecords.filter { record in
                Calendar.current.isDate(record.date, inSameDayAs: today) && record.isCompleted
            }
            
            return Set(todaysCompletedRecords.compactMap { $0.templateTask?.id })
        } catch {
            Logger.error.error("Failed to get completed task IDs: \(error.localizedDescription)")
            return Set()
        }
    }
}

// MARK: - Home Data Error

enum HomeDataError: Identifiable, Equatable {
    case noActiveTemplate
    case taskLoadFailed(String)
    case healthKitNotAuthorized
    case stepCountFailed(String)
    case weightLoadFailed(String)
    case ftpLoadFailed(String)
    case workoutLoadFailed(String)
    
    var id: String {
        switch self {
        case .noActiveTemplate:
            return "noActiveTemplate"
        case .taskLoadFailed(let message):
            return "taskLoadFailed_\(message)"
        case .healthKitNotAuthorized:
            return "healthKitNotAuthorized"
        case .stepCountFailed(let message):
            return "stepCountFailed_\(message)"
        case .weightLoadFailed(let message):
            return "weightLoadFailed_\(message)"
        case .ftpLoadFailed(let message):
            return "ftpLoadFailed_\(message)"
        case .workoutLoadFailed(let message):
            return "workoutLoadFailed_\(message)"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .noActiveTemplate:
            return "アクティブなワークアウトテンプレートが設定されていません"
        case .taskLoadFailed(let message):
            return "タスク取得エラー: \(message)"
        case .healthKitNotAuthorized:
            return "Apple Health連携の権限が必要です"
        case .stepCountFailed(let message):
            return "歩数取得エラー: \(message)"
        case .weightLoadFailed(let message):
            return "体重データ取得エラー: \(message)"
        case .ftpLoadFailed(let message):
            return "FTPデータ取得エラー: \(message)"
        case .workoutLoadFailed(let message):
            return "ワークアウト記録取得エラー: \(message)"
        }
    }
    
    var canResolve: Bool {
        switch self {
        case .healthKitNotAuthorized, .noActiveTemplate:
            return true
        default:
            return false
        }
    }
    
    var actionTitle: String? {
        switch self {
        case .healthKitNotAuthorized:
            return "設定を開く"
        case .noActiveTemplate:
            return "テンプレート設定"
        default:
            return nil
        }
    }
}