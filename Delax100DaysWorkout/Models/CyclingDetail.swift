import Foundation
import SwiftData

enum CyclingIntensity: String, Codable, CaseIterable {
    case recovery = "Recovery"
    case z2 = "Zone2"
    case endurance = "Endurance"
    case tempo = "Tempo"
    case sst = "SST"
    case vo2max = "VO2 Max"
    case anaerobic = "Anaerobic"
    case sprint = "Sprint"
    
    var description: String {
        switch self {
        case .recovery: return "リカバリー"
        case .z2: return "Z2 脂肪燃焼"
        case .endurance: return "エンデュランス"
        case .tempo: return "テンポ"
        case .sst: return "SST"
        case .vo2max: return "VO2 Max"
        case .anaerobic: return "アナエロビック"
        case .sprint: return "スプリント"
        }
    }
}

@Model
final class CyclingDetail {
    var distance: Double
    var duration: Int
    var averagePower: Double
    var intensity: CyclingIntensity
    var notes: String?
    
    init(distance: Double = 0, duration: Int = 0, averagePower: Double = 0, intensity: CyclingIntensity = .endurance, notes: String? = nil) {
        self.distance = distance
        self.duration = duration
        self.averagePower = averagePower
        self.intensity = intensity
        self.notes = notes
    }
}