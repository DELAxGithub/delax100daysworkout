import Foundation
import SwiftData

@Model
final class DailyTask {
    var dayOfWeek: Int  // 0=日曜, 1=月曜...6=土曜
    var workoutType: WorkoutType
    var title: String
    var taskDescription: String?
    var targetDetailsData: Data?  // TargetDetailsをData型で保存
    var isFlexible: Bool = false
    var sortOrder: Int = 0
    
    // リレーション
    @Relationship(inverse: \WeeklyTemplate.dailyTasks)
    var template: WeeklyTemplate?
    
    var targetDetails: TargetDetails? {
        get {
            guard let data = targetDetailsData else { return nil }
            return try? JSONDecoder().decode(TargetDetails.self, from: data)
        }
        set {
            targetDetailsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(dayOfWeek: Int, workoutType: WorkoutType, title: String, description: String? = nil, targetDetails: TargetDetails? = nil, isFlexible: Bool = false, sortOrder: Int = 0) {
        self.dayOfWeek = dayOfWeek
        self.workoutType = workoutType
        self.title = title
        self.taskDescription = description
        self.targetDetails = targetDetails
        self.isFlexible = isFlexible
        self.sortOrder = sortOrder
    }
    
    var dayName: String {
        let days = ["日", "月", "火", "水", "木", "金", "土"]
        return days[dayOfWeek]
    }
    
    var icon: String {
        workoutType.iconName
    }
    
    func adjustedForPerformance(recentAverage: Double) -> DailyTask {
        guard isFlexible else { return self }
        
        // パフォーマンスに基づいて目標を調整
        let adjustedTask = DailyTask(
            dayOfWeek: dayOfWeek,
            workoutType: workoutType,
            title: title,
            description: taskDescription,
            targetDetails: targetDetails,
            isFlexible: isFlexible
        )
        
        // 例：サイクリングの場合、パワーを調整
        if workoutType == .cycling, var details = targetDetails {
            if let currentPower = details.targetPower {
                details.targetPower = Int(Double(currentPower) * (1 + (recentAverage - 1) * 0.05))
                adjustedTask.targetDetails = details
            }
        }
        
        return adjustedTask
    }
}