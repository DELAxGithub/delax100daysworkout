import Foundation
import SwiftData
import SwiftUI

enum WorkoutType: String, Codable, CaseIterable {
    case cycling = "Cycling"
    case strength = "Strength"
    case flexibility = "Flexibility"

    var iconName: String {
        switch self {
        case .cycling:
            return "bicycle"
        case .strength:
            return "figure.strengthtraining.traditional"
        case .flexibility:
            return "figure.flexibility"
        }
    }

    var iconColor: Color {
        switch self {
        case .cycling: return .blue
        case .strength: return .orange
        case .flexibility: return .green
        }
    }
}

@Model
final class WorkoutRecord {
    var date: Date
    var workoutType: WorkoutType
    var summary: String
    var isCompleted: Bool = false
    var isQuickRecord: Bool = false
    
    var cyclingDetail: CyclingDetail?
    var strengthDetails: [StrengthDetail]?
    var flexibilityDetail: FlexibilityDetail?
    var templateTask: DailyTask?
    
    init(date: Date, workoutType: WorkoutType, summary: String, isQuickRecord: Bool = false) {
        self.date = date
        self.workoutType = workoutType
        self.summary = summary
        self.isQuickRecord = isQuickRecord
    }
    
    func markAsCompleted() {
        self.isCompleted = true
    }
    
    static func fromDailyTask(_ task: DailyTask, date: Date = Date()) -> WorkoutRecord {
        let record = WorkoutRecord(
            date: date,
            workoutType: task.workoutType,
            summary: task.title,
            isQuickRecord: true
        )
        record.templateTask = task
        return record
    }
}