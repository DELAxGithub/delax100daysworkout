import SwiftUI
import SwiftData
import Foundation

// MARK: - Generic History Search Engine

protocol Searchable {
    var searchableText: String { get }
    var searchableDate: Date { get }
    var searchableValue: Double { get }
}

class HistorySearchEngine<T: Searchable> {
    
    // MARK: - Search Methods
    
    static func filterRecords(
        _ records: [T],
        searchText: String,
        sortOption: SearchConfiguration.SortOption
    ) -> [T] {
        var filteredRecords = records
        
        // Apply search filter if search text is not empty
        if !searchText.isEmpty {
            filteredRecords = records.filter { record in
                searchMatches(record: record, searchText: searchText)
            }
        }
        
        // Apply sorting
        return applySorting(filteredRecords, sortOption: sortOption)
    }
    
    private static func searchMatches(record: T, searchText: String) -> Bool {
        let searchTerms = searchText.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let searchableContent = record.searchableText.lowercased()
        
        // Check if all search terms are found
        return searchTerms.allSatisfy { term in
            searchableContent.contains(term) || 
            isNumericMatch(term: term, value: record.searchableValue) ||
            isDateMatch(term: term, date: record.searchableDate)
        }
    }
    
    private static func isNumericMatch(term: String, value: Double) -> Bool {
        // Try to parse search term as number
        if let searchValue = Double(term) {
            let tolerance = max(1.0, value * 0.05) // 5% tolerance or minimum 1.0
            return abs(value - searchValue) <= tolerance
        }
        return false
    }
    
    private static func isDateMatch(term: String, date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        // Try various date formats
        let formats = ["yyyy", "MM", "dd", "yyyy/MM", "MM/dd", "yyyy/MM/dd"]
        
        for format in formats {
            formatter.dateFormat = format
            let dateString = formatter.string(from: date)
            if dateString.lowercased().contains(term) {
                return true
            }
        }
        
        // Try month names in Japanese
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: date)
        if monthName.lowercased().contains(term) {
            return true
        }
        
        return false
    }
    
    private static func applySorting(
        _ records: [T],
        sortOption: SearchConfiguration.SortOption
    ) -> [T] {
        switch sortOption {
        case .dateNewest:
            return records.sorted { $0.searchableDate > $1.searchableDate }
        case .dateOldest:
            return records.sorted { $0.searchableDate < $1.searchableDate }
        case .valueHighest:
            return records.sorted { $0.searchableValue > $1.searchableValue }
        case .valueLowest:
            return records.sorted { $0.searchableValue < $1.searchableValue }
        }
    }
}

// MARK: - FTP History Search Extension

extension FTPHistory: Searchable {
    var searchableText: String {
        var components = [
            "\(ftpValue)",
            methodDisplayText,
            formattedDate
        ]
        
        if let notes = notes, !notes.isEmpty {
            components.append(notes)
        }
        
        return components.joined(separator: " ")
    }
    
    var searchableDate: Date {
        return date
    }
    
    var searchableValue: Double {
        return Double(ftpValue)
    }
}

// MARK: - Workout Record Search Extension

extension WorkoutRecord: Searchable {
    var searchableText: String {
        var components = [
            summary,
            workoutType.rawValue,
            workoutType.description,
            formattedDate,
            isCompleted ? "完了" : "未完了"
        ]
        
        // Add cycling details if available
        if let cyclingDetail = cyclingDetail {
            components.append(contentsOf: [
                cyclingDetail.formattedDistance,
                cyclingDetail.formattedDuration,
                cyclingDetail.formattedAveragePower,
                cyclingDetail.intensity.rawValue,
                cyclingDetail.intensity.description
            ])
            
            if let notes = cyclingDetail.notes, !notes.isEmpty {
                components.append(notes)
            }
        }
        
        // Add strength details if available
        if let strengthDetails = strengthDetails {
            for detail in strengthDetails {
                components.append(contentsOf: [
                    detail.exercise,
                    "\(detail.sets)セット",
                    "\(detail.reps)回",
                    "\(detail.weight)kg"
                ])
                
                if let notes = detail.notes, !notes.isEmpty {
                    components.append(notes)
                }
            }
        }
        
        // Add flexibility details if available
        if let flexDetail = flexibilityDetail {
            components.append(contentsOf: [
                "前屈\(flexDetail.forwardBendDistance)cm",
                "左開脚\(flexDetail.leftSplitAngle)°",
                "右開脚\(flexDetail.rightSplitAngle)°",
                "前後開脚前\(flexDetail.frontSplitAngle)°",
                "前後開脚後\(flexDetail.backSplitAngle)°",
                "\(flexDetail.duration)分間"
            ])
            
            if let notes = flexDetail.notes, !notes.isEmpty {
                components.append(notes)
            }
        }
        
        return components.joined(separator: " ")
    }
    
    var searchableDate: Date {
        return date
    }
    
    var searchableValue: Double {
        // Return different values based on workout type for meaningful search
        switch workoutType {
        case .cycling:
            return cyclingDetail?.distance ?? 0.0
        case .strength:
            return Double(strengthDetails?.count ?? 0)
        case .flexibility:
            return flexibilityDetail?.forwardBendDistance ?? 0.0
        case .pilates, .yoga:
            return isCompleted ? 1.0 : 0.0
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

private extension WorkoutType {
    var description: String {
        switch self {
        case .cycling: return "サイクリング"
        case .strength: return "筋力トレーニング"
        case .flexibility: return "柔軟性"
        case .pilates: return "ピラティス"
        case .yoga: return "ヨガ"
        }
    }
}

// MARK: - Search Results View Model

@Observable
class HistorySearchViewModel<T: Searchable> {
    var searchText: String = ""
    var selectedSort: SearchConfiguration.SortOption = .dateNewest
    var isSearchActive: Bool = false
    
    private var allRecords: [T] = []
    
    var filteredRecords: [T] {
        return HistorySearchEngine.filterRecords(
            allRecords,
            searchText: searchText,
            sortOption: selectedSort
        )
    }
    
    var hasResults: Bool {
        return !filteredRecords.isEmpty
    }
    
    var searchResultsCount: Int {
        return filteredRecords.count
    }
    
    func updateRecords(_ records: [T]) {
        allRecords = records
    }
    
    func clearSearch() {
        searchText = ""
        isSearchActive = false
    }
    
    func activateSearch() {
        isSearchActive = !searchText.isEmpty
    }
}


// MARK: - Optimized SwiftData Queries

struct OptimizedFTPQuery {
    
    static func createOptimizedDescriptor(
        searchText: String = "",
        sortOption: SearchConfiguration.SortOption = .dateNewest
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
        sortOption: SearchConfiguration.SortOption = .dateNewest
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
        sortOption: SearchConfiguration.SortOption = .dateNewest
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

// MARK: - Additional Optimized Queries

struct OptimizedDailyLogQuery {
    static func createOptimizedDescriptor(
        searchText: String = "",
        sortOption: SearchConfiguration.SortOption = .dateNewest
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
        sortOption: SearchConfiguration.SortOption = .dateNewest
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
        sortOption: SearchConfiguration.SortOption = .dateNewest
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
        sortOption: SearchConfiguration.SortOption = .dateNewest
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

// MARK: - Additional Model Search Extensions

extension DailyLog: Searchable {
    var searchableText: String {
        var components = ["\(weightKg)kg"]
        
        // Add formatted date
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        components.append(formatter.string(from: date))
        
        return components.joined(separator: " ")
    }
    
    var searchableDate: Date {
        return date
    }
    
    var searchableValue: Double {
        return weightKg
    }
}

extension Achievement: Searchable {
    var searchableText: String {
        var components = [title, achievementDescription, type.rawValue]
        
        if let value = value, !value.isEmpty {
            components.append(value)
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        components.append(formatter.string(from: date))
        
        return components.joined(separator: " ")
    }
    
    var searchableDate: Date {
        return date
    }
    
    var searchableValue: Double {
        return 1.0 // Achievements don't have numeric values, use 1.0 as default
    }
}

extension WeeklyReport: Searchable {
    var searchableText: String {
        var components = [
            summary,
            "\(cyclingCompleted + strengthCompleted + flexibilityCompleted)回"
        ]
        
        // Add achievements
        for achievement in achievements {
            components.append(achievement)
        }
        
        // Add formatted date range
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "MM/dd"
        components.append("\(formatter.string(from: weekStartDate))-\(formatter.string(from: weekEndDate))")
        
        return components.joined(separator: " ")
    }
    
    var searchableDate: Date {
        return weekStartDate
    }
    
    var searchableValue: Double {
        return Double(cyclingCompleted + strengthCompleted + flexibilityCompleted)
    }
}

extension TrainingSavings: Searchable {
    var searchableText: String {
        var components = [
            savingsType.rawValue,
            savingsType.displayName,
            "\(currentCount)/\(targetCount)",
            "現在\(currentStreak)連続"
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        components.append(formatter.string(from: lastUpdated))
        
        return components.joined(separator: " ")
    }
    
    var searchableDate: Date {
        return lastUpdated
    }
    
    var searchableValue: Double {
        return Double(currentCount)
    }
}

#Preview {
    Text("History Search Engine Utility")
        .font(Typography.headlineLarge.font)
        .foregroundColor(SemanticColor.primaryText.color)
}