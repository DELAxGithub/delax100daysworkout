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
    
    /// 動的に生成される表示用タイトル
    var displayTitle: String {
        guard let details = targetDetails else { return title }
        
        switch workoutType {
        case .cycling:
            if let intensity = details.intensity {
                if let duration = details.duration {
                    return "\(intensity.shortDisplayName) \(duration)分"
                } else {
                    return "\(intensity.displayName)"
                }
            }
            return title
            
        case .strength:
            if let exercises = details.exercises, !exercises.isEmpty {
                let exerciseName = exercises.first ?? "筋トレ"
                if let sets = details.targetSets, let reps = details.targetReps {
                    return "\(exerciseName) \(sets)×\(reps)"
                } else {
                    return exerciseName
                }
            }
            return title
            
        case .flexibility, .pilates, .yoga:
            if let duration = details.targetDuration {
                if workoutType == .flexibility {
                    if details.targetForwardBend != nil || details.targetSplitAngle != nil {
                        return "柔軟・測定 \(duration)分"
                    } else {
                        return "ストレッチ \(duration)分"
                    }
                } else {
                    return "\(workoutType == .pilates ? "ピラティス" : "ヨガ") \(duration)分"
                }
            }
            return title
        }
    }
    
    /// 表示用サブタイトル（詳細情報）
    var displaySubtitle: String? {
        guard let details = targetDetails else { return taskDescription }
        
        switch workoutType {
        case .cycling:
            var components: [String] = []
            
            if let power = details.targetPower, power > 0 {
                components.append("\(power)W")
            }
            
            if let heartRate = details.averageHeartRate, heartRate > 0 {
                components.append("\(heartRate)bpm")
            }
            
            if let wattsPerBpm = details.wattsPerBpm {
                components.append(String(format: "%.2f W/bpm", wattsPerBpm))
            }
            
            if let intensity = details.intensity {
                components.append(intensity.displayName)
            }
            
            return components.isEmpty ? taskDescription : components.joined(separator: " • ")
            
        case .strength:
            var components: [String] = []
            
            if let exercises = details.exercises, exercises.count > 1 {
                components.append("\(exercises.count)種目")
            }
            
            // 筋群や部位の情報があれば追加
            if let description = taskDescription, !description.contains("クイック記録") {
                components.append(description)
            }
            
            return components.isEmpty ? nil : components.joined(separator: " • ")
            
        case .flexibility, .pilates, .yoga:
            var components: [String] = []
            
            if let forwardBend = details.targetForwardBend, forwardBend > 0 {
                components.append("前屈 \(Int(forwardBend))cm")
            }
            
            if let splitAngle = details.targetSplitAngle, splitAngle > 0 {
                components.append("開脚 \(Int(splitAngle))°")
            }
            
            if components.isEmpty, let description = taskDescription, !description.contains("クイック記録") {
                return description
            }
            
            return components.isEmpty ? nil : components.joined(separator: " • ")
        }
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
    
    // MARK: - Migration Support
    
    /// 既存のpilates/yogaタスクをflexibilityに移行
    func migrateToFlexibility() {
        switch workoutType.rawValue {
        case "Pilates":
            workoutType = .flexibility
            if title.contains("ピラティス") == false {
                title = "ピラティス - \(title)"
            }
            
        case "Yoga":
            workoutType = .flexibility
            if title.contains("ヨガ") == false {
                title = "ヨガ - \(title)"
            }
            
        default:
            break
        }
    }
}