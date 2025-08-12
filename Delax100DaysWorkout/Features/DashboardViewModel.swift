import Foundation
import SwiftData

@MainActor
@Observable
class DashboardViewModel {
    // MARK: - Published Properties for UI
    var daysRemaining: Int = 0
    var weightProgress: Double = 0.0
    var ftpProgress: Double = 0.0
    var pwrProgress: Double = 0.0

    var currentWeightFormatted: String = "N/A"
    var goalWeightFormatted: String = "N/A"
    var currentFtpFormatted: String = "N/A"
    var goalFtpFormatted: String = "N/A"
    var currentPwrFormatted: String = "N/A"
    var goalPwrFormatted: String = "N/A"

    // MARK: - Private Properties
    private var modelContext: ModelContext
    private var userProfile: UserProfile?
    private var latestDailyLog: DailyLog?
    var todaysWorkouts: [WorkoutRecord] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshData()
    }

    func refreshData() {
        fetchData()
        calculateMetrics()
    }

    private func fetchData() {
        // Fetch UserProfile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        self.userProfile = try? modelContext.fetch(profileDescriptor).first

        // Fetch the most recent DailyLog
        var logDescriptor = FetchDescriptor<DailyLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        logDescriptor.fetchLimit = 1
        self.latestDailyLog = try? modelContext.fetch(logDescriptor).first

        // Fetch today's WorkoutRecords
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        let predicate = #Predicate<WorkoutRecord> { record in
            record.date >= startOfToday && record.date < endOfToday
        }
        let workoutDescriptor = FetchDescriptor<WorkoutRecord>(predicate: predicate, sortBy: [SortDescriptor(\.date)])
        self.todaysWorkouts = (try? modelContext.fetch(workoutDescriptor)) ?? []
    }

    private func calculateMetrics() {
        guard let profile = userProfile else { return }

        // 1. Days Remaining
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: profile.goalDate)
        daysRemaining = max(0, components.day ?? 0)

        // 2. Current Values
        let currentWeight = latestDailyLog?.weightKg ?? profile.startWeightKg
        let currentFtp = profile.startFtp // Note: For now, current FTP is the start FTP.
        let currentPwr = (currentWeight > 0) ? Double(currentFtp) / currentWeight : 0.0
        let goalPwr = (profile.goalWeightKg > 0) ? Double(profile.goalFtp) / profile.goalWeightKg : 0.0

        // 3. Progress Calculation (0.0 to 1.0)
        let weightLossGoal = profile.startWeightKg - profile.goalWeightKg
        if weightLossGoal > 0 {
            let weightLost = profile.startWeightKg - currentWeight
            weightProgress = max(0, min(1, weightLost / weightLossGoal))
        }

        let ftpGainGoal = Double(profile.goalFtp - profile.startFtp)
        if ftpGainGoal > 0 {
            let ftpGained = Double(currentFtp - profile.startFtp)
            ftpProgress = max(0, min(1, ftpGained / ftpGainGoal))
        }

        let startPwr = (profile.startWeightKg > 0) ? Double(profile.startFtp) / profile.startWeightKg : 0.0
        let pwrGainGoal = goalPwr - startPwr
        if pwrGainGoal > 0 {
            let pwrGained = currentPwr - startPwr
            pwrProgress = max(0, min(1, pwrGained / pwrGainGoal))
        }

        // 4. Formatted Strings for UI
        currentWeightFormatted = String(format: "%.1f kg", currentWeight)
        goalWeightFormatted = String(format: "%.1f kg", profile.goalWeightKg)
        currentFtpFormatted = "\(currentFtp) W"
        goalFtpFormatted = "\(profile.goalFtp) W"
        currentPwrFormatted = String(format: "%.2f W/kg", currentPwr)
        goalPwrFormatted = String(format: "%.2f W/kg", goalPwr)
    }
    
    // MARK: - Workout Editing Functions
    
    func updateWorkout(_ originalWorkout: WorkoutRecord, with editedWorkout: WorkoutRecord) {
        do {
            // 既存のワークアウトを更新
            originalWorkout.date = editedWorkout.date
            originalWorkout.workoutType = editedWorkout.workoutType
            originalWorkout.summary = editedWorkout.summary
            originalWorkout.isCompleted = editedWorkout.isCompleted
            
            // 詳細データを更新
            originalWorkout.cyclingDetail = editedWorkout.cyclingDetail
            originalWorkout.strengthDetails = editedWorkout.strengthDetails
            originalWorkout.flexibilityDetail = editedWorkout.flexibilityDetail
            
            try modelContext.save()
            
            // データを再読み込み
            refreshData()
            
            print("✅ ワークアウトが正常に更新されました")
            
        } catch {
            print("❌ ワークアウト更新エラー: \(error.localizedDescription)")
        }
    }
    
    func deleteWorkout(_ workout: WorkoutRecord) {
        do {
            modelContext.delete(workout)
            try modelContext.save()
            
            // データを再読み込み
            refreshData()
            
            print("✅ ワークアウトが正常に削除されました")
            
        } catch {
            print("❌ ワークアウト削除エラー: \(error.localizedDescription)")
        }
    }
    
    func confirmDeleteWorkout(_ workout: WorkoutRecord, completion: @escaping (Bool) -> Void) {
        // UIの削除確認は呼び出し元で処理
        completion(true)
    }
    
    deinit {
        // Cleanup if needed
    }
}