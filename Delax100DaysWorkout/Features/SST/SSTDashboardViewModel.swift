import Foundation
import SwiftData
import OSLog
import SwiftUI

@MainActor
class SSTDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var ftpHistory: [FTPHistory] = []
    @Published var currentFTP: Int? = nil
    @Published var goalFTP: Int? = nil
    @Published var ftpProgress: Double = 0.0
    @Published var whrData: [WHRDataPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
    // MARK: - Computed Properties
    
    var twentyMinutePowerTarget: Int? {
        guard let ftp = currentFTP else { return nil }
        return Int(Double(ftp) * 1.05) // 20分目標は現在FTPの105%
    }
    
    var ftpChangeFromPrevious: (value: Int, percentage: Double)? {
        guard ftpHistory.count >= 2 else { return nil }
        let latest = ftpHistory[0].ftpValue
        let previous = ftpHistory[1].ftpValue
        let change = latest - previous
        let percentage = Double(change) / Double(previous) * 100
        return (value: change, percentage: percentage)
    }
    
    var formattedFTPChange: String? {
        guard let change = ftpChangeFromPrevious else { return nil }
        let sign = change.value >= 0 ? "+" : ""
        return "\(sign)\(change.value)W (\(String(format: "%.1f", change.percentage))%)"
    }
    
    // MARK: - Initialization
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        guard let context = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            loadFTPHistory(context: context)
            loadWHRData(context: context)
            calculateGoalFTP()
            calculateProgress()
        } catch {
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func loadFTPHistory(context: ModelContext) {
        let descriptor = FetchDescriptor<FTPHistory>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            ftpHistory = try context.fetch(descriptor)
            currentFTP = ftpHistory.first?.ftpValue
        } catch {
            Logger.error.error("Failed to load FTP history: \(error.localizedDescription)")
            ftpHistory = []
            currentFTP = nil
        }
    }
    
    private func loadWHRData(context: ModelContext) {
        // 過去30日のサイクリングデータを取得
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let cyclingType = WorkoutType.cycling
        let predicate = #Predicate<WorkoutRecord> { workout in
            workout.date >= thirtyDaysAgo && workout.workoutType == cyclingType
        }
        
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let workouts = try context.fetch(descriptor)
            whrData = workouts.compactMap { workout in
                // TODO: Update for SimpleCyclingData - WHR not available in simple model
                guard let cycling = workout.cyclingData else { return nil }
                // Using dummy values since WHR isn't in SimpleCyclingData
                return WHRDataPoint(date: workout.date, whrRatio: 1.0, averagePower: Double(cycling.power ?? 0))
            }
        } catch {
            Logger.error.error("Failed to load W/HR data: \(error.localizedDescription)")
            whrData = []
        }
    }
    
    private func calculateGoalFTP() {
        guard let current = currentFTP else {
            goalFTP = nil
            return
        }
        
        // 目標FTPを現在の110%に設定（カスタマイズ可能）
        goalFTP = Int(Double(current) * 1.1)
    }
    
    private func calculateProgress() {
        guard let current = currentFTP, let goal = goalFTP else {
            ftpProgress = 0.0
            return
        }
        
        // 過去のベースラインからの進捗を計算
        let baseline = ftpHistory.last?.ftpValue ?? current
        let progress = Double(current - baseline) / Double(goal - baseline)
        ftpProgress = min(max(progress, 0.0), 1.0)
    }
    
    // MARK: - Data Management
    
    func refreshData() {
        loadData()
    }
    
    func getFTPTrend() -> FTPTrend {
        guard ftpHistory.count >= 3 else { return .stable }
        
        let recent = Array(ftpHistory.prefix(3))
        let changes = zip(recent.dropFirst(), recent).map { current, previous in
            current.ftpValue - previous.ftpValue
        }
        
        let averageChange = Double(changes.reduce(0, +)) / Double(changes.count)
        
        if averageChange > 2 {
            return .improving(rate: averageChange)
        } else if averageChange < -2 {
            return .declining(rate: abs(averageChange))
        } else {
            return .stable
        }
    }
    
    func getWHRTrend() -> WHRTrend {
        guard whrData.count >= 7 else { return .stable }
        
        let recent = Array(whrData.suffix(7))
        let older = Array(whrData.prefix(7))
        
        let recentAverage = recent.map(\.whrRatio).reduce(0, +) / Double(recent.count)
        let olderAverage = older.map(\.whrRatio).reduce(0, +) / Double(older.count)
        
        let change = recentAverage - olderAverage
        
        if change > 0.05 {
            return .improving(rate: change)
        } else if change < -0.05 {
            return .declining(rate: abs(change))
        } else {
            return .stable
        }
    }
}

// MARK: - Data Models

struct WHRDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let whrRatio: Double
    let averagePower: Double
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    var formattedWHR: String {
        return String(format: "%.2f", whrRatio)
    }
}

enum FTPTrend {
    case improving(rate: Double)
    case stable
    case declining(rate: Double)
    
    var displayText: String {
        switch self {
        case .improving(let rate):
            return "向上中 (+\(String(format: "%.1f", rate))W/回)"
        case .stable:
            return "安定"
        case .declining(let rate):
            return "低下傾向 (-\(String(format: "%.1f", rate))W/回)"
        }
    }
    
    var color: Color {
        switch self {
        case .improving:
            return .green
        case .stable:
            return .blue
        case .declining:
            return .orange
        }
    }
    
    var iconName: String {
        switch self {
        case .improving:
            return "arrow.up.right"
        case .stable:
            return "arrow.right"
        case .declining:
            return "arrow.down.right"
        }
    }
}

enum WHRTrend {
    case improving(rate: Double)
    case stable
    case declining(rate: Double)
    
    var displayText: String {
        switch self {
        case .improving(let rate):
            return "効率向上 (+\(String(format: "%.2f", rate)))"
        case .stable:
            return "安定"
        case .declining(let rate):
            return "効率低下 (-\(String(format: "%.2f", rate)))"
        }
    }
    
    var color: Color {
        switch self {
        case .improving:
            return .green
        case .stable:
            return .blue
        case .declining:
            return .red
        }
    }
}

// MARK: - Sample Data for Previews

extension SSTDashboardViewModel {
    static func sampleViewModel() -> SSTDashboardViewModel {
        let viewModel = SSTDashboardViewModel()
        
        // Sample FTP history
        let calendar = Calendar.current
        viewModel.ftpHistory = [
            FTPHistory(
                date: Date(),
                ftpValue: 280,
                measurementMethod: .twentyMinuteTest,
                notes: "Good test"
            ),
            FTPHistory(
                date: calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                ftpValue: 275,
                measurementMethod: .manual
            ),
            FTPHistory(
                date: calendar.date(byAdding: .day, value: -28, to: Date()) ?? Date(),
                ftpValue: 270,
                measurementMethod: .rampTest
            )
        ]
        
        viewModel.currentFTP = 280
        viewModel.goalFTP = 308
        viewModel.ftpProgress = 0.4
        
        // Sample W/HR data
        viewModel.whrData = (0..<30).compactMap { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let whr = 1.8 + Double.random(in: -0.2...0.2)
            let power = 250 + Double.random(in: -50...50)
            return WHRDataPoint(date: date, whrRatio: whr, averagePower: power)
        }.reversed()
        
        return viewModel
    }
}