import Foundation
import SwiftData

// MARK: - Unified Achievement System

class AchievementSystem {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Achievement Generation
    
    func generateUnifiedAchievements(
        wprSystem: WPRTrackingSystem?,
        legacySavings: [TrainingSavings],
        unifiedProgress: UnifiedProgressSummary?
    ) -> [UnifiedAchievement] {
        var achievements: [UnifiedAchievement] = []
        
        // WPR系達成
        if let wprSystem = wprSystem {
            achievements.append(contentsOf: generateWPRAchievements(wprSystem))
        }
        
        // レガシー貯金系達成
        achievements.append(contentsOf: generateLegacySavingsAchievements(legacySavings))
        
        // 統合システム系達成
        if let unifiedProgress = unifiedProgress {
            achievements.append(contentsOf: generateIntegrationAchievements(unifiedProgress))
        }
        
        return achievements.sorted { $0.earnedDate > $1.earnedDate }
    }
    
    // MARK: - WPR Achievements
    
    private func generateWPRAchievements(_ wprSystem: WPRTrackingSystem) -> [UnifiedAchievement] {
        var achievements: [UnifiedAchievement] = []
        
        let currentWPR = wprSystem.currentWPR
        let targetWPR = wprSystem.targetWPR
        let progressRatio = targetWPR > 0 ? currentWPR / targetWPR : 0.0
        
        // WPR進捗マイルストーン
        let progressMilestones = [0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
        
        for milestone in progressMilestones {
            if progressRatio >= milestone {
                let achievement = UnifiedAchievement(
                    id: UUID(),
                    type: .wprMilestone,
                    title: "WPR \(Int(milestone * 100))%達成",
                    description: "目標WPRの\(Int(milestone * 100))%に到達しました",
                    earnedDate: wprSystem.lastUpdated ?? Date(),
                    badgeEmoji: getBadgeEmoji(for: milestone),
                    sourceSystem: .wpr,
                    value: String(format: "%.2f", currentWPR)
                )
                achievements.append(achievement)
            }
        }
        
        return achievements
    }
    
    // MARK: - Legacy Savings Achievements
    
    private func generateLegacySavingsAchievements(_ legacySavings: [TrainingSavings]) -> [UnifiedAchievement] {
        var achievements: [UnifiedAchievement] = []
        
        for savings in legacySavings {
            let progressRatio = Double(savings.currentCount) / Double(savings.targetCount)
            
            // 貯金達成マイルストーン
            if progressRatio >= 1.0 {
                let achievement = UnifiedAchievement(
                    id: UUID(),
                    type: .legacySavings,
                    title: "\(savings.savingsType.displayName)達成",
                    description: "目標\(savings.targetCount)回を達成しました",
                    earnedDate: savings.lastUpdated ?? Date(),
                    badgeEmoji: "🏆",
                    sourceSystem: .legacy,
                    value: "\(savings.currentCount)/\(savings.targetCount)"
                )
                achievements.append(achievement)
            }
            
            // ストリーク達成
            if savings.currentStreak >= 7 {
                let achievement = UnifiedAchievement(
                    id: UUID(),
                    type: .legacySavings,
                    title: "\(savings.savingsType.displayName)ストリーク",
                    description: "\(savings.currentStreak)日連続で実施中",
                    earnedDate: savings.lastUpdated ?? Date(),
                    badgeEmoji: "🔥",
                    sourceSystem: .legacy,
                    value: "\(savings.currentStreak)日連続"
                )
                achievements.append(achievement)
            }
        }
        
        return achievements
    }
    
    // MARK: - Integration Achievements
    
    private func generateIntegrationAchievements(_ unifiedProgress: UnifiedProgressSummary) -> [UnifiedAchievement] {
        var achievements: [UnifiedAchievement] = []
        
        // 統合進捗マイルストーン
        if unifiedProgress.totalScore >= 0.8 {
            let achievement = UnifiedAchievement(
                id: UUID(),
                type: .integration,
                title: "統合システム80%達成",
                description: "WPRとレガシーシステムの統合進捗80%を達成",
                earnedDate: Date(),
                badgeEmoji: "🎯",
                sourceSystem: .integrated,
                value: "\(Int(unifiedProgress.totalScore * 100))%"
            )
            achievements.append(achievement)
        }
        
        // バランス達成
        let wprLegacyBalance = abs(unifiedProgress.wprProgress - unifiedProgress.legacyProgress)
        if wprLegacyBalance < 0.1 {  // 10%以内の差
            let achievement = UnifiedAchievement(
                id: UUID(),
                type: .integration,
                title: "バランス達成",
                description: "WPRとレガシー進捗のバランスが取れています",
                earnedDate: Date(),
                badgeEmoji: "⚖️",
                sourceSystem: .integrated,
                value: "バランス良好"
            )
            achievements.append(achievement)
        }
        
        return achievements
    }
    
    // MARK: - Helper Methods
    
    private func getBadgeEmoji(for milestone: Double) -> String {
        switch milestone {
        case 0.1: return "🌱"
        case 0.25: return "🏃"
        case 0.5: return "💪"
        case 0.75: return "🔥"
        case 0.9: return "🚀"
        case 1.0: return "🏆"
        default: return "⭐"
        }
    }
}