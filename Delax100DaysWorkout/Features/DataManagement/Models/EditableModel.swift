import SwiftUI

// MARK: - Editable Model Enum

enum EditableModel: String, CaseIterable {
    case workoutRecords = "WorkoutRecords"
    case ftpHistory = "FTPHistory"
    case dailyMetrics = "DailyMetrics"
    case dailyTasks = "DailyTasks"
    case weeklyTemplates = "WeeklyTemplates"
    case userProfiles = "UserProfiles"
    
    var displayName: String {
        switch self {
        case .workoutRecords: return "ワークアウト記録"
        case .ftpHistory: return "FTP記録"
        case .dailyMetrics: return "体重・メトリクス"
        case .dailyTasks: return "タスク記録"
        case .weeklyTemplates: return "週間テンプレート"
        case .userProfiles: return "ユーザープロファイル"
        }
    }
    
    var iconName: String {
        switch self {
        case .workoutRecords: return "figure.run"
        case .ftpHistory: return "bolt.fill"
        case .dailyMetrics: return "scalemass.fill"
        case .dailyTasks: return "checkmark.circle.fill"
        case .weeklyTemplates: return "calendar"
        case .userProfiles: return "person.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .workoutRecords: return .green
        case .ftpHistory: return .blue
        case .dailyMetrics: return .orange
        case .dailyTasks: return .purple
        case .weeklyTemplates: return .indigo
        case .userProfiles: return .pink
        }
    }
}

extension EditableModel: Identifiable {
    var id: String { rawValue }
}