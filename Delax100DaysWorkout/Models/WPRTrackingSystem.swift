import Foundation
import SwiftData
import SwiftUI

enum BottleneckType: String, Codable, CaseIterable {
    case efficiency = "効率性"
    case power = "パワー"
    case cardio = "心肺機能"
    case strength = "筋力"
    case flexibility = "柔軟性"
    case weight = "体重"
    
    var iconName: String {
        switch self {
        case .efficiency: return "speedometer"
        case .power: return "bolt.fill"
        case .cardio: return "heart.fill"
        case .strength: return "figure.strengthtraining.traditional"
        case .flexibility: return "figure.flexibility"
        case .weight: return "scalemass.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .efficiency: return .blue
        case .power: return .red
        case .cardio: return .pink
        case .strength: return .green
        case .flexibility: return .purple
        case .weight: return .orange
        }
    }
    
    var improvementStrategy: String {
        switch self {
        case .efficiency: return "SST/閾値トレーニング強化"
        case .power: return "パワープロファイル全域向上"
        case .cardio: return "HR@Power効率改善"
        case .strength: return "Volume Load増加"
        case .flexibility: return "ROM可動域拡大"
        case .weight: return "体重管理・体組成改善"
        }
    }
}

@Model
final class WPRTrackingSystem: @unchecked Sendable {
    var id: UUID
    var createdDate: Date
    var lastUpdated: Date
    
    // 基本WPR指標
    var currentWPR: Double = 0.0
    var targetWPR: Double = 4.5
    var baselineFTP: Int = 0
    var baselineWeight: Double = 0.0
    
    // 現在のFTPと体重（動的更新）
    var currentFTP: Int = 0
    var currentWeight: Double = 0.0
    
    // 科学的指標と寄与度係数 (Hopker et al., 2010; Seiler, 2009)
    var efficiencyFactor: Double = 0.0
    var efficiencyCoefficient: Double = 0.25    // 25%寄与
    var efficiencyBaseline: Double = 1.2
    var efficiencyTarget: Double = 1.5
    
    // Power Profile係数 (Cesanelli et al., 2021)
    var powerProfileCoefficient: Double = 0.30  // 30%寄与
    var powerProfileBaseline: Double = 0.0
    var powerProfileTarget: Double = 0.15       // 15%向上目標
    
    // HR効率係数 (Lunn et al., 2009)
    var hrEfficiencyCoefficient: Double = 0.15  // 15%寄与
    var hrEfficiencyBaseline: Double = 0.0
    var hrEfficiencyFactor: Double = 0.0
    var hrEfficiencyTarget: Double = -15.0      // -15bpm目標
    
    // 筋力係数 (Vikmoen et al., 2021; Krzysztofik et al., 2019)
    var strengthCoefficient: Double = 0.20      // 20%寄与
    var strengthBaseline: Double = 0.0
    var strengthFactor: Double = 0.0
    var strengthTarget: Double = 0.30           // 30%VL向上
    
    // 柔軟性係数 (Holliday et al., 2021; Konrad, 2024)
    var flexibilityCoefficient: Double = 0.10   // 10%寄与
    var flexibilityBaseline: Double = 0.0
    var flexibilityFactor: Double = 0.0
    var flexibilityTarget: Double = 15.0        // +15°目標
    
    // アルゴリズム計算結果
    var overallProgressScore: Double = 0.0
    var currentBottleneck: BottleneckType = BottleneckType.efficiency
    var projectedWPRGain: Double = 0.0
    var daysToTarget: Int?
    var confidenceLevel: Double = 0.0           // 予測信頼度
    
    // 拡張指標対応（将来使用）
    var customCoefficients: [String: Double] = [:]  // 追加指標用
    var isAdvancedMode: Bool = false            // 上級者モード
    
    init() {
        self.id = UUID()
        self.createdDate = Date()
        self.lastUpdated = Date()
    }
    
    // MARK: - Computed Properties
    
    /// 現在のWPR計算
    var calculatedWPR: Double {
        guard currentWeight > 0 else { return 0.0 }
        return Double(currentFTP) / currentWeight
    }
    
    /// 目標達成率 (0.0 - 1.0)
    var targetProgressRatio: Double {
        guard targetWPR > baselineWPR else { return 0.0 }
        return min((calculatedWPR - baselineWPR) / (targetWPR - baselineWPR), 1.0)
    }
    
    /// ベースラインWPR
    var baselineWPR: Double {
        guard baselineWeight > 0 else { return 0.0 }
        return Double(baselineFTP) / baselineWeight
    }
    
    /// 目標まで必要なWPR向上
    var requiredWPRGain: Double {
        return max(targetWPR - calculatedWPR, 0.0)
    }
    
    /// 各指標の目標達成率
    var efficiencyProgress: Double {
        let range = efficiencyTarget - efficiencyBaseline
        guard range > 0 else { return 0.0 }
        return min((efficiencyFactor - efficiencyBaseline) / range, 1.0)
    }
    
    var powerProfileProgress: Double {
        guard powerProfileTarget > 0 else { return 0.0 }
        return min((powerProfileBaseline > 0 ? 
                   (currentPowerProfileScore - powerProfileBaseline) / powerProfileTarget : 0.0), 1.0)
    }
    
    var hrEfficiencyProgress: Double {
        let range = abs(hrEfficiencyTarget - hrEfficiencyBaseline)
        guard range > 0 else { return 0.0 }
        // 心拍効率は減少が良い方向なので計算を調整
        let currentReduction = hrEfficiencyBaseline - hrEfficiencyFactor
        let targetReduction = hrEfficiencyBaseline - hrEfficiencyTarget
        return min(max(currentReduction / targetReduction, 0.0), 1.0)
    }
    
    var strengthProgress: Double {
        let range = strengthTarget - strengthBaseline
        guard range > 0 else { return 0.0 }
        return min((strengthFactor - strengthBaseline) / range, 1.0)
    }
    
    var flexibilityProgress: Double {
        let range = flexibilityTarget - flexibilityBaseline
        guard range > 0 else { return 0.0 }
        return min((flexibilityFactor - flexibilityBaseline) / range, 1.0)
    }
    
    // MARK: - Methods
    
    /// 係数の妥当性チェック
    func validateCoefficients() -> Bool {
        let totalCoefficient = efficiencyCoefficient + powerProfileCoefficient + 
                              hrEfficiencyCoefficient + strengthCoefficient + flexibilityCoefficient
        return abs(totalCoefficient - 1.0) < 0.01  // 合計100%の許容誤差1%
    }
    
    /// 係数の正規化（合計100%に調整）
    func normalizeCoefficients() {
        let total = efficiencyCoefficient + powerProfileCoefficient + 
                   hrEfficiencyCoefficient + strengthCoefficient + flexibilityCoefficient
        
        guard total > 0 else { return }
        
        efficiencyCoefficient /= total
        powerProfileCoefficient /= total
        hrEfficiencyCoefficient /= total
        strengthCoefficient /= total
        flexibilityCoefficient /= total
    }
    
    /// ベースライン設定
    func setBaseline(ftp: Int, weight: Double, ef: Double = 1.2) {
        baselineFTP = ftp
        baselineWeight = weight
        currentFTP = ftp
        currentWeight = weight
        efficiencyBaseline = ef
        efficiencyFactor = ef
        lastUpdated = Date()
    }
    
    /// 現在の指標更新
    func updateCurrentMetrics(ftp: Int, weight: Double) {
        currentFTP = ftp
        currentWeight = weight
        lastUpdated = Date()
    }
    
    /// エビデンスベース係数リセット（研究データ基準）
    func resetToEvidenceBasedCoefficients() {
        // Hopker et al. (2010) - EF/効率性重要度
        efficiencyCoefficient = 0.25
        
        // Cesanelli et al. (2021) - パワープロファイル重要度
        powerProfileCoefficient = 0.30
        
        // Lunn et al. (2009) - 心肺効率重要度
        hrEfficiencyCoefficient = 0.15
        
        // Vikmoen/Krzysztofik - 筋力重要度
        strengthCoefficient = 0.20
        
        // Holliday/Konrad - 柔軟性重要度
        flexibilityCoefficient = 0.10
        
        lastUpdated = Date()
    }
    
    /// WPRメトリクス再計算（FTP/体重変更時）
    func recalculateWPRMetrics() {
        // 現在のWPRを再計算
        currentWPR = calculatedWPR
        
        // 目標達成率を更新
        let _ = targetProgressRatio
        
        // 改善予測を更新（簡易版）
        if baselineWPR > 0 && targetWPR > baselineWPR {
            let progressToTarget = (calculatedWPR - baselineWPR) / (targetWPR - baselineWPR)
            
            // 線形外挿で残り期間を予測
            if progressToTarget > 0 && overallProgressScore > 0 {
                let estimatedTotalDays = Date().timeIntervalSince(createdDate) / (24 * 60 * 60) / progressToTarget
                let remainingDays = max(0, estimatedTotalDays - Date().timeIntervalSince(createdDate) / (24 * 60 * 60))
                daysToTarget = Int(remainingDays)
            }
            
            projectedWPRGain = max(0, targetWPR - calculatedWPR)
        }
        
        lastUpdated = Date()
    }
}

// MARK: - Supporting Data Structures

struct WPRProjection {
    let currentWPR: Double
    let projectedWPR: Double
    let daysToTarget: Int
    let confidenceLevel: Double
    let bottleneck: BottleneckType
    let recommendedActions: [String]
}

struct WPRMilestone {
    let wprValue: Double
    let description: String
    let badgeEmoji: String
    let achievementDate: Date?
    let isAchieved: Bool
    
    static let milestones: [WPRMilestone] = [
        WPRMilestone(wprValue: 3.5, description: "中級者レベル", badgeEmoji: "🥉", achievementDate: nil, isAchieved: false),
        WPRMilestone(wprValue: 4.0, description: "上級者レベル", badgeEmoji: "🥈", achievementDate: nil, isAchieved: false),
        WPRMilestone(wprValue: 4.5, description: "エリートレベル", badgeEmoji: "🥇", achievementDate: nil, isAchieved: false),
        WPRMilestone(wprValue: 5.0, description: "プロレベル", badgeEmoji: "👑", achievementDate: nil, isAchieved: false)
    ]
}

extension WPRTrackingSystem {
    /// 現在のパワープロファイルスコア（PowerProfile から計算）
    var currentPowerProfileScore: Double {
        // PowerProfile integration point
        // Returns placeholder value as PowerProfile is managed separately
        // Actual score calculation would require PowerProfile instance reference
        return 0.0
    }
    
    /// デバッグ用サンプルデータ生成
    static func sampleData() -> WPRTrackingSystem {
        let system = WPRTrackingSystem()
        system.setBaseline(ftp: 250, weight: 70.0, ef: 1.22)
        system.updateCurrentMetrics(ftp: 265, weight: 68.5)
        system.efficiencyFactor = 1.28
        system.overallProgressScore = 0.64
        system.currentBottleneck = .strength
        system.projectedWPRGain = 0.3
        system.daysToTarget = 45
        system.confidenceLevel = 0.85
        return system
    }
}