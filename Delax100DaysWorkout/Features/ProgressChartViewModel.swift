import Foundation
import SwiftData

@Observable
class ProgressChartViewModel {
    var dailyLogs: [DailyLog] = []
    var userProfile: UserProfile?
    var workoutRecords: [WorkoutRecord] = []

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }

    func fetchData() {
        do {
            // Fetch all DailyLog entries and sort them by date for the chart
            let logDescriptor = FetchDescriptor<DailyLog>(sortBy: [SortDescriptor(\.date, order: .forward)])
            dailyLogs = try modelContext.fetch(logDescriptor)

            // Fetch UserProfile to get the goal weight
            let profileDescriptor = FetchDescriptor<UserProfile>()
            userProfile = try modelContext.fetch(profileDescriptor).first
            
            // Fetch WorkoutRecords for progress stats
            let workoutDescriptor = FetchDescriptor<WorkoutRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            workoutRecords = try modelContext.fetch(workoutDescriptor)

        } catch {
            print("Failed to fetch data for progress chart: \(error)")
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchData()
    }
}