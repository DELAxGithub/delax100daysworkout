import Foundation

// MARK: - Sort Engine

class SortEngine<T: Searchable> {
    
    static func applySorting(
        _ records: [T],
        sortOption: HistorySearchConfiguration.SortOption
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
    
    static func customSort<U: Comparable>(
        _ records: [T],
        by keyPath: KeyPath<T, U>,
        ascending: Bool = true
    ) -> [T] {
        return records.sorted { first, second in
            let firstValue = first[keyPath: keyPath]
            let secondValue = second[keyPath: keyPath]
            return ascending ? firstValue < secondValue : firstValue > secondValue
        }
    }
}