import Foundation
import SwiftData

struct WeeklyStats {
    let weekStartDate: Date
    let totalWorkouts: Int
    let completedWorkouts: Int
    let cyclingStats: WorkoutTypeStats
    let strengthStats: WorkoutTypeStats
    let flexibilityStats: WorkoutTypeStats
    let achievements: [Achievement]
    
    var completionRate: Double {
        guard totalWorkouts > 0 else { return 0 }
        return Double(completedWorkouts) / Double(totalWorkouts)
    }
}

struct WorkoutTypeStats {
    let type: WorkoutType
    let completed: Int
    let target: Int
    let improvements: [String]
    let averageMetric: Double // パワー、重量、角度など
    
    var completionRate: Double {
        guard target > 0 else { return 0 }
        return Double(completed) / Double(target)
    }
}

struct Progress {
    let currentStreak: Int
    let longestStreak: Int
    let totalWorkouts: Int
    let weeklyAverage: Double
    let recentAchievements: [Achievement]
}

class ProgressAnalyzer {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // PR（Personal Record）を検出
    func detectPR(newRecord: WorkoutRecord, history: [WorkoutRecord]) -> Achievement? {
        switch newRecord.workoutType {
        case .cycling:
            return detectCyclingPR(newRecord: newRecord, history: history)
        case .strength:
            return Achievement.checkForPR(newRecord: newRecord, history: history)
        case .flexibility:
            return detectFlexibilityPR(newRecord: newRecord, history: history)
        }
    }
    
    // 週次統計を計算
    func calculateWeeklyStats(records: [WorkoutRecord], template: WeeklyTemplate) -> WeeklyStats {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        // 今週の記録をフィルタ
        let weekRecords = records.filter { record in
            guard let recordWeek = calendar.dateInterval(of: .weekOfYear, for: record.date)?.start else { return false }
            return recordWeek == weekStart
        }
        
        // タイプ別に統計を計算
        let cyclingStats = calculateTypeStats(records: weekRecords, type: .cycling, template: template)
        let strengthStats = calculateTypeStats(records: weekRecords, type: .strength, template: template)
        let flexibilityStats = calculateTypeStats(records: weekRecords, type: .flexibility, template: template)
        
        // 今週の実績を収集
        let achievements = collectWeeklyAchievements(records: weekRecords)
        
        return WeeklyStats(
            weekStartDate: weekStart,
            totalWorkouts: weekRecords.count,
            completedWorkouts: weekRecords.filter { $0.isCompleted }.count,
            cyclingStats: cyclingStats,
            strengthStats: strengthStats,
            flexibilityStats: flexibilityStats,
            achievements: achievements
        )
    }
    
    // モチベーショナルメッセージを生成
    func generateMotivationalMessage(progress: Progress) -> String {
        var messages: [String] = []
        
        // ストリークに基づくメッセージ
        if progress.currentStreak >= 7 {
            messages.append("🔥 \(progress.currentStreak)日連続達成中！素晴らしい継続力です")
        } else if progress.currentStreak >= 3 {
            messages.append("👍 \(progress.currentStreak)日連続！この調子で1週間を目指しましょう")
        }
        
        // 週平均に基づくメッセージ
        if progress.weeklyAverage >= 5 {
            messages.append("💪 週\(Int(progress.weeklyAverage))回のトレーニング、アスリートレベルです！")
        } else if progress.weeklyAverage >= 3 {
            messages.append("✨ 週\(Int(progress.weeklyAverage))回のペース、理想的です")
        }
        
        // 最近の実績に基づくメッセージ
        if let latestAchievement = progress.recentAchievements.first {
            switch latestAchievement.type {
            case .personalRecord:
                messages.append("🏆 新記録達成！限界を超えました")
            case .milestone:
                messages.append("🎯 マイルストーン達成！着実に前進しています")
            case .improvement:
                messages.append("📈 確実に成長しています！")
            case .streak:
                messages.append("🔥 継続は力なり！")
            }
        }
        
        // ランダムな励ましメッセージ
        let encouragements = [
            "今日も一歩前進！",
            "小さな積み重ねが大きな成果に",
            "あなたの努力は必ず報われます",
            "昨日の自分を超えていこう",
            "継続することが最大の才能"
        ]
        
        if messages.isEmpty {
            messages.append(encouragements.randomElement() ?? "頑張っています！")
        }
        
        return messages.joined(separator: "\n")
    }
    
    // MARK: - Private Methods
    
    private func detectCyclingPR(newRecord: WorkoutRecord, history: [WorkoutRecord]) -> Achievement? {
        guard let newDetail = newRecord.cyclingDetail else { return nil }
        
        let cyclingHistory = history.filter { $0.workoutType == .cycling }
        
        // 最高パワー記録をチェック
        let maxPower = cyclingHistory.compactMap { $0.cyclingDetail?.averagePower }.max() ?? 0
        
        if newDetail.averagePower > maxPower && maxPower > 0 {
            return Achievement(
                type: .personalRecord,
                title: "パワー新記録！",
                description: "平均\(Int(newDetail.averagePower))W達成",
                workoutType: .cycling,
                value: "\(Int(newDetail.averagePower))W"
            )
        }
        
        // 最長距離記録をチェック
        let maxDistance = cyclingHistory.compactMap { $0.cyclingDetail?.distance }.max() ?? 0
        
        if newDetail.distance > maxDistance && maxDistance > 0 {
            return Achievement(
                type: .personalRecord,
                title: "距離新記録！",
                description: "\(newDetail.distance)km達成",
                workoutType: .cycling,
                value: "\(newDetail.distance)km"
            )
        }
        
        return nil
    }
    
    private func detectFlexibilityPR(newRecord: WorkoutRecord, history: [WorkoutRecord]) -> Achievement? {
        guard let newDetail = newRecord.flexibilityDetail else { return nil }
        
        let flexHistory = history
            .filter { $0.workoutType == .flexibility }
            .compactMap { $0.flexibilityDetail }
        
        return Achievement.checkForFlexibilityImprovement(current: newDetail, previous: flexHistory)
    }
    
    private func calculateTypeStats(records: [WorkoutRecord], type: WorkoutType, template: WeeklyTemplate) -> WorkoutTypeStats {
        let typeRecords = records.filter { $0.workoutType == type }
        let completed = typeRecords.filter { $0.isCompleted }.count
        
        // テンプレートから目標数を取得
        let weeklyTarget = (0...6).reduce(0) { count, day in
            count + template.tasksForDay(day).filter { $0.workoutType == type }.count
        }
        
        // 改善点を分析
        var improvements: [String] = []
        let averageMetric: Double
        
        switch type {
        case .cycling:
            let powers = typeRecords.compactMap { $0.cyclingDetail?.averagePower }
            averageMetric = powers.isEmpty ? 0 : powers.reduce(0, +) / Double(powers.count)
            if powers.count >= 2 && powers.last! > powers.first! {
                improvements.append("パワーが向上中")
            }
            
        case .strength:
            let totalVolumes = typeRecords.compactMap { record in
                record.strengthDetails?.reduce(0.0) { $0 + ($1.weight * Double($1.sets * $1.reps)) }
            }
            averageMetric = totalVolumes.isEmpty ? 0 : totalVolumes.reduce(0, +) / Double(totalVolumes.count)
            if totalVolumes.count >= 2 && totalVolumes.last! > totalVolumes.first! {
                improvements.append("総負荷量が増加")
            }
            
        case .flexibility:
            let angles = typeRecords.compactMap { $0.flexibilityDetail?.averageSplitAngle }
            averageMetric = angles.isEmpty ? 0 : angles.reduce(0, +) / Double(angles.count)
            if angles.count >= 2 && angles.last! > angles.first! {
                improvements.append("柔軟性が向上")
            }
        }
        
        return WorkoutTypeStats(
            type: type,
            completed: completed,
            target: weeklyTarget,
            improvements: improvements,
            averageMetric: averageMetric
        )
    }
    
    private func collectWeeklyAchievements(records: [WorkoutRecord]) -> [Achievement] {
        // 実際の実装では、Achievement モデルから今週の実績を取得
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { achievement in
                achievement.date >= weekStart
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching achievements: \(error)")
            return []
        }
    }
    
    // 現在の進捗状況を分析
    func analyzeProgress(records: [WorkoutRecord]) -> Progress {
        let sortedRecords = records.sorted { $0.date > $1.date }
        
        // 現在のストリークを計算
        let currentStreak = calculateCurrentStreak(records: sortedRecords)
        
        // 最長ストリークを計算
        let longestStreak = calculateLongestStreak(records: sortedRecords)
        
        // 週平均を計算
        let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()
        let recentRecords = records.filter { $0.date >= fourWeeksAgo }
        let weeklyAverage = Double(recentRecords.count) / 4.0
        
        // 最近の実績
        let recentAchievements = collectWeeklyAchievements(records: recentRecords)
        
        return Progress(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalWorkouts: records.count,
            weeklyAverage: weeklyAverage,
            recentAchievements: recentAchievements
        )
    }
    
    private func calculateCurrentStreak(records: [WorkoutRecord]) -> Int {
        var streak = 0
        var lastDate = Date()
        let calendar = Calendar.current
        
        for record in records.sorted(by: { $0.date > $1.date }) {
            let daysBetween = calendar.dateComponents([.day], from: record.date, to: lastDate).day ?? 0
            
            if daysBetween <= 1 {
                streak += 1
                lastDate = record.date
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak(records: [WorkoutRecord]) -> Int {
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        let calendar = Calendar.current
        
        for record in records.sorted(by: { $0.date < $1.date }) {
            if let last = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: last, to: record.date).day ?? 0
                
                if daysBetween <= 1 {
                    currentStreak += 1
                } else {
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            lastDate = record.date
        }
        
        return max(longestStreak, currentStreak)
    }
}