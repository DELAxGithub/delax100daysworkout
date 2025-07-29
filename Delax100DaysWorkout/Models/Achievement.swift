import Foundation
import SwiftData

enum AchievementType: String, Codable {
    case personalRecord = "PR"
    case streak = "連続記録"
    case milestone = "マイルストーン"
    case improvement = "改善"
}

@Model
final class Achievement {
    var type: AchievementType
    var title: String
    var achievementDescription: String
    var date: Date
    var workoutType: WorkoutType?
    var value: String?
    var badgeEmoji: String
    
    init(type: AchievementType, title: String, description: String, workoutType: WorkoutType? = nil, value: String? = nil) {
        self.type = type
        self.title = title
        self.achievementDescription = description
        self.date = Date()
        self.workoutType = workoutType
        self.value = value
        
        // タイプに基づいてバッジを設定
        switch type {
        case .personalRecord:
            self.badgeEmoji = "🏆"
        case .streak:
            self.badgeEmoji = "🔥"
        case .milestone:
            self.badgeEmoji = "🎯"
        case .improvement:
            self.badgeEmoji = "📈"
        }
    }
    
    static func checkForPR(newRecord: WorkoutRecord, history: [WorkoutRecord]) -> Achievement? {
        guard newRecord.workoutType == .strength,
              let details = newRecord.strengthDetails,
              !details.isEmpty else { return nil }
        
        // 各エクササイズでPRをチェック
        for detail in details {
            let previousMax = history
                .filter { $0.workoutType == .strength }
                .compactMap { $0.strengthDetails }
                .flatMap { $0 }
                .filter { $0.exercise == detail.exercise }
                .map { $0.weight }
                .max() ?? 0
            
            if detail.weight > previousMax && previousMax > 0 {
                return Achievement(
                    type: .personalRecord,
                    title: "新記録達成！",
                    description: "\(detail.exercise)で\(detail.weight)kg達成",
                    workoutType: .strength,
                    value: "\(detail.weight)kg"
                )
            }
        }
        
        return nil
    }
    
    static func checkForStreak(records: [WorkoutRecord], targetDays: Int = 7) -> Achievement? {
        let sortedRecords = records.sorted { $0.date > $1.date }
        var streakDays = 0
        var lastDate = Date()
        
        for record in sortedRecords {
            let daysDiff = Calendar.current.dateComponents([.day], from: record.date, to: lastDate).day ?? 0
            
            if daysDiff <= 1 {
                streakDays += 1
                lastDate = record.date
            } else {
                break
            }
        }
        
        if streakDays == targetDays {
            return Achievement(
                type: .streak,
                title: "\(targetDays)日連続達成！",
                description: "素晴らしい継続力です",
                value: "\(targetDays)日"
            )
        }
        
        return nil
    }
    
    static func checkForFlexibilityImprovement(current: FlexibilityDetail?, previous: [FlexibilityDetail]) -> Achievement? {
        guard let current = current,
              let previousBest = previous.map({ $0.averageSplitAngle }).max(),
              current.averageSplitAngle > previousBest + 10 else { return nil }
        
        return Achievement(
            type: .improvement,
            title: "柔軟性向上！",
            description: "開脚角度が\(Int(current.averageSplitAngle))度に到達",
            workoutType: .flexibility,
            value: "\(Int(current.averageSplitAngle))度"
        )
    }
}