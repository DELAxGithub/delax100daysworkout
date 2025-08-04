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
    
    // 新規追加フィールド（Phase 1: サイクリング集計機能）
    var averageHeartRate: Int?       // 平均心拍数
    var maxHeartRate: Int?           // 最大心拍数
    var maxPower: Double?            // 最大パワー
    var normalizedPower: Double?     // 正規化パワー（NP）
    var isFromHealthKit: Bool = false // Apple Healthから取得されたデータかどうか
    
    init(distance: Double = 0, 
         duration: Int = 0, 
         averagePower: Double = 0, 
         intensity: CyclingIntensity = .endurance, 
         notes: String? = nil,
         averageHeartRate: Int? = nil,
         maxHeartRate: Int? = nil,
         maxPower: Double? = nil,
         normalizedPower: Double? = nil,
         isFromHealthKit: Bool = false) {
        self.distance = distance
        self.duration = duration
        self.averagePower = averagePower
        self.intensity = intensity
        self.notes = notes
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.maxPower = maxPower
        self.normalizedPower = normalizedPower
        self.isFromHealthKit = isFromHealthKit
    }
    
    // MARK: - Computed Properties
    
    /// W/HR比（ワット/心拍比）- パワー効率の指標
    var whrRatio: Double? {
        get {
            guard let avgHR = averageHeartRate, avgHR > 0 else { return nil }
            return averagePower / Double(avgHR)
        }
    }
    
    /// Intensity Factor（IF）- FTPに対する強度比
    var intensityFactor: Double? {
        get {
            // TODO: FTPHistoryから最新のFTPを取得する
            // 暫定的に250Wを基準FTPとして使用
            let estimatedFTP = 250.0
            return (normalizedPower ?? averagePower) / estimatedFTP
        }
    }
    
    /// Training Stress Score（TSS）- トレーニング負荷スコア
    var trainingStressScore: Double? {
        get {
            guard let intensityFactor = intensityFactor, duration > 0 else { return nil }
            let hoursDecimal = Double(duration) / 3600.0
            return hoursDecimal * intensityFactor * intensityFactor * 100
        }
    }
    
    /// 平均速度（km/h）
    var averageSpeed: Double? {
        get {
            guard duration > 0 else { return nil }
            let hoursDecimal = Double(duration) / 3600.0
            return distance / hoursDecimal
        }
    }
    
    /// パワー密度（W/kg）- 体重との関係で計算（体重は別途取得）
    func powerToWeightRatio(weight: Double?) -> Double? {
        guard let weight = weight, weight > 0 else { return nil }
        return averagePower / weight
    }
    
    // MARK: - Formatted Strings
    
    var formattedDistance: String {
        return String(format: "%.1f km", distance)
    }
    
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedAveragePower: String {
        return String(format: "%.0f W", averagePower)
    }
    
    var formattedMaxPower: String? {
        guard let maxPower = maxPower else { return nil }
        return String(format: "%.0f W", maxPower)
    }
    
    var formattedAverageHeartRate: String? {
        guard let avgHR = averageHeartRate else { return nil }
        return "\(avgHR) bpm"
    }
    
    var formattedMaxHeartRate: String? {
        guard let maxHR = maxHeartRate else { return nil }
        return "\(maxHR) bpm"
    }
    
    var formattedWHRRatio: String? {
        guard let whr = whrRatio else { return nil }
        return String(format: "%.2f W/bpm", whr)
    }
    
    var formattedAverageSpeed: String? {
        guard let speed = averageSpeed else { return nil }
        return String(format: "%.1f km/h", speed)
    }
    
    // MARK: - Validation
    
    var isValidHeartRateData: Bool {
        if let avgHR = averageHeartRate {
            guard avgHR >= 60 && avgHR <= 200 else { return false }
        }
        
        if let maxHR = maxHeartRate {
            guard maxHR >= 100 && maxHR <= 220 else { return false }
        }
        
        if let avgHR = averageHeartRate, let maxHR = maxHeartRate {
            return avgHR <= maxHR
        }
        
        return true
    }
    
    var isValidPowerData: Bool {
        guard averagePower >= 0 && averagePower <= 1000 else { return false }
        
        if let maxPower = maxPower {
            guard maxPower >= 0 && maxPower <= 2000 else { return false }
            return averagePower <= maxPower
        }
        
        return true
    }
    
    var isComplete: Bool {
        return distance > 0 && duration > 0 && averagePower > 0
    }
    
    // MARK: - Apple Health Integration
    
    func updateFromHealthKit(averageHeartRate: Int? = nil,
                           maxHeartRate: Int? = nil,
                           maxPower: Double? = nil,
                           normalizedPower: Double? = nil) {
        if let avgHR = averageHeartRate, avgHR >= 60 && avgHR <= 200 {
            self.averageHeartRate = avgHR
        }
        
        if let maxHR = maxHeartRate, maxHR >= 100 && maxHR <= 220 {
            self.maxHeartRate = maxHR
        }
        
        if let maxPwr = maxPower, maxPwr >= 0 && maxPwr <= 2000 {
            self.maxPower = maxPwr
        }
        
        if let normPwr = normalizedPower, normPwr >= 0 && normPwr <= 1000 {
            self.normalizedPower = normPwr
        }
        
        self.isFromHealthKit = true
    }
}