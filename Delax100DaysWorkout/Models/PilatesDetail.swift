import Foundation
import SwiftData

@Model
final class PilatesDetail {
    var duration: Int
    var exerciseType: String
    var repetitions: Int?
    var holdTime: Int?
    var difficulty: PilatesDifficulty
    var coreEngagement: Double?
    var posturalAlignment: Double?
    var breathControl: Double?
    var notes: String?
    
    init(duration: Int = 0, exerciseType: String = "", repetitions: Int? = nil, 
         holdTime: Int? = nil, difficulty: PilatesDifficulty = .beginner,
         coreEngagement: Double? = nil, posturalAlignment: Double? = nil, 
         breathControl: Double? = nil, notes: String? = nil) {
        self.duration = duration
        self.exerciseType = exerciseType
        self.repetitions = repetitions
        self.holdTime = holdTime
        self.difficulty = difficulty
        self.coreEngagement = coreEngagement
        self.posturalAlignment = posturalAlignment
        self.breathControl = breathControl
        self.notes = notes
    }
    
    var intensityScore: Double {
        let coreScore = coreEngagement ?? 0
        let posturalScore = posturalAlignment ?? 0
        let breathScore = breathControl ?? 0
        return (coreScore + posturalScore + breathScore) / 3
    }
}

enum PilatesDifficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}