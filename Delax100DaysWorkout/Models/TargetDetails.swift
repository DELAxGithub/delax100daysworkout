import Foundation

struct TargetDetails: Codable {
    // サイクリング用
    var duration: Int?
    var intensity: CyclingIntensity?
    var targetPower: Int?
    
    // 筋トレ用
    var exercises: [String]?
    var targetSets: Int?
    var targetReps: Int?
    
    // 柔軟性用
    var targetDuration: Int?
    var targetForwardBend: Double?
    var targetSplitAngle: Double?
    
    init() {}
    
    // サイクリング用イニシャライザ
    init(duration: Int, intensity: CyclingIntensity, targetPower: Int? = nil) {
        self.duration = duration
        self.intensity = intensity
        self.targetPower = targetPower
    }
    
    // 筋トレ用イニシャライザ
    init(exercises: [String], targetSets: Int = 3, targetReps: Int = 10) {
        self.exercises = exercises
        self.targetSets = targetSets
        self.targetReps = targetReps
    }
    
    // 柔軟性用イニシャライザ
    init(targetDuration: Int, targetForwardBend: Double? = nil, targetSplitAngle: Double? = nil) {
        self.targetDuration = targetDuration
        self.targetForwardBend = targetForwardBend
        self.targetSplitAngle = targetSplitAngle
    }
}