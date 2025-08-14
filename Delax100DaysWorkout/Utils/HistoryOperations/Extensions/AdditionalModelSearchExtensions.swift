import Foundation

// MARK: - DailyLog Search Extension

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

// MARK: - Achievement Search Extension

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

// MARK: - WeeklyReport Search Extension

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

// MARK: - TrainingSavings Search Extension

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