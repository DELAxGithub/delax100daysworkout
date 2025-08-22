import Foundation

struct TargetDetails: Codable {
    // サイクリング用
    var duration: Int?
    var intensity: CyclingZone?
    var targetPower: Int?
    var targetHeartRate: Int?     // 目標心拍数
    var averageHeartRate: Int?    // 実測平均心拍数
    var wattsPerBpm: Double?      // ワットパー心拍
    
    // 筋トレ用
    var targetMuscleGroup: WorkoutMuscleGroup?
    var targetSets: Int?
    var targetReps: Int?
    var targetWeight: Double?
    
    // 柔軟性用
    var targetDuration: Int?
    var targetForwardBend: Double?
    var targetSplitAngle: Double?
    
    init() {}
}