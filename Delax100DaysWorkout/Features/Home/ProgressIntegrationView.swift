import SwiftUI
import SwiftData
import OSLog

// MARK: - Progress Integration View

struct ProgressIntegrationView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var taskCounterService = TaskCounterService.shared
    
    // State for data
    @State private var taskCounters: [TaskCompletionCounter] = []
    @State private var wprTrackingSystem: WPRTrackingSystem?
    @State private var goalData: GoalManagerData = GoalManagerData()
    @State private var intensityData: [TrainingIntensityData] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Task Counter Section (Issue #52 integration)
            TaskCounterSection(counters: taskCounters)
            
            // Goal vs Achievement Section
            GoalAchievementSection(
                weightGoal: goalData.weightGoal,
                ftpGoal: goalData.ftpGoal,
                workoutGoal: goalData.workoutGoal
            )
            
            // Integrated Progress Chart (WPR + Weight + FTP)
            if let wprSystem = wprTrackingSystem {
                IntegratedProgressChart(
                    wprData: createWPRDataPoints(from: wprSystem),
                    weightData: createWeightDataPoints(),
                    ftpData: createFTPDataPoints()
                )
            }
            
            // Training Intensity Balance
            TrainingIntensitySection(intensityData: intensityData)
        }
        .onAppear {
            loadAllData()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAllData() {
        Task {
            isLoading = true
            await loadTaskCounters()
            await loadWPRSystem()
            await loadGoalData()
            await loadIntensityData()
            isLoading = false
        }
    }
    
    @MainActor
    private func loadTaskCounters() async {
        taskCounters = taskCounterService.getAllCounterStats(in: modelContext)
            .map { $0.counter }
            .sorted { $0.completionCount > $1.completionCount }
    }
    
    @MainActor
    private func loadWPRSystem() async {
        let descriptor = FetchDescriptor<WPRTrackingSystem>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        do {
            let systems = try modelContext.fetch(descriptor)
            wprTrackingSystem = systems.first
        } catch {
            Logger.error.error("Error fetching WPR system: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadGoalData() async {
        goalData = await GoalManagerData.load(from: modelContext)
    }
    
    @MainActor
    private func loadIntensityData() async {
        // Generate sample intensity data - in real implementation, 
        // this would analyze WorkoutRecord data
        intensityData = [
            TrainingIntensityData(
                type: "サイクリング",
                weeklyHours: 4.5,
                averageIntensity: "Zone 2",
                trend: "↗️ +0.5h",
                color: .blue
            ),
            TrainingIntensityData(
                type: "筋トレ",
                weeklyHours: 2.5,
                averageIntensity: "中強度",
                trend: "→ 維持",
                color: .orange
            ),
            TrainingIntensityData(
                type: "柔軟性",
                weeklyHours: 1.0,
                averageIntensity: "軽度",
                trend: "↘️ -0.2h",
                color: .green
            )
        ]
    }
    
    // MARK: - Data Conversion
    
    private func createWPRDataPoints(from wprSystem: WPRTrackingSystem) -> [WPRDataPoint] {
        // In real implementation, this would fetch historical WPR data
        let calendar = Calendar.current
        var points: [WPRDataPoint] = []
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let progress = Double(30-i) / 30.0
                let wprValue = wprSystem.baselineWPR + (wprSystem.calculatedWPR - wprSystem.baselineWPR) * progress
                points.append(WPRDataPoint(date: date, value: wprValue))
            }
        }
        
        return points.reversed()
    }
    
    private func createWeightDataPoints() -> [WeightDataPoint] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<DailyMetric>(
            predicate: #Predicate { metric in
                metric.weightKg != nil && metric.date >= thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let metrics = try modelContext.fetch(descriptor)
            return metrics.compactMap { metric in
                guard let weight = metric.weightKg else { return nil }
                return WeightDataPoint(date: metric.date, weight: weight)
            }
        } catch {
            Logger.error.error("Error fetching weight data: \(error.localizedDescription)")
            return []
        }
    }
    
    private func createFTPDataPoints() -> [FTPDataPoint] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<FTPHistory>(
            predicate: #Predicate { history in
                history.date >= thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let history = try modelContext.fetch(descriptor)
            return history.map { ftp in
                FTPDataPoint(date: ftp.date, ftp: ftp.ftpValue)
            }
        } catch {
            Logger.error.error("Error fetching FTP data: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Goal Manager Data

struct GoalManagerData {
    var weightGoal: (current: Double?, target: Double, progress: String)?
    var ftpGoal: (current: Int?, target: Int, progress: String)?
    var workoutGoal: (current: Int, target: Int, progress: String)?
    
    static func load(from modelContext: ModelContext) async -> GoalManagerData {
        var data = GoalManagerData()
        
        // Weight goal
        if let currentWeight = await getCurrentWeight(from: modelContext) {
            let targetWeight = 65.0 // Default target, should be user-configurable
            let difference = currentWeight - targetWeight
            let progressText = difference > 0 ? 
                String(format: "%.1fkg減量", difference) : 
                String(format: "%.1fkg増量", abs(difference))
            
            data.weightGoal = (current: currentWeight, target: targetWeight, progress: progressText)
        }
        
        // FTP goal  
        if let currentFTP = await getCurrentFTP(from: modelContext) {
            let targetFTP = currentFTP + 20 // Default +20W improvement
            let difference = targetFTP - currentFTP
            let progressText = "+\(difference)W"
            
            data.ftpGoal = (current: currentFTP, target: targetFTP, progress: progressText)
        }
        
        // Workout goal
        let currentWorkouts = await getMonthlyWorkouts(from: modelContext)
        let targetWorkouts = 20 // Default monthly target
        let remaining = max(0, targetWorkouts - currentWorkouts)
        let progressText = remaining > 0 ? "残り\(remaining)回" : "目標達成！"
        
        data.workoutGoal = (current: currentWorkouts, target: targetWorkouts, progress: progressText)
        
        return data
    }
    
    private static func getCurrentWeight(from modelContext: ModelContext) async -> Double? {
        let descriptor = FetchDescriptor<DailyMetric>(
            predicate: #Predicate { $0.weightKg != nil },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let metrics = try modelContext.fetch(descriptor)
            return metrics.first?.weightKg
        } catch {
            return nil
        }
    }
    
    private static func getCurrentFTP(from modelContext: ModelContext) async -> Int? {
        let descriptor = FetchDescriptor<FTPHistory>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let history = try modelContext.fetch(descriptor)
            return history.first?.ftpValue
        } catch {
            return nil
        }
    }
    
    private static func getMonthlyWorkouts(from modelContext: ModelContext) async -> Int {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { record in
                record.date >= monthStart && record.isCompleted
            }
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            return records.count
        } catch {
            return 0
        }
    }
}

// Note: Logger.error already exists in Utils/Logger.swift - no need to redeclare

#Preview {
    ProgressIntegrationView()
        .modelContainer(for: [
            TaskCompletionCounter.self,
            WPRTrackingSystem.self,
            DailyMetric.self,
            FTPHistory.self,
            WorkoutRecord.self
        ])
}