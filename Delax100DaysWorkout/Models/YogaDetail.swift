import Foundation
import SwiftData

@Model
final class YogaDetail {
    var duration: Int
    var yogaStyle: YogaStyle
    var poses: [String]
    var breathingTechnique: String?
    var flexibility: Double?
    var balance: Double?
    var mindfulness: Double?
    var meditation: Bool
    var notes: String?
    
    init(duration: Int = 0, yogaStyle: YogaStyle = .hatha, poses: [String] = [],
         breathingTechnique: String? = nil, flexibility: Double? = nil, 
         balance: Double? = nil, mindfulness: Double? = nil, 
         meditation: Bool = false, notes: String? = nil) {
        self.duration = duration
        self.yogaStyle = yogaStyle
        self.poses = poses
        self.breathingTechnique = breathingTechnique
        self.flexibility = flexibility
        self.balance = balance
        self.mindfulness = mindfulness
        self.meditation = meditation
        self.notes = notes
    }
    
    var wellnessScore: Double {
        let flexScore = flexibility ?? 0
        let balanceScore = balance ?? 0
        let mindScore = mindfulness ?? 0
        return (flexScore + balanceScore + mindScore) / 3
    }
    
    var totalPoses: Int {
        return poses.count
    }
}

enum YogaStyle: String, Codable, CaseIterable {
    case hatha = "Hatha"
    case vinyasa = "Vinyasa"
    case ashtanga = "Ashtanga"
    case bikram = "Bikram"
    case yin = "Yin"
    case restorative = "Restorative"
    case kundalini = "Kundalini"
    case power = "Power"
}