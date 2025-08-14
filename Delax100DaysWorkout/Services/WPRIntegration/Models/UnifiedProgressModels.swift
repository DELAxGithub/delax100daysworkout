import Foundation

// MARK: - Unified Progress Models

struct UnifiedProgressSummary {
    let totalScore: Double
    let wprProgress: Double
    let wprCurrent: Double
    let wprTarget: Double
    let legacyProgress: Double
    let sstCount: Int
    let strengthVolume: Double
    let flexibilityStreak: Int
    let daysToWPRTarget: Int
    let overallConfidence: Double
    
    var formattedSummary: String {
        return """
        統合進捗: \(Int(totalScore * 100))%
        WPR進捗: \(String(format: "%.2f", wprCurrent))/\(String(format: "%.1f", wprTarget))
        SST回数: \(sstCount)回
        筋トレ総量: \(Int(strengthVolume))セット
        柔軟性ストリーク: \(flexibilityStreak)日
        """
    }
}

enum UnifiedAchievementType: String, Codable {
    case wprMilestone = "WPRマイルストーン"
    case legacySavings = "貯金達成"
    case scientificMetric = "科学指標達成"
    case integration = "統合システム達成"
}

enum SourceSystem: String, Codable {
    case wpr = "WPRシステム"
    case legacy = "レガシー貯金"
    case scientific = "科学指標"
    case integrated = "統合システム"
}

struct UnifiedAchievement: Identifiable {
    let id: UUID
    let type: UnifiedAchievementType
    let title: String
    let description: String
    let earnedDate: Date
    let badgeEmoji: String
    let sourceSystem: SourceSystem
    let value: String
    
    var displayText: String {
        return "\(badgeEmoji) \(title) (\(sourceSystem.rawValue))"
    }
}

// MARK: - Volume Count Structure

struct VolumeCount {
    let push: Int
    let pull: Int
    let legs: Int
    
    var total: Int {
        return push + pull + legs
    }
}