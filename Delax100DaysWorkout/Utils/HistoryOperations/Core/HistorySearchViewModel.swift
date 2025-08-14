import SwiftUI

// MARK: - Search Results View Model

@Observable
class HistorySearchViewModel<T: Searchable> {
    var searchText: String = ""
    var selectedSort: HistorySearchConfiguration.SortOption = .dateNewest
    var isSearchActive: Bool = false
    
    private var allRecords: [T] = []
    
    var filteredRecords: [T] {
        let filtered = HistoryFilterEngine.filterRecords(allRecords, searchText: searchText)
        return SortEngine.applySorting(filtered, sortOption: selectedSort)
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