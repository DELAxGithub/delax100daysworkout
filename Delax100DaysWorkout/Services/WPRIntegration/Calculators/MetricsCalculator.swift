import Foundation
import SwiftData

// MARK: - Metrics Calculator

class MetricsCalculator {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Unified Progress Calculation
    
    func calculateUnifiedProgress(
        wprSystem: WPRTrackingSystem?,
        legacySavings: [TrainingSavings]
    ) -> UnifiedProgressSummary {
        
        let wprProgress = calculateWPRProgress(wprSystem)
        let legacyProgress = calculateLegacyProgress(legacySavings)
        
        // 総合スコア計算 (WPR 70%, Legacy 30%)
        let totalScore = (wprProgress.progress * 0.7) + (legacyProgress.averageProgress * 0.3)
        
        return UnifiedProgressSummary(
            totalScore: totalScore,
            wprProgress: wprProgress.progress,
            wprCurrent: wprProgress.current,
            wprTarget: wprProgress.target,
            legacyProgress: legacyProgress.averageProgress,
            sstCount: legacyProgress.sstCount,
            strengthVolume: legacyProgress.totalStrengthVolume,
            flexibilityStreak: legacyProgress.maxFlexibilityStreak,
            daysToWPRTarget: wprProgress.daysToTarget,
            overallConfidence: calculateConfidenceScore(wprProgress, legacyProgress)
        )
    }
    
    // MARK: - WPR Progress Calculation
    
    private func calculateWPRProgress(_ wprSystem: WPRTrackingSystem?) -> WPRProgressInfo {
        guard let wprSystem = wprSystem else {
            return WPRProgressInfo(progress: 0.0, current: 0.0, target: 1.0, daysToTarget: 999)
        }
        
        let currentWPR = wprSystem.currentWPR
        let targetWPR = wprSystem.targetWPR
        
        guard targetWPR > 0 else {
            return WPRProgressInfo(progress: 0.0, current: currentWPR, target: targetWPR, daysToTarget: 999)
        }
        
        let progress = min(currentWPR / targetWPR, 1.0)
        let remainingProgress = max(targetWPR - currentWPR, 0.0)
        
        // 現在の改善レートから目標達成日数を推定
        let improvementRate = calculateRecentImprovementRate(wprSystem)
        let daysToTarget = improvementRate > 0 ? Int(remainingProgress / improvementRate) : 999
        
        return WPRProgressInfo(
            progress: progress,
            current: currentWPR,
            target: targetWPR,
            daysToTarget: daysToTarget
        )
    }
    
    // MARK: - Legacy Progress Calculation
    
    private func calculateLegacyProgress(_ legacySavings: [TrainingSavings]) -> LegacyProgressInfo {
        guard !legacySavings.isEmpty else {
            return LegacyProgressInfo(
                averageProgress: 0.0,
                sstCount: 0,
                totalStrengthVolume: 0.0,
                maxFlexibilityStreak: 0
            )
        }
        
        let progressValues = legacySavings.map { Double($0.currentCount) / Double($0.targetCount) }
        let averageProgress = progressValues.reduce(0, +) / Double(progressValues.count)
        
        let sstCount = legacySavings.first { $0.savingsType == .sstCounter }?.currentCount ?? 0
        
        let strengthTypes: [SavingsType] = [.pushVolume, .pullVolume, .legsVolume]
        let totalStrengthVolume = strengthTypes.compactMap { type in
            legacySavings.first { $0.savingsType == type }?.currentCount
        }.reduce(0, +)
        
        let flexibilityTypes: [SavingsType] = [.forwardSplitStreak, .sideSplitStreak, .forwardBendStreak, .backBridgeStreak]
        let maxFlexibilityStreak = flexibilityTypes.compactMap { type in
            legacySavings.first { $0.savingsType == type }?.currentStreak
        }.max() ?? 0
        
        return LegacyProgressInfo(
            averageProgress: averageProgress,
            sstCount: sstCount,
            totalStrengthVolume: Double(totalStrengthVolume),
            maxFlexibilityStreak: maxFlexibilityStreak
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateRecentImprovementRate(_ wprSystem: WPRTrackingSystem) -> Double {
        // 過去30日間の改善レートを計算
        // 実装ではhistoricalDataから計算する
        return 0.01  // 仮の値: 1日0.01の改善
    }
    
    private func calculateConfidenceScore(
        _ wprProgress: WPRProgressInfo,
        _ legacyProgress: LegacyProgressInfo
    ) -> Double {
        // 信頼度スコア計算 (0.0 - 1.0)
        var confidence = 0.0
        
        // WPR進捗による信頼度 (50%)
        confidence += wprProgress.progress * 0.5
        
        // レガシー進捗による信頼度 (30%)
        confidence += legacyProgress.averageProgress * 0.3
        
        // 一貫性による信頼度 (20%)
        let consistencyScore = calculateConsistencyScore(wprProgress, legacyProgress)
        confidence += consistencyScore * 0.2
        
        return min(confidence, 1.0)
    }
    
    private func calculateConsistencyScore(
        _ wprProgress: WPRProgressInfo,
        _ legacyProgress: LegacyProgressInfo
    ) -> Double {
        // WPR進捗とレガシー進捗の一貫性を評価
        let progressDifference = abs(wprProgress.progress - legacyProgress.averageProgress)
        return max(1.0 - progressDifference, 0.0)  // 差が小さいほど高スコア
    }
}

// MARK: - Supporting Structures

private struct WPRProgressInfo {
    let progress: Double
    let current: Double
    let target: Double
    let daysToTarget: Int
}

private struct LegacyProgressInfo {
    let averageProgress: Double
    let sstCount: Int
    let totalStrengthVolume: Double
    let maxFlexibilityStreak: Int
}