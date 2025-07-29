import Foundation
import SwiftData

@Model
final class WeeklyReport {
    var weekStartDate: Date
    var weekEndDate: Date
    var cyclingCompleted: Int = 0
    var cyclingTarget: Int = 0
    var strengthCompleted: Int = 0
    var strengthTarget: Int = 0
    var flexibilityCompleted: Int = 0
    var flexibilityTarget: Int = 0
    var summary: String = ""
    var achievements: [String] = []
    var encouragementMessage: String = ""
    var createdAt: Date
    
    init(weekStartDate: Date) {
        self.weekStartDate = weekStartDate
        self.weekEndDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        self.createdAt = Date()
    }
    
    var totalCompleted: Int {
        cyclingCompleted + strengthCompleted + flexibilityCompleted
    }
    
    var totalTarget: Int {
        cyclingTarget + strengthTarget + flexibilityTarget
    }
    
    var completionRate: Double {
        guard totalTarget > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalTarget)
    }
    
    var cyclingCompletionRate: Double {
        guard cyclingTarget > 0 else { return 0 }
        return Double(cyclingCompleted) / Double(cyclingTarget)
    }
    
    var strengthCompletionRate: Double {
        guard strengthTarget > 0 else { return 0 }
        return Double(strengthCompleted) / Double(strengthTarget)
    }
    
    var flexibilityCompletionRate: Double {
        guard flexibilityTarget > 0 else { return 0 }
        return Double(flexibilityCompleted) / Double(flexibilityTarget)
    }
    
    func generateSummary(records: [WorkoutRecord], previousWeek: WeeklyReport?) {
        // 達成率に基づくサマリー生成
        var summaryParts: [String] = []
        
        // 全体の達成率
        let rate = Int(completionRate * 100)
        if rate >= 90 {
            summaryParts.append("素晴らしい週でした！達成率\(rate)%")
        } else if rate >= 70 {
            summaryParts.append("良い調子です。達成率\(rate)%")
        } else {
            summaryParts.append("来週も頑張りましょう。達成率\(rate)%")
        }
        
        // 各カテゴリーの状況
        if cyclingCompleted > 0 {
            summaryParts.append("サイクリング: \(cyclingCompleted)/\(cyclingTarget)")
        }
        if strengthCompleted > 0 {
            summaryParts.append("筋トレ: \(strengthCompleted)/\(strengthTarget)")
        }
        if flexibilityCompleted > 0 {
            summaryParts.append("柔軟: \(flexibilityCompleted)/\(flexibilityTarget)")
        }
        
        self.summary = summaryParts.joined(separator: " ")
        
        // 励ましメッセージ生成
        generateEncouragementMessage()
    }
    
    private func generateEncouragementMessage() {
        if completionRate >= 1.0 {
            encouragementMessage = "完璧な1週間でした！この調子を維持しましょう 🎉"
        } else if completionRate >= 0.8 {
            encouragementMessage = "素晴らしい達成率です！あと少しで完璧でした 💪"
        } else if completionRate >= 0.6 {
            encouragementMessage = "良いペースです。来週はもう少し頑張ってみましょう 👍"
        } else {
            encouragementMessage = "継続することが大切です。少しずつ進めていきましょう 🌱"
        }
        
        // カテゴリー別の励まし
        if flexibilityCompletionRate >= 0.9 && flexibilityTarget > 0 {
            encouragementMessage += "\n柔軟性トレーニングの継続、素晴らしいです！"
        }
        if cyclingCompletionRate >= 0.9 && cyclingTarget > 0 {
            encouragementMessage += "\nサイクリングの目標達成、お見事です！"
        }
        if strengthCompletionRate >= 0.9 && strengthTarget > 0 {
            encouragementMessage += "\n筋トレの継続、効果が出てきているはず！"
        }
    }
}