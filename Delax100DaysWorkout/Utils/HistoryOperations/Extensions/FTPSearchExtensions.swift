import Foundation

// MARK: - FTP History Search Extension

extension FTPHistory: Searchable {
    var searchableText: String {
        var components = [
            "\(ftpValue)",
            methodDisplayText,
            searchFormattedDate
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
    
    private var searchFormattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}