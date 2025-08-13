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
    
    // ピラティス用
    var exerciseType: String?
    var repetitions: Int?
    var holdTime: Int?
    var difficulty: PilatesDifficulty?
    var coreEngagement: Double?
    var posturalAlignment: Double?
    var breathControl: Double?
    
    // ヨガ用
    var yogaStyle: YogaStyle?
    var poses: [String]?
    var breathingTechnique: String?
    var flexibility: Double?
    var balance: Double?
    var mindfulness: Double?
    var meditation: Bool?
    
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
    
    // ピラティス用イニシャライザ
    init(
        targetDuration: Int,
        exerciseType: String? = nil,
        repetitions: Int? = nil,
        holdTime: Int? = nil,
        difficulty: PilatesDifficulty? = nil,
        coreEngagement: Double? = nil,
        posturalAlignment: Double? = nil,
        breathControl: Double? = nil
    ) {
        self.targetDuration = targetDuration
        self.exerciseType = exerciseType
        self.repetitions = repetitions
        self.holdTime = holdTime
        self.difficulty = difficulty
        self.coreEngagement = coreEngagement
        self.posturalAlignment = posturalAlignment
        self.breathControl = breathControl
    }
    
    // ヨガ用イニシャライザ
    init(
        targetDuration: Int,
        yogaStyle: YogaStyle? = nil,
        poses: [String]? = nil,
        breathingTechnique: String? = nil,
        flexibility: Double? = nil,
        balance: Double? = nil,
        mindfulness: Double? = nil,
        meditation: Bool? = nil
    ) {
        self.targetDuration = targetDuration
        self.yogaStyle = yogaStyle
        self.poses = poses
        self.breathingTechnique = breathingTechnique
        self.flexibility = flexibility
        self.balance = balance
        self.mindfulness = mindfulness
        self.meditation = meditation
    }
}