import SwiftUI
import SwiftData

// MARK: - Data Management View Model

@Observable
class DataManagementViewModel {
    
    // MARK: - Alert States
    var showingResetAlert = false
    var showingWorkoutDeleteAlert = false
    var showingFTPDeleteAlert = false
    var showingMetricsDeleteAlert = false
    var showingTasksDeleteAlert = false
    var showingTemplatesDeleteAlert = false
    var showingProfileDeleteAlert = false
    var showingDemoDataOptions = false
    
    // MARK: - Navigation State
    var selectedEditModel: EditableModel?
    
    // MARK: - Helper Methods
    
    func getModelCount(_ model: EditableModel, queries: DataManagementQueries) -> Int {
        switch model {
        case .workoutRecords: return queries.workoutRecords.count
        case .ftpHistory: return queries.ftpHistory.count
        case .dailyMetrics: return queries.validDailyMetrics.count
        case .dailyTasks: return queries.dailyTasks.count
        case .weeklyTemplates: return queries.weeklyTemplates.count
        case .userProfiles: return queries.userProfiles.count
        }
    }
    
    func showDeleteAlert(for model: EditableModel) {
        switch model {
        case .workoutRecords: showingWorkoutDeleteAlert = true
        case .ftpHistory: showingFTPDeleteAlert = true
        case .dailyMetrics: showingMetricsDeleteAlert = true
        case .dailyTasks: showingTasksDeleteAlert = true
        case .weeklyTemplates: showingTemplatesDeleteAlert = true
        case .userProfiles: showingProfileDeleteAlert = true
        }
    }
    
    func getTotalDataCount(queries: DataManagementQueries) -> Int {
        return queries.workoutRecords.count + 
               queries.ftpHistory.count + 
               queries.validDailyMetrics.count + 
               queries.dailyTasks.count + 
               queries.weeklyTemplates.count + 
               queries.userProfiles.count
    }
}

// MARK: - Data Queries Wrapper

struct DataManagementQueries {
    let workoutRecords: [WorkoutRecord]
    let ftpHistory: [FTPHistory]
    let dailyMetrics: [DailyMetric]
    let dailyTasks: [DailyTask]
    let weeklyTemplates: [WeeklyTemplate]
    let userProfiles: [UserProfile]
    
    var validDailyMetrics: [DailyMetric] {
        dailyMetrics.filter { $0.hasAnyData }
    }
}