import SwiftData
import Foundation

// MARK: - Optimized FTP Query

struct OptimizedFTPQuery {
    
    static func createOptimizedDescriptor(
        searchText: String = "",
        sortOption: HistorySearchConfiguration.SortOption = .dateNewest
    ) -> FetchDescriptor<FTPHistory> {
        
        var descriptor = FetchDescriptor<FTPHistory>()
        
        // Apply sorting at database level for better performance
        switch sortOption {
        case .dateNewest:
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        case .dateOldest:
            descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        case .valueHighest:
            descriptor.sortBy = [SortDescriptor(\.ftpValue, order: .reverse)]
        case .valueLowest:
            descriptor.sortBy = [SortDescriptor(\.ftpValue, order: .forward)]
        }
        
        // Add predicate for basic filtering if possible
        if !searchText.isEmpty, let ftpValue = Int(searchText) {
            descriptor.predicate = #Predicate<FTPHistory> { ftp in
                ftp.ftpValue == ftpValue
            }
        }
        
        // Limit results for performance
        descriptor.fetchLimit = 1000
        
        return descriptor
    }
}

// MARK: - DailyMetric Optimized Queries

struct OptimizedDailyMetricQuery {
    
    static func createOptimizedDescriptor(
        searchText: String = "",
        sortOption: HistorySearchConfiguration.SortOption = .dateNewest
    ) -> FetchDescriptor<DailyMetric> {
        
        var descriptor = FetchDescriptor<DailyMetric>()
        
        // Apply sorting at database level for better performance
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
        
        // Add predicate for basic filtering if possible
        if !searchText.isEmpty {
            // Try to parse as weight value
            if let weightValue = Double(searchText) {
                descriptor.predicate = #Predicate<DailyMetric> { metric in
                    metric.weightKg == weightValue
                }
            }
            // Try to parse as heart rate
            else if let hrValue = Int(searchText) {
                descriptor.predicate = #Predicate<DailyMetric> { metric in
                    metric.restingHeartRate == hrValue || metric.maxHeartRate == hrValue
                }
            }
        }
        
        // Only include metrics with actual data
        if descriptor.predicate == nil {
            descriptor.predicate = #Predicate<DailyMetric> { metric in
                metric.weightKg != nil || metric.restingHeartRate != nil || metric.maxHeartRate != nil
            }
        }
        
        // Limit results for performance
        descriptor.fetchLimit = 1000
        
        return descriptor
    }
}

// MARK: - Workout Record Optimized Queries

struct OptimizedWorkoutQuery {
    
    static func createOptimizedDescriptor(
        searchText: String = "",
        sortOption: HistorySearchConfiguration.SortOption = .dateNewest
    ) -> FetchDescriptor<WorkoutRecord> {
        
        var descriptor = FetchDescriptor<WorkoutRecord>()
        
        // Apply sorting at database level for better performance
        switch sortOption {
        case .dateNewest:
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        case .dateOldest:
            descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        case .valueHighest:
            // For WorkoutRecord, we'll sort by summary alphabetically as a proxy for "value"
            descriptor.sortBy = [SortDescriptor(\.summary, order: .reverse)]
        case .valueLowest:
            descriptor.sortBy = [SortDescriptor(\.summary, order: .forward)]
        }
        
        // Add predicate for basic filtering if possible
        if !searchText.isEmpty {
            // Try to filter by workout type or completion status first
            let lowerSearchText = searchText.lowercased()
            
            if lowerSearchText.contains("完了") {
                descriptor.predicate = #Predicate<WorkoutRecord> { workout in
                    workout.isCompleted == true
                }
            } else if lowerSearchText.contains("未完了") {
                descriptor.predicate = #Predicate<WorkoutRecord> { workout in
                    workout.isCompleted == false
                }
            } else {
                // Basic text search on summary - avoid complex enum comparisons in Predicate
                descriptor.predicate = #Predicate<WorkoutRecord> { workout in
                    workout.summary.localizedStandardContains(searchText)
                }
            }
        }
        
        // Limit results for performance
        descriptor.fetchLimit = 1000
        
        return descriptor
    }
}