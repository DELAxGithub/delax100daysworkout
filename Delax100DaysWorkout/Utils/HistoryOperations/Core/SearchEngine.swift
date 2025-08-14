import Foundation

// MARK: - Core Search Engine

class SearchEngine<T: Searchable> {
    
    static func searchMatches(record: T, searchText: String) -> Bool {
        let searchTerms = searchText.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let searchableContent = record.searchableText.lowercased()
        
        // Check if all search terms are found
        return searchTerms.allSatisfy { term in
            searchableContent.contains(term) || 
            NumericMatcher.isMatch(term: term, value: record.searchableValue) ||
            DateMatcher.isMatch(term: term, date: record.searchableDate)
        }
    }
}

// MARK: - Numeric Matcher

struct NumericMatcher {
    static func isMatch(term: String, value: Double) -> Bool {
        // Try to parse search term as number
        if let searchValue = Double(term) {
            let tolerance = max(1.0, value * 0.05) // 5% tolerance or minimum 1.0
            return abs(value - searchValue) <= tolerance
        }
        return false
    }
}

// MARK: - Date Matcher

struct DateMatcher {
    static func isMatch(term: String, date: Date) -> Bool {
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
}