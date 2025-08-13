import Foundation
import SwiftData

@Model
final class TaskCompletionCounter {
    var taskType: String          // 種目識別子 ("SST", "筋トレ-スクワット", "柔軟性-ヨガ" etc.)
    var completionCount: Int      // 累計完了回数
    var currentTarget: Int        // 現在の目標回数
    var startDate: Date          // カウント開始日
    var lastCompletedDate: Date? // 最終完了日
    var isTargetAchieved: Bool   // 現在の目標達成フラグ
    
    init(taskType: String, currentTarget: Int = 50, startDate: Date = Date()) {
        self.taskType = taskType
        self.completionCount = 0
        self.currentTarget = currentTarget
        self.startDate = startDate
        self.lastCompletedDate = nil
        self.isTargetAchieved = false
    }
    
    // カウントアップ
    func incrementCount() {
        completionCount += 1
        lastCompletedDate = Date()
        
        // 目標達成チェック
        if completionCount >= currentTarget && !isTargetAchieved {
            isTargetAchieved = true
        }
    }
    
    // 追加目標設定（「おかわり」機能）
    func addTarget(additionalCount: Int = 50) {
        currentTarget += additionalCount
        isTargetAchieved = false
    }
    
    // 残り回数計算
    var remainingCount: Int {
        max(0, currentTarget - completionCount)
    }
    
    // 進捗率計算
    var progressRate: Double {
        guard currentTarget > 0 else { return 0.0 }
        return min(1.0, Double(completionCount) / Double(currentTarget))
    }
    
    // 表示用フォーマット
    var displayText: String {
        "\(taskType) \(completionCount)回目"
    }
    
    var progressText: String {
        if isTargetAchieved {
            return "目標達成！"
        } else {
            return "\(currentTarget)回まで残り\(remainingCount)回"
        }
    }
}