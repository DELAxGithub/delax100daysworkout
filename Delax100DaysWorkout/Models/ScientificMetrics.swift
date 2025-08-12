import Foundation
import SwiftData
import SwiftUI

// MARK: - Efficiency Factor System

@Model
final class EfficiencyMetrics: @unchecked Sendable {
    var id: UUID
    var measurementDate: Date
    var normalizedPower: Double
    var averageHeartRate: Int
    var duration: TimeInterval  // セッション継続時間（秒）
    var workoutType: String     // "SST", "Threshold", "Endurance"
    
    // メタデータ
    var isValid: Bool = true    // データ品質フラグ
    var weatherConditions: String?
    var notes: String?
    
    init(normalizedPower: Double, averageHeartRate: Int, duration: TimeInterval, workoutType: String = "General") {
        self.id = UUID()
        self.measurementDate = Date()
        self.normalizedPower = normalizedPower
        self.averageHeartRate = averageHeartRate
        self.duration = duration
        self.workoutType = workoutType
    }
    
    // MARK: - Computed Properties
    
    /// Efficiency Factor = NP ÷ HR (Hopker et al., 2010)
    var efficiencyFactor: Double {
        guard averageHeartRate > 0 else { return 0.0 }
        return normalizedPower / Double(averageHeartRate)
    }
    
    /// WPRへの推定寄与度
    var wprContribution: Double {
        // EF改善 → 同心拍でより高パワー → WPR向上
        let baselineEF = 1.2
        let improvement = efficiencyFactor - baselineEF
        return max(improvement * 2.5, 0.0)  // 係数は実データで調整
    }
    
    /// データ品質スコア（0.0-1.0）
    var qualityScore: Double {
        var score = 1.0
        
        // 継続時間チェック（20分未満は品質低下）
        if duration < 1200 { score -= 0.3 }
        
        // 心拍数の妥当性チェック
        if averageHeartRate < 100 || averageHeartRate > 200 { score -= 0.4 }
        
        // パワーの妥当性チェック
        if normalizedPower < 50 || normalizedPower > 500 { score -= 0.3 }
        
        return max(score, 0.0)
    }
}

// MARK: - Power Profile System

@Model
final class PowerProfile: @unchecked Sendable {
    var id: UUID
    var testDate: Date
    var testConditions: String?  // "Indoor", "Outdoor", "Race"
    
    // 各時間域の最高平均パワー
    var power5Sec: Int = 0       // 神経筋パワー
    var power1Min: Int = 0       // VO2max
    var power5Min: Int = 0       // VO2max持久
    var power20Min: Int = 0      // FTP
    var power60Min: Int = 0      // 有酸素持久
    
    // ベースライン比較用
    var baseline5Sec: Int = 0
    var baseline1Min: Int = 0
    var baseline5Min: Int = 0
    var baseline20Min: Int = 0
    var baseline60Min: Int = 0
    
    // テスト詳細
    var restBetweenEfforts: TimeInterval = 0  // 各エフォート間の休息時間
    var overallTestDuration: TimeInterval = 0
    var perceivedExertion: Int = 0           // RPE (1-10)
    
    init() {
        self.id = UUID()
        self.testDate = Date()
    }
    
    // MARK: - Computed Properties
    
    /// 全体的な改善スコア (Cesanelli et al., 2021 基準)
    var improvementScore: Double {
        let currentPowers = [power5Sec, power1Min, power5Min, power20Min, power60Min]
        let baselinePowers = [baseline5Sec, baseline1Min, baseline5Min, baseline20Min, baseline60Min]
        
        guard baselinePowers.allSatisfy({ $0 > 0 }) else { return 0.0 }
        
        let improvements = zip(currentPowers, baselinePowers).map { current, baseline in
            Double(current - baseline) / Double(baseline)
        }
        
        return improvements.reduce(0, +) / Double(improvements.count)
    }
    
    /// 各領域の改善率
    var neuromuscularImprovement: Double {
        guard baseline5Sec > 0 else { return 0.0 }
        return Double(power5Sec - baseline5Sec) / Double(baseline5Sec)
    }
    
    var vo2maxImprovement: Double {
        guard baseline1Min > 0 else { return 0.0 }
        return Double(power1Min - baseline1Min) / Double(baseline1Min)
    }
    
    var vo2maxEnduranceImprovement: Double {
        guard baseline5Min > 0 else { return 0.0 }
        return Double(power5Min - baseline5Min) / Double(baseline5Min)
    }
    
    var ftpImprovement: Double {
        guard baseline20Min > 0 else { return 0.0 }
        return Double(power20Min - baseline20Min) / Double(baseline20Min)
    }
    
    var aerobicEnduranceImprovement: Double {
        guard baseline60Min > 0 else { return 0.0 }
        return Double(power60Min - baseline60Min) / Double(baseline60Min)
    }
    
    /// パワープロファイルのバランススコア
    var profileBalance: Double {
        let powers = [power5Sec, power1Min, power5Min, power20Min, power60Min]
        guard powers.allSatisfy({ $0 > 0 }) else { return 0.0 }
        
        // 理想的な比率（5秒を基準とした相対値）
        let idealRatios = [1.0, 0.85, 0.75, 0.65, 0.55]
        let actualRatios = powers.map { Double($0) / Double(power5Sec) }
        
        let deviations = zip(actualRatios, idealRatios).map { abs($0 - $1) }
        let averageDeviation = deviations.reduce(0, +) / Double(deviations.count)
        
        return max(1.0 - averageDeviation, 0.0)
    }
    
    /// ベースライン設定
    func setBaseline() {
        baseline5Sec = power5Sec
        baseline1Min = power1Min
        baseline5Min = power5Min
        baseline20Min = power20Min
        baseline60Min = power60Min
    }
}

// MARK: - HR at Power Tracking

@Model
final class HRAtPowerTracking: @unchecked Sendable {
    var id: UUID
    var testDate: Date
    var testPowers: [Int] = [200, 250, 300]  // テスト用固定ワット
    var heartRateResponses: [Int] = []       // 対応する心拍数
    var testDuration: TimeInterval = 60      // 各パワーでのテスト時間（秒）
    
    // ベースライン
    var baselineHRResponses: [Int] = []
    
    // 環境要因
    var ambientTemperature: Double?
    var humidity: Double?
    var restingHR: Int?
    
    init() {
        self.id = UUID()
        self.testDate = Date()
    }
    
    // MARK: - Computed Properties
    
    /// 全体的な効率改善 (Lunn et al., 2009 基準)
    var efficiencyImprovement: Double {
        guard heartRateResponses.count == baselineHRResponses.count,
              heartRateResponses.count > 0 else { return 0.0 }
        
        let improvements = zip(heartRateResponses, baselineHRResponses).map { current, baseline in
            Double(baseline - current) / Double(baseline)  // 心拍低下は改善
        }
        
        return improvements.reduce(0, +) / Double(improvements.count)
    }
    
    /// 特定ワット数での効率
    func efficiencyAt(power: Int) -> Double? {
        guard let index = testPowers.firstIndex(of: power),
              index < heartRateResponses.count else { return nil }
        
        return Double(power) / Double(heartRateResponses[index])
    }
    
    /// 心肺フィットネス指数
    var cardioFitnessIndex: Double {
        guard !heartRateResponses.isEmpty else { return 0.0 }
        
        // より高いワット数で相対的に低い心拍数 = 良好
        let weightedEfficiency = zip(testPowers, heartRateResponses).enumerated().map { index, pair in
            let (power, hr) = pair
            let weight = Double(index + 1)  // 高ワットほど重み大
            return Double(power) / Double(hr) * weight
        }
        
        return weightedEfficiency.reduce(0, +) / Double(weightedEfficiency.count)
    }
    
    /// ベースライン設定
    func setBaseline() {
        baselineHRResponses = heartRateResponses
    }
}

// MARK: - Volume Load System

enum MuscleGroup: String, Codable, CaseIterable {
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
    
    var iconName: String {
        switch self {
        case .push: return "figure.strengthtraining.traditional"
        case .pull: return "figure.pull.ups"
        case .legs: return "figure.squat"
        }
    }
    
    var color: Color {
        switch self {
        case .push: return .red
        case .pull: return .green
        case .legs: return .orange
        }
    }
}

@Model
final class VolumeLoadSystem: @unchecked Sendable {
    var id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    
    // 週間Volume Load (重量 × レップ × セット)
    var weeklyPushVL: Double = 0.0
    var weeklyPullVL: Double = 0.0
    var weeklyLegsVL: Double = 0.0
    
    // ベースライン
    var baselinePushVL: Double = 0.0
    var baselinePullVL: Double = 0.0
    var baselineLegsVL: Double = 0.0
    
    // Krzysztofik et al. (2019) 基準指標
    var targetWeeklyPushSets: Int = 28       // 週28-30セット/筋群
    var targetWeeklyPullSets: Int = 28
    var targetWeeklyLegsSets: Int = 24
    
    var actualWeeklyPushSets: Int = 0
    var actualWeeklyPullSets: Int = 0
    var actualWeeklyLegsSets: Int = 0
    
    // RPE/質的評価
    var averagePushRPE: Double = 0.0
    var averagePullRPE: Double = 0.0
    var averageLegsRPE: Double = 0.0
    
    init() {
        self.id = UUID()
        let now = Date()
        let calendar = Calendar.current
        self.weekStartDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        self.weekEndDate = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
    }
    
    // MARK: - Computed Properties
    
    /// 総Volume Load
    var totalVolumeLoad: Double {
        return weeklyPushVL + weeklyPullVL + weeklyLegsVL
    }
    
    /// 全体的な改善スコア (Vikmoen et al., 2021: 8%パワー向上基準)
    var improvementScore: Double {
        let baselineTotal = baselinePushVL + baselinePullVL + baselineLegsVL
        guard baselineTotal > 0 else { return 0.0 }
        
        return (totalVolumeLoad - baselineTotal) / baselineTotal
    }
    
    /// 各筋群の改善率
    var pushImprovement: Double {
        guard baselinePushVL > 0 else { return 0.0 }
        return (weeklyPushVL - baselinePushVL) / baselinePushVL
    }
    
    var pullImprovement: Double {
        guard baselinePullVL > 0 else { return 0.0 }
        return (weeklyPullVL - baselinePullVL) / baselinePullVL
    }
    
    var legsImprovement: Double {
        guard baselineLegsVL > 0 else { return 0.0 }
        return (weeklyLegsVL - baselineLegsVL) / baselineLegsVL
    }
    
    /// セット数達成率
    var pushSetAchievement: Double {
        return Double(actualWeeklyPushSets) / Double(targetWeeklyPushSets)
    }
    
    var pullSetAchievement: Double {
        return Double(actualWeeklyPullSets) / Double(targetWeeklyPullSets)
    }
    
    var legsSetAchievement: Double {
        return Double(actualWeeklyLegsSets) / Double(targetWeeklyLegsSets)
    }
    
    /// 筋力バランススコア
    var balanceScore: Double {
        let pushRatio = weeklyPushVL / totalVolumeLoad
        let pullRatio = weeklyPullVL / totalVolumeLoad
        let legsRatio = weeklyLegsVL / totalVolumeLoad
        
        // 理想的な比率（Push:Pull:Legs = 1.2:1.0:0.8）
        let idealPushRatio = 1.2 / 3.0
        let idealPullRatio = 1.0 / 3.0
        let idealLegsRatio = 0.8 / 3.0
        
        let pushDeviation = abs(pushRatio - idealPushRatio)
        let pullDeviation = abs(pullRatio - idealPullRatio)
        let legsDeviation = abs(legsRatio - idealLegsRatio)
        
        let averageDeviation = (pushDeviation + pullDeviation + legsDeviation) / 3.0
        return max(1.0 - averageDeviation * 3.0, 0.0)
    }
    
    /// ベースライン設定
    func setBaseline() {
        baselinePushVL = weeklyPushVL
        baselinePullVL = weeklyPullVL
        baselineLegsVL = weeklyLegsVL
    }
}

// MARK: - ROM Tracking System

@Model
final class ROMTracking: @unchecked Sendable {
    var id: UUID
    var measurementDate: Date
    
    // 各部位の可動域（度数）
    var forwardBendAngle: Double = 0.0      // 前屈角度
    var shoulderFlexion: Double = 0.0       // 肩屈曲可動域
    var hipFlexibility: Double = 0.0        // 股関節柔軟性
    var spinalRotation: Double = 0.0        // 脊椎回旋
    var ankleFlexion: Double = 0.0          // 足首背屈
    
    // ベースライン
    var baselineForwardBend: Double = 0.0
    var baselineShoulderFlexion: Double = 0.0
    var baselineHipFlexibility: Double = 0.0
    var baselineSpinalRotation: Double = 0.0
    var baselineAnkleFlexion: Double = 0.0
    
    // 動的柔軟性テスト結果
    var dynamicFlexibilityScore: Double = 0.0
    var yBalanceTestScore: Double = 0.0
    
    // 柔軟性セッション詳細
    var sessionDuration: TimeInterval = 0   // 秒
    var stretchHoldTime: TimeInterval = 30  // 各ストレッチの保持時間
    var perceivedStretching: Int = 0        // 伸張感覚 (1-10)
    
    init() {
        self.id = UUID()
        self.measurementDate = Date()
    }
    
    // MARK: - Computed Properties
    
    /// 全体的な改善スコア (Konrad, 2024 基準)
    var improvementScore: Double {
        let current = [forwardBendAngle, shoulderFlexion, hipFlexibility, spinalRotation, ankleFlexion]
        let baseline = [baselineForwardBend, baselineShoulderFlexion, baselineHipFlexibility, 
                       baselineSpinalRotation, baselineAnkleFlexion]
        
        guard baseline.allSatisfy({ $0 > 0 }) else { return 0.0 }
        
        let improvements = zip(current, baseline).map { current, baseline in
            (current - baseline) / baseline
        }
        
        return improvements.reduce(0, +) / Double(improvements.count)
    }
    
    /// パワーロス削減推定 (Holliday et al., 2021)
    var powerLossReduction: Double {
        // ROM改善 → ペダリング効率改善 → パワーロス削減
        let hipContribution = (hipFlexibility - baselineHipFlexibility) * 0.002  // 2% per 10°
        let shoulderContribution = (shoulderFlexion - baselineShoulderFlexion) * 0.001
        let spineContribution = (spinalRotation - baselineSpinalRotation) * 0.0015
        
        return max(hipContribution + shoulderContribution + spineContribution, 0.0)
    }
    
    /// 各部位の改善率
    var forwardBendImprovement: Double {
        guard baselineForwardBend > 0 else { return 0.0 }
        return (forwardBendAngle - baselineForwardBend) / baselineForwardBend
    }
    
    var shoulderFlexionImprovement: Double {
        guard baselineShoulderFlexion > 0 else { return 0.0 }
        return (shoulderFlexion - baselineShoulderFlexion) / baselineShoulderFlexion
    }
    
    var hipFlexibilityImprovement: Double {
        guard baselineHipFlexibility > 0 else { return 0.0 }
        return (hipFlexibility - baselineHipFlexibility) / baselineHipFlexibility
    }
    
    /// 機能的可動域スコア
    var functionalMobilityScore: Double {
        // 各関節の重要度重み付け（サイクリング特化）
        let hipWeight = 0.4      // 股関節が最重要
        let shoulderWeight = 0.25
        let spineWeight = 0.2
        let ankleWeight = 0.1
        let forwardBendWeight = 0.05
        
        let weightedScore = (hipFlexibility * hipWeight +
                           shoulderFlexion * shoulderWeight +
                           spinalRotation * spineWeight +
                           ankleFlexion * ankleWeight +
                           forwardBendAngle * forwardBendWeight) / 100.0  // 正規化
        
        return min(weightedScore, 1.0)
    }
    
    /// ベースライン設定
    func setBaseline() {
        baselineForwardBend = forwardBendAngle
        baselineShoulderFlexion = shoulderFlexion
        baselineHipFlexibility = hipFlexibility
        baselineSpinalRotation = spinalRotation
        baselineAnkleFlexion = ankleFlexion
    }
}

// MARK: - Supporting Extensions

extension WPRTrackingSystem {
    /// 最新の科学的指標を統合更新
    func updateFromScientificMetrics(
        efficiency: EfficiencyMetrics?,
        powerProfile: PowerProfile?,
        hrTracking: HRAtPowerTracking?,
        volumeLoad: VolumeLoadSystem?,
        romTracking: ROMTracking?
    ) {
        if let ef = efficiency {
            self.efficiencyFactor = ef.efficiencyFactor
        }
        
        // Update from PowerProfile
        if let pp = powerProfile {
            // PowerProfile metrics are already tracked separately
            // No direct update needed here
        }
        
        // Update from HRAtPowerTracking
        if let hr = hrTracking {
            // HRAtPowerTracking metrics are already tracked separately
            // No direct update needed here
        }
        
        // Update from VolumeLoadSystem
        if let vl = volumeLoad {
            // VolumeLoadSystem metrics are already tracked separately
            // No direct update needed here
        }
        
        // Update from ROMTracking
        if let rom = romTracking {
            // ROMTracking metrics are already tracked separately
            // No direct update needed here
        }
        
        self.lastUpdated = Date()
    }
}