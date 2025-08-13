import Foundation
import SwiftData
import SwiftUI

enum WorkoutType: String, Codable, CaseIterable {
    case cycling = "Cycling"
    case strength = "Strength"
    case flexibility = "Flexibility"
    case pilates = "Pilates"
    case yoga = "Yoga"

    var iconName: String {
        switch self {
        case .cycling:
            return "bicycle"
        case .strength:
            return "figure.strengthtraining.traditional"
        case .flexibility:
            return "figure.flexibility"
        case .pilates:
            return "figure.pilates"
        case .yoga:
            return "figure.yoga"
        }
    }

    var iconColor: Color {
        switch self {
        case .cycling: return .blue
        case .strength: return .orange
        case .flexibility: return .green
        case .pilates: return .purple
        case .yoga: return .mint
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
    
    @Relationship(deleteRule: .cascade)
    var cyclingDetail: CyclingDetail?
    
    @Relationship(deleteRule: .cascade)
    var strengthDetails: [StrengthDetail]?
    
    @Relationship(deleteRule: .cascade)
    var flexibilityDetail: FlexibilityDetail?
    
    @Relationship(deleteRule: .cascade)
    var pilatesDetail: PilatesDetail?
    
    @Relationship(deleteRule: .cascade)
    var yogaDetail: YogaDetail?
    
    var templateTask: DailyTask?
    
    init(date: Date, workoutType: WorkoutType, summary: String, isQuickRecord: Bool = false) {
        self.date = date
        self.workoutType = workoutType
        self.summary = summary
        self.isQuickRecord = isQuickRecord
    }
    
    func markAsCompleted(modelContext: ModelContext? = nil) {
        self.isCompleted = true
        
        // カウンターを自動更新
        if let context = modelContext {
            Task {
                await MainActor.run {
                    TaskCounterService.shared.incrementCounter(for: self, in: context)
                }
            }
        }
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