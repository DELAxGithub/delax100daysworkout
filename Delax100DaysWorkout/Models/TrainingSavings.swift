import Foundation
import SwiftData

enum SavingsType: String, Codable, CaseIterable {
    case chestPress = "ChestPress"
    case squats = "Squats" 
    case deadlifts = "Deadlifts"
    case shoulderPress = "ShoulderPress"
    case hamstringStretch = "HamstringStretch"
    case backStretch = "BackStretch"
    case shoulderStretch = "ShoulderStretch"
    case sstCounter = "SSTCounter"
    case pushVolume = "PushVolume"
    case pullVolume = "PullVolume"
    case legsVolume = "LegsVolume"
    case forwardSplitStreak = "ForwardSplitStreak"
    case sideSplitStreak = "SideSplitStreak"
    case forwardBendStreak = "ForwardBendStreak"
    case backBridgeStreak = "BackBridgeStreak"
    
    var displayName: String {
        switch self {
        case .chestPress: return "チェストプレス"
        case .squats: return "スクワット"
        case .deadlifts: return "デッドリフト"
        case .shoulderPress: return "ショルダープレス"
        case .hamstringStretch: return "ハムストリングストレッチ"
        case .backStretch: return "背中ストレッチ"
        case .shoulderStretch: return "肩ストレッチ"
        case .sstCounter: return "SSTセッション"
        case .pushVolume: return "プッシュボリューム"
        case .pullVolume: return "プルボリューム"
        case .legsVolume: return "レッグボリューム"
        case .forwardSplitStreak: return "前屈ストリーク"
        case .sideSplitStreak: return "サイドスプリットストリーク"
        case .forwardBendStreak: return "前屈ストリーク"
        case .backBridgeStreak: return "ブリッジストリーク"
        }
    }
    
    var defaultTarget: Int {
        switch self {
        case .chestPress, .squats, .deadlifts, .shoulderPress:
            return 100 // セット数目標
        case .hamstringStretch, .backStretch, .shoulderStretch:
            return 30 // 日数目標
        case .sstCounter:
            return 50 // SSTセッション目標
        case .pushVolume, .pullVolume, .legsVolume:
            return 1000 // ボリューム目標
        case .forwardSplitStreak, .sideSplitStreak, .forwardBendStreak, .backBridgeStreak:
            return 21 // ストリーク目標（21日間）
        }
    }
    
    var isStrengthType: Bool {
        switch self {
        case .chestPress, .squats, .deadlifts, .shoulderPress, .pushVolume, .pullVolume, .legsVolume:
            return true
        case .hamstringStretch, .backStretch, .shoulderStretch, .forwardSplitStreak, .sideSplitStreak, .forwardBendStreak, .backBridgeStreak:
            return false // 柔軟性
        case .sstCounter:
            return false // サイクリング
        }
    }
}

@Model
final class TrainingSavings {
    var id: UUID = UUID()
    var savingsType: SavingsType
    var currentCount: Int = 0
    var targetCount: Int
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastUpdated: Date = Date()
    var lastStreakDate: Date?
    var createdAt: Date = Date()
    
    init(savingsType: SavingsType, targetCount: Int) {
        self.savingsType = savingsType
        self.targetCount = targetCount
    }
    
    // MARK: - Computed Properties
    
    var progressRatio: Double {
        guard targetCount > 0 else { return 0.0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }
    
    var isCompleted: Bool {
        return currentCount >= targetCount
    }
    
    var remainingCount: Int {
        return max(0, targetCount - currentCount)
    }
    
    // MARK: - Progress Methods
    
    func addProgress(_ amount: Int = 1) {
        currentCount += amount
        lastUpdated = Date()
    }
    
    func updateStreak(for date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        if let lastDate = lastStreakDate {
            let lastStreakDay = calendar.startOfDay(for: lastDate)
            let daysBetween = calendar.dateComponents([.day], from: lastStreakDay, to: today).day ?? 0
            
            if daysBetween == 1 {
                // 連続日
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if daysBetween > 1 {
                // ストリーク途切れ
                currentStreak = 1
            }
        } else {
            // 初回
            currentStreak = 1
            longestStreak = 1
        }
        
        lastStreakDate = date
        lastUpdated = Date()
    }
}

// MARK: - Sample Data

extension TrainingSavings {
    static let sampleData: [TrainingSavings] = [
        TrainingSavings(savingsType: .chestPress, targetCount: 100),
        TrainingSavings(savingsType: .squats, targetCount: 100),
        TrainingSavings(savingsType: .hamstringStretch, targetCount: 30)
    ]
    
    static var sample: TrainingSavings {
        let sample = sampleData[0]
        sample.currentCount = 45
        sample.currentStreak = 7
        sample.longestStreak = 12
        return sample
    }
}