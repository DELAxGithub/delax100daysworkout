import SwiftData
import Foundation

// MARK: - Additional Optimized Queries

struct OptimizedDailyLogQuery {
    static func createOptimizedDescriptor(
        searchText: String = "",
        sortOption: HistorySearchConfiguration.SortOption = .dateNewest
    ) -> FetchDescriptor<DailyLog> {
        var descriptor = FetchDescriptor<DailyLog>()
        
        switch sortOption {
        case .dateNewest:
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        case .dateOldest:
            descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        case .valueHighest:
            descriptor.sortBy = [SortDescriptor(\.weightKg, order: .reverse)]
        case .valueLowest:
            descriptor.sortBy = [SortDescriptor(\.weightKg, order: .forward)]
        }
        
        if !searchText.isEmpty, let weightValue = Double(searchText) {
            descriptor.predicate = #Predicate<DailyLog> { log in
                log.weightKg == weightValue
            }
        }
        
        descriptor.fetchLimit = 1000
        return descriptor
    }
}

struct OptimizedAchievementQuery {
    static func createOptimizedDescriptor(
        searchText: String = "",
        sortOption: HistorySearchConfiguration.SortOption = .dateNewest
    ) -> FetchDescriptor<Achievement> {
        var descriptor = FetchDescriptor<Achievement>()
        
        switch sortOption {
        case .dateNewest:
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        case .dateOldest:
            descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        case .valueHighest:
            descriptor.sortBy = [SortDescriptor(\.title, order: .reverse)]
        case .valueLowest:
            descriptor.sortBy = [SortDescriptor(\.title, order: .forward)]
        }
        
        if !searchText.isEmpty {
            descriptor.predicate = #Predicate<Achievement> { achievement in
                achievement.title.localizedStandardContains(searchText) ||
                achievement.achievementDescription.localizedStandardContains(searchText)
            }
        }
        
        descriptor.fetchLimit = 1000
        return descriptor
    }
}

struct OptimizedWeeklyReportQuery {
    static func createOptimizedDescriptor(
        searchText: String = "",
        sortOption: HistorySearchConfiguration.SortOption = .dateNewest
    ) -> FetchDescriptor<WeeklyReport> {
        var descriptor = FetchDescriptor<WeeklyReport>()
        
        switch sortOption {
        case .dateNewest:
            descriptor.sortBy = [SortDescriptor(\.weekStartDate, order: .reverse)]
        case .dateOldest:
            descriptor.sortBy = [SortDescriptor(\.weekStartDate, order: .forward)]
        case .valueHighest:
            descriptor.sortBy = [SortDescriptor(\.cyclingCompleted, order: .reverse)]
        case .valueLowest:
            descriptor.sortBy = [SortDescriptor(\.cyclingCompleted, order: .forward)]
        }
        
        if !searchText.isEmpty {
            descriptor.predicate = #Predicate<WeeklyReport> { report in
                report.summary.localizedStandardContains(searchText)
            }
        }
        
        descriptor.fetchLimit = 1000
        return descriptor
    }
}

struct OptimizedTrainingSavingsQuery {
    static func createOptimizedDescriptor(
        searchText: String = "",
        sortOption: HistorySearchConfiguration.SortOption = .dateNewest
    ) -> FetchDescriptor<TrainingSavings> {
        var descriptor = FetchDescriptor<TrainingSavings>()
        
        switch sortOption {
        case .dateNewest:
            descriptor.sortBy = [SortDescriptor(\.lastUpdated, order: .reverse)]
        case .dateOldest:
            descriptor.sortBy = [SortDescriptor(\.lastUpdated, order: .forward)]
        case .valueHighest:
            descriptor.sortBy = [SortDescriptor(\.currentCount, order: .reverse)]
        case .valueLowest:
            descriptor.sortBy = [SortDescriptor(\.currentCount, order: .forward)]
        }
        
        if !searchText.isEmpty, let count = Int(searchText) {
            descriptor.predicate = #Predicate<TrainingSavings> { savings in
                savings.currentCount == count
            }
        }
        
        descriptor.fetchLimit = 1000
        return descriptor
    }
}