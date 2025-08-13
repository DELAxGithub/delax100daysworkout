import Foundation
import SwiftData
import SwiftUI

// MARK: - Home Dashboard ViewModel

@MainActor
@Observable
class HomeDashboardViewModel {
    // Dashboard State
    var summaryCards: [SummaryCardConfiguration] = []
    var todaysTasks: [DailyTask] = []
    var dashboardStats: DashboardStats = DashboardStats()
    var isLoading: Bool = false
    
    // Integrated ViewModels
    private var scheduleViewModel: WeeklyScheduleViewModel?
    private var todayViewModel: TodayViewModel?
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupIntegratedViewModels()
        loadDashboardData()
    }
    
    // MARK: - Setup Methods
    
    private func setupIntegratedViewModels() {
        scheduleViewModel = WeeklyScheduleViewModel(modelContext: modelContext)
        todayViewModel = TodayViewModel(modelContext: modelContext)
    }
    
    func loadDashboardData() {
        Task {
            isLoading = true
            
            await loadSummaryData()
            await loadTodaysTasks()
            await updateDashboardStats()
            
            isLoading = false
        }
    }
    
    // MARK: - Data Loading
    
    private func loadSummaryData() async {
        // FTP Card
        if let ftpData = await fetchFTPData() {
            summaryCards.append(.basic(
                title: "現在のFTP",
                value: "\(ftpData.current)W",
                subtitle: ftpData.changeText,
                color: .blue,
                icon: "bolt.fill"
            ))
        }
        
        // Progress Card
        if let progressData = await fetchProgressData() {
            summaryCards.append(.basic(
                title: "今週の進捗",
                value: "\(progressData)",
                subtitle: "ワークアウト完了",
                color: .green,
                icon: "checkmark.circle.fill"
            ))
        }
        
        // Weight Card
        if let weightData = await fetchWeightData() {
            summaryCards.append(.basic(
                title: "最新体重",
                value: weightData.displayValue,
                subtitle: weightData.source,
                color: .orange,
                icon: "figure.stand"
            ))
        }
    }
    
    private func loadTodaysTasks() async {
        if let todayViewModel = todayViewModel {
            todaysTasks = todayViewModel.todaysTasks
        }
    }
    
    private func updateDashboardStats() async {
        dashboardStats = DashboardStats(
            totalWorkouts: await fetchTotalWorkouts(),
            currentStreak: await fetchCurrentStreak(),
            weeklyProgress: await fetchWeeklyProgress()
        )
    }
    
    // MARK: - Public Methods
    
    func refreshAllData() {
        loadDashboardData()
        scheduleViewModel?.refreshCompletedTasks()
        todayViewModel?.refreshTasks()
    }
    
    func toggleTaskCompletion(_ task: DailyTask) {
        scheduleViewModel?.toggleTaskCompletion(task)
        Task { await loadTodaysTasks() }
    }
    
    func isTaskCompleted(_ task: DailyTask) -> Bool {
        return scheduleViewModel?.isTaskCompleted(task) ?? false
    }
}

// MARK: - Data Models

struct DashboardStats {
    let totalWorkouts: Int
    let currentStreak: Int
    let weeklyProgress: Double
    
    init(totalWorkouts: Int = 0, currentStreak: Int = 0, weeklyProgress: Double = 0) {
        self.totalWorkouts = totalWorkouts
        self.currentStreak = currentStreak
        self.weeklyProgress = weeklyProgress
    }
}

// MARK: - Private Data Fetching Extensions

private extension HomeDashboardViewModel {
    func fetchFTPData() async -> (current: Int, changeText: String)? {
        let descriptor = FetchDescriptor<FTPHistory>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let history = try modelContext.fetch(descriptor)
            guard let latest = history.first else { return nil }
            
            let changeText = history.count > 1 ? 
                calculateFTPChange(latest: latest, previous: history[1]) : "初回記録"
            
            return (current: latest.ftpValue, changeText: changeText)
        } catch {
            return nil
        }
    }
    
    func calculateFTPChange(latest: FTPHistory, previous: FTPHistory) -> String {
        let change = latest.ftpValue - previous.ftpValue
        let prefix = change > 0 ? "+" : ""
        return "\(prefix)\(change)W"
    }
    
    func fetchProgressData() async -> Int? {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.date >= weekStart && $0.isCompleted }
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            return records.count
        } catch {
            return nil
        }
    }
    
    func fetchWeightData() async -> (displayValue: String, source: String)? {
        let descriptor = FetchDescriptor<DailyMetric>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let metrics = try modelContext.fetch(descriptor)
            guard let latest = metrics.first, let weight = latest.weightKg else {
                return (displayValue: "未測定", source: "手動入力")
            }
            
            return (
                displayValue: String(format: "%.1f kg", weight),
                source: "Apple Health"
            )
        } catch {
            return nil
        }
    }
    
    func fetchTotalWorkouts() async -> Int {
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.isCompleted }
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            return records.count
        } catch {
            return 0
        }
    }
    
    func fetchCurrentStreak() async -> Int {
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.isCompleted },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            return calculateStreak(records: records)
        } catch {
            return 0
        }
    }
    
    func fetchWeeklyProgress() async -> Double {
        guard let progressData = await fetchProgressData() else { return 0 }
        return min(Double(progressData) / 7.0, 1.0)
    }
    
    func calculateStreak(records: [WorkoutRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        let recordsByDay = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.date)
        }
        
        while let dayRecords = recordsByDay[calendar.startOfDay(for: currentDate)],
              !dayRecords.isEmpty {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
}