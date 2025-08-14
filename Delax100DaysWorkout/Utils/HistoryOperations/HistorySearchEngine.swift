import SwiftUI
import SwiftData
import Foundation

// MARK: - Main History Search Engine (Orchestrator)

class HistorySearchEngine<T: Searchable> {
    
    // MARK: - Primary Search Interface
    
    static func filterRecords(
        _ records: [T],
        searchText: String,
        sortOption: HistorySearchConfiguration.SortOption
    ) -> [T] {
        // Apply search filter
        let filteredRecords = HistoryFilterEngine.filterRecords(records, searchText: searchText)
        
        // Apply sorting
        return SortEngine.applySorting(filteredRecords, sortOption: sortOption)
    }
    
    // MARK: - Advanced Search Methods
    
    static func searchWithCustomPredicate(
        _ records: [T],
        predicate: (T) -> Bool,
        sortOption: HistorySearchConfiguration.SortOption = .dateNewest
    ) -> [T] {
        let filteredRecords = HistoryFilterEngine.filterRecordsWithCustomPredicate(records, predicate: predicate)
        return SortEngine.applySorting(filteredRecords, sortOption: sortOption)
    }
    
    static func searchWithDateRange(
        _ records: [T],
        startDate: Date,
        endDate: Date,
        sortOption: HistorySearchConfiguration.SortOption = .dateNewest
    ) -> [T] {
        let filteredRecords = records.filter { record in
            record.searchableDate >= startDate && record.searchableDate <= endDate
        }
        return SortEngine.applySorting(filteredRecords, sortOption: sortOption)
    }
    
    static func searchWithValueRange(
        _ records: [T],
        minValue: Double,
        maxValue: Double,
        sortOption: HistorySearchConfiguration.SortOption = .valueHighest
    ) -> [T] {
        let filteredRecords = records.filter { record in
            record.searchableValue >= minValue && record.searchableValue <= maxValue
        }
        return SortEngine.applySorting(filteredRecords, sortOption: sortOption)
    }
}

#Preview {
    Text("History Search Engine - Modular Version")
        .font(.headline)
        .foregroundColor(.primary)
}