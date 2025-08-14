import Foundation

// MARK: - Searchable Protocol

protocol Searchable {
    var searchableText: String { get }
    var searchableDate: Date { get }
    var searchableValue: Double { get }
}

// MARK: - History Search Configuration

struct HistorySearchConfiguration {
    enum SortOption: String, CaseIterable {
        case dateNewest = "dateNewest"
        case dateOldest = "dateOldest"
        case valueHighest = "valueHighest"
        case valueLowest = "valueLowest"
        
        var displayName: String {
            switch self {
            case .dateNewest: return "新しい順"
            case .dateOldest: return "古い順"
            case .valueHighest: return "値の大きい順"
            case .valueLowest: return "値の小さい順"
            }
        }
    }
}