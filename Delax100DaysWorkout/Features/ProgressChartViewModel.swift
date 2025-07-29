import Foundation
import SwiftData

@Observable
class ProgressChartViewModel {
    var dailyLogs: [DailyLog] = []
    var userProfile: UserProfile?

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

        } catch {
            print("Failed to fetch daily logs for chart: \(error)")
        }
    }
}