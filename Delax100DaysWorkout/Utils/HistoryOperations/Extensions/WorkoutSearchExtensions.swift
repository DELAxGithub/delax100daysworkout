import Foundation

extension WorkoutRecord {
    
    /// Workout Record SearchableString extension
    var searchableString: String {
        var components = [
            workoutType.rawValue,
            summary,
            date.formatted(.dateTime.day().month().year()),
            isCompleted ? "完了" : "未完了"
        ]
        
        // Add cycling details if available
        if let cyclingData = cyclingData {
            components.append(contentsOf: [
                cyclingData.zone.rawValue,
                "\(cyclingData.duration)分",
                cyclingData.power != nil ? "\(cyclingData.power!)W" : ""
            ])
        }
        
        // Add strength details if available
        if let strengthData = strengthData {
            let groupName = strengthData.customName ?? strengthData.muscleGroup.displayName
            components.append(contentsOf: [
                groupName,
                "\(strengthData.sets)セット",
                "\(strengthData.reps)回",
                "\(strengthData.weight)kg"
            ])
        }
        
        // Add flexibility details if available
        if let flexibilityData = flexibilityData {
            components.append(contentsOf: [
                flexibilityData.type.displayName,
                "\(flexibilityData.duration)分間"
            ])
            
            if let measurement = flexibilityData.measurement {
                let unit = flexibilityData.type == .forwardBend ? "cm" : "°"
                components.append("\(measurement)\(unit)")
            }
        }
        
        return components.joined(separator: " ")
    }
    
    /// Returns the primary measurement value for this workout
    var primaryMeasurement: Double {
        switch workoutType {
        case .cycling:
            return Double(cyclingData?.duration ?? 0)
        case .strength:
            return strengthData?.weight ?? 0.0
        case .flexibility, .pilates, .yoga:
            return flexibilityData?.measurement ?? Double(flexibilityData?.duration ?? 0)
        }
    }
    
    /// Returns a localized type name for display
    var localizedWorkoutType: String {
        switch workoutType {
        case .cycling: return "サイクリング"
        case .strength: return "筋力トレーニング"
        case .flexibility, .pilates, .yoga: return "柔軟性トレーニング"
        }
    }
}