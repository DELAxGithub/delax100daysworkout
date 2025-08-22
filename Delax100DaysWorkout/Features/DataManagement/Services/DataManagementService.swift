import SwiftUI
import SwiftData
import OSLog

// MARK: - Data Management Service

class DataManagementService {
    
    // MARK: - Delete Operations
    
    static func deleteAllData(
        queries: DataManagementQueries,
        modelContext: ModelContext
    ) {
        withAnimation {
            // Delete all data types
            for record in queries.workoutRecords {
                modelContext.delete(record)
            }
            for record in queries.ftpHistory {
                modelContext.delete(record)
            }
            for record in queries.dailyMetrics {
                modelContext.delete(record)
            }
            for record in queries.dailyTasks {
                modelContext.delete(record)
            }
            for record in queries.weeklyTemplates {
                modelContext.delete(record)
            }
            for record in queries.userProfiles {
                modelContext.delete(record)
            }
            
            try? modelContext.save()
        }
    }
    
    static func deleteWorkoutRecords(
        workoutRecords: [WorkoutRecord],
        modelContext: ModelContext
    ) {
        withAnimation {
            for record in workoutRecords {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    static func deleteFTPHistory(
        ftpHistory: [FTPHistory],
        modelContext: ModelContext
    ) {
        withAnimation {
            for record in ftpHistory {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    static func deleteDailyMetrics(
        validDailyMetrics: [DailyMetric],
        modelContext: ModelContext
    ) {
        withAnimation {
            // Only delete metrics with actual data
            for record in validDailyMetrics {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    static func deleteDailyTasks(
        dailyTasks: [DailyTask],
        modelContext: ModelContext
    ) {
        withAnimation {
            for record in dailyTasks {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    static func deleteWeeklyTemplates(
        weeklyTemplates: [WeeklyTemplate],
        modelContext: ModelContext
    ) {
        withAnimation {
            for record in weeklyTemplates {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    static func deleteUserProfiles(
        userProfiles: [UserProfile],
        modelContext: ModelContext
    ) {
        withAnimation {
            for record in userProfiles {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    // MARK: - Demo Data Operations
    
    static func generateDemoData(modelContext: ModelContext) {
        // DemoDataManager は簡単化のため無効化
        Logger.debug.debug("Demo data generation disabled for simplified build")
    }
}