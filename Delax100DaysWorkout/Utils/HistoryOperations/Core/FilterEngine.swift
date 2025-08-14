import Foundation

// MARK: - History Filter Engine

class HistoryFilterEngine<T: Searchable> {
    
    static func filterRecords(
        _ records: [T],
        searchText: String
    ) -> [T] {
        // Apply search filter if search text is not empty
        if !searchText.isEmpty {
            return records.filter { record in
                SearchEngine.searchMatches(record: record, searchText: searchText)
            }
        }
        return records
    }
    
    static func filterRecordsWithCustomPredicate(
        _ records: [T],
        predicate: (T) -> Bool
    ) -> [T] {
        return records.filter(predicate)
    }
}