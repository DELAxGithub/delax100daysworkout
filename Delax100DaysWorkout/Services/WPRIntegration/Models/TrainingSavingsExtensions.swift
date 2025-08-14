import Foundation

// MARK: - TrainingSavings Extensions for WPR Integration

extension TrainingSavings {
    /// WPRへの推定寄与度計算
    var estimatedWPRContribution: Double {
        let progressRatio = Double(currentCount) / Double(targetCount)
        
        switch savingsType {
        case .sstCounter:
            return progressRatio * 0.25  // 効率性25%寄与
        case .pushVolume, .pullVolume, .legsVolume:
            return progressRatio * 0.20 / 3.0  // 筋力20%を3分割
        case .forwardSplitStreak, .sideSplitStreak, .forwardBendStreak, .backBridgeStreak:
            return progressRatio * 0.10 / 4.0  // 柔軟性10%を4分割
        case .chestPress, .squats, .deadlifts, .shoulderPress:
            return progressRatio * 0.05  // 基本筋力5%寄与
        case .hamstringStretch, .backStretch, .shoulderStretch:
            return progressRatio * 0.05  // 基本柔軟性5%寄与
        }
    }
    
    /// WPR統合表示用の進捗情報
    var wprIntegratedProgress: String {
        let contribution = estimatedWPRContribution * 100
        return "WPR寄与: \(String(format: "%.1f", contribution))%"
    }
}