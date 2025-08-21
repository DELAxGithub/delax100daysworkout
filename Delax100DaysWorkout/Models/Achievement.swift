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
}