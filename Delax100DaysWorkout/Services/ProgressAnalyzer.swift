import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "ProgressAnalyzer")

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
        case .pilates:
            // ピラティスPR検出は後で実装
            return nil
        case .yoga:
            // ヨガPR検出は後で実装
            return nil
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
    
    // Enhanced full analysis method for WeeklyPlanManager
    func performFullAnalysis() async -> AnalysisData {
        do {
            // Fetch all workout records with performance optimization
            let descriptor = FetchDescriptor<WorkoutRecord>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let allRecords = try modelContext.fetch(descriptor)
            
            // Filter to last 30 days for performance (configurable)
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recentRecords = allRecords.filter { $0.date >= thirtyDaysAgo }
            
            // Enhanced progress analysis
            let progress = analyzeProgress(records: recentRecords)
            
            // Calculate completion rate based on recent activity
            let completionRate = calculateEnhancedCompletionRate(records: recentRecords)
            
            // Generate comprehensive trends summary
            let progressTrends = generateEnhancedProgressTrendsSummary(records: recentRecords, allRecords: allRecords)
            
            // Performance metrics
            let analysisMetrics = calculateAnalysisMetrics(recentRecords: recentRecords, totalRecords: allRecords)
            
            logger.info("Full analysis completed: \(recentRecords.count) recent records, completion rate: \(completionRate)%")
            
            return AnalysisData(
                workoutRecords: recentRecords,
                completionRate: completionRate,
                progressTrends: "\(progressTrends)\n\n📊 分析メトリクス: \(analysisMetrics)"
            )
        } catch {
            Logger.error.error("Failed to perform full analysis: \(error.localizedDescription)")
            return AnalysisData(
                workoutRecords: [], 
                completionRate: 0, 
                progressTrends: "分析エラー: データの取得に失敗しました"
            )
        }
    }
    
    // AI分析用の構造化データを生成
    func generateAIAnalysisData(records: [WorkoutRecord], template: WeeklyTemplate) -> AIAnalysisRequest {
        let weeklyStats = calculateWeeklyStats(records: records, template: template)
        let progress = analyzeProgress(records: records)
        
        // ユーザー設定を取得（実装に応じて調整）
        let userPreferences = UserPreferences(
            preferredWorkoutDays: [1, 2, 3, 4, 5, 6], // 月-土
            availableTime: 60, // 1日平均60分
            fitnessGoals: ["筋力向上", "持久力向上", "柔軟性向上"],
            limitations: []
        )
        
        return AIAnalysisRequest(
            weeklyStats: weeklyStats,
            progress: progress,
            currentTemplate: template,
            userPreferences: userPreferences
        )
    }
    
    // 詳細な週次レポートを生成（AI用）
    func generateDetailedWeeklyReport(records: [WorkoutRecord], template: WeeklyTemplate) -> DetailedWeeklyReport {
        let stats = calculateWeeklyStats(records: records, template: template)
        let progress = analyzeProgress(records: records)
        
        // より詳細な分析
        let cyclingAnalysis = analyzeCyclingTrends(records: records)
        let strengthAnalysis = analyzeStrengthTrends(records: records)
        let flexibilityAnalysis = analyzeFlexibilityTrends(records: records)
        
        return DetailedWeeklyReport(
            weeklyStats: stats,
            progress: progress,
            cyclingAnalysis: cyclingAnalysis,
            strengthAnalysis: strengthAnalysis,
            flexibilityAnalysis: flexibilityAnalysis,
            recommendations: generateRecommendations(stats: stats, progress: progress)
        )
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
            if powers.count >= 2, let lastPower = powers.last, let firstPower = powers.first, lastPower > firstPower {
                improvements.append("パワーが向上中")
            }
            
        case .strength:
            let totalVolumes = typeRecords.compactMap { record in
                record.strengthDetails?.reduce(0.0) { $0 + ($1.weight * Double($1.sets * $1.reps)) }
            }
            averageMetric = totalVolumes.isEmpty ? 0 : totalVolumes.reduce(0, +) / Double(totalVolumes.count)
            if totalVolumes.count >= 2, let lastVolume = totalVolumes.last, let firstVolume = totalVolumes.first, lastVolume > firstVolume {
                improvements.append("総負荷量が増加")
            }
            
        case .flexibility:
            let angles = typeRecords.compactMap { $0.flexibilityDetail?.averageSplitAngle }
            averageMetric = angles.isEmpty ? 0 : angles.reduce(0, +) / Double(angles.count)
            if angles.count >= 2, let lastAngle = angles.last, let firstAngle = angles.first, lastAngle > firstAngle {
                improvements.append("柔軟性が向上")
            }
        case .pilates:
            averageMetric = Double(typeRecords.count)
            if typeRecords.count >= 2 {
                improvements.append("継続的に実施")
            }
        case .yoga:
            averageMetric = Double(typeRecords.count)
            if typeRecords.count >= 2 {
                improvements.append("継続的に実施")
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
            Logger.error.error("Error fetching achievements: \(error.localizedDescription)")
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
    
    // サイクリングのトレンド分析
    private func analyzeCyclingTrends(records: [WorkoutRecord]) -> CyclingTrendAnalysis {
        let cyclingRecords = records.filter { $0.workoutType == .cycling }
            .sorted { $0.date < $1.date }
        
        guard cyclingRecords.count >= 3 else {
            return CyclingTrendAnalysis(
                powerTrend: .stable,
                distanceTrend: .stable,
                consistencyScore: 0.5,
                recommendations: ["より多くのデータが必要です"]
            )
        }
        
        let powers = cyclingRecords.compactMap { $0.cyclingDetail?.averagePower }
        let distances = cyclingRecords.compactMap { $0.cyclingDetail?.distance }
        
        return CyclingTrendAnalysis(
            powerTrend: calculateTrend(values: powers),
            distanceTrend: calculateTrend(values: distances.map { Double($0) }),
            consistencyScore: calculateConsistencyScore(values: powers),
            recommendations: generateCyclingRecommendations(powers: powers, distances: distances.map { Int($0) })
        )
    }
    
    // 筋トレのトレンド分析
    private func analyzeStrengthTrends(records: [WorkoutRecord]) -> StrengthTrendAnalysis {
        let strengthRecords = records.filter { $0.workoutType == .strength }
            .sorted { $0.date < $1.date }
        
        guard strengthRecords.count >= 3 else {
            return StrengthTrendAnalysis(
                volumeTrend: .stable,
                strengthTrend: .stable,
                consistencyScore: 0.5,
                recommendations: ["より多くのデータが必要です"]
            )
        }
        
        let totalVolumes = strengthRecords.compactMap { record in
            record.strengthDetails?.reduce(0.0) { $0 + ($1.weight * Double($1.sets * $1.reps)) }
        }
        
        let maxWeights = strengthRecords.compactMap { record in
            record.strengthDetails?.map { $0.weight }.max()
        }
        
        return StrengthTrendAnalysis(
            volumeTrend: calculateTrend(values: totalVolumes),
            strengthTrend: calculateTrend(values: maxWeights),
            consistencyScore: calculateConsistencyScore(values: totalVolumes),
            recommendations: generateStrengthRecommendations(volumes: totalVolumes, maxWeights: maxWeights)
        )
    }
    
    // 柔軟性のトレンド分析
    private func analyzeFlexibilityTrends(records: [WorkoutRecord]) -> FlexibilityTrendAnalysis {
        let flexRecords = records.filter { $0.workoutType == .flexibility }
            .sorted { $0.date < $1.date }
        
        guard flexRecords.count >= 3 else {
            return FlexibilityTrendAnalysis(
                forwardBendTrend: .stable,
                splitAngleTrend: .stable,
                consistencyScore: 0.5,
                recommendations: ["より多くのデータが必要です"]
            )
        }
        
        let forwardBends = flexRecords.compactMap { $0.flexibilityDetail?.forwardBendDistance }
        let splitAngles = flexRecords.compactMap { $0.flexibilityDetail?.averageSplitAngle }
        
        return FlexibilityTrendAnalysis(
            forwardBendTrend: calculateTrend(values: forwardBends),
            splitAngleTrend: calculateTrend(values: splitAngles),
            consistencyScore: calculateConsistencyScore(values: splitAngles),
            recommendations: generateFlexibilityRecommendations(forwardBends: forwardBends, splitAngles: splitAngles)
        )
    }
    
    // 汎用トレンド計算
    private func calculateTrend(values: [Double]) -> TrendDirection {
        guard values.count >= 3 else { return .stable }
        
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        if secondAvg > firstAvg * 1.05 {
            return .improving
        } else if secondAvg < firstAvg * 0.95 {
            return .declining
        } else {
            return .stable
        }
    }
    
    // 一貫性スコアの計算
    private func calculateConsistencyScore(values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // CV（変動係数）を逆にして一貫性スコアとする
        let coefficientOfVariation = standardDeviation / mean
        return max(0, 1 - coefficientOfVariation)
    }
    
    // レコメンデーション生成
    private func generateRecommendations(stats: WeeklyStats, progress: Progress) -> [String] {
        var recommendations: [String] = []
        
        // 完了率に基づく推奨
        if stats.completionRate < 0.7 {
            recommendations.append("完了率が低いため、目標を調整することを検討してください")
        } else if stats.completionRate > 0.9 {
            recommendations.append("素晴らしい完了率です！強度を少し上げても良いかもしれません")
        }
        
        // ストリークに基づく推奨
        if progress.currentStreak == 0 {
            recommendations.append("新しいスタートです。小さな目標から始めましょう")
        } else if progress.currentStreak >= 7 {
            recommendations.append("連続記録が素晴らしいです！適度な休息も忘れずに")
        }
        
        return recommendations
    }
    
    private func generateCyclingRecommendations(powers: [Double], distances: [Int]) -> [String] {
        var recommendations: [String] = []
        
        if powers.isEmpty {
            recommendations.append("パワーデータの記録を開始しましょう")
        } else {
            let avgPower = powers.reduce(0, +) / Double(powers.count)
            if avgPower < 150 {
                recommendations.append("基礎持久力の向上に重点を置きましょう")
            } else if avgPower > 200 {
                recommendations.append("高いパワーを維持できています！インターバルトレーニングを追加してみては？")
            }
        }
        
        return recommendations
    }
    
    private func generateStrengthRecommendations(volumes: [Double], maxWeights: [Double]) -> [String] {
        var recommendations: [String] = []
        
        if volumes.isEmpty {
            recommendations.append("筋トレのボリューム記録を開始しましょう")
        } else {
            let trend = calculateTrend(values: volumes)
            switch trend {
            case .improving:
                recommendations.append("筋力が順調に向上しています！")
            case .declining:
                recommendations.append("十分な休息と栄養を確保しましょう")
            case .stable:
                recommendations.append("プログレッシブオーバーロードを意識しましょう")
            }
        }
        
        return recommendations
    }
    
    private func generateFlexibilityRecommendations(forwardBends: [Double], splitAngles: [Double]) -> [String] {
        var recommendations: [String] = []
        
        if splitAngles.isEmpty {
            recommendations.append("柔軟性の測定を開始しましょう")
        } else {
            let avgAngle = splitAngles.reduce(0, +) / Double(splitAngles.count)
            if avgAngle < 90 {
                recommendations.append("基本的なストレッチから始めましょう")
            } else if avgAngle > 130 {
                recommendations.append("素晴らしい柔軟性です！さらなる向上を目指しましょう")
            }
        }
        
        return recommendations
    }
    
    // Helper method to generate progress trends summary
    private func generateProgressTrendsSummary(records: [WorkoutRecord]) -> String {
        let cyclingRecords = records.filter { $0.workoutType == .cycling }
        let strengthRecords = records.filter { $0.workoutType == .strength }
        let flexibilityRecords = records.filter { $0.workoutType == .flexibility }
        
        var trends: [String] = []
        
        if !cyclingRecords.isEmpty {
            let analysis = analyzeCyclingTrends(records: records)
            trends.append("サイクリング: \(trendToString(analysis.powerTrend))")
        }
        
        if !strengthRecords.isEmpty {
            let analysis = analyzeStrengthTrends(records: records)
            trends.append("筋トレ: \(trendToString(analysis.volumeTrend))")
        }
        
        if !flexibilityRecords.isEmpty {
            let analysis = analyzeFlexibilityTrends(records: records)
            trends.append("柔軟性: \(trendToString(analysis.splitAngleTrend))")
        }
        
        return trends.isEmpty ? "データ不足" : trends.joined(separator: ", ")
    }
    
    private func trendToString(_ trend: TrendDirection) -> String {
        switch trend {
        case .improving: return "向上中"
        case .stable: return "安定"
        case .declining: return "下降気味"
        }
    }
    
    // Enhanced helper methods for Phase 2
    
    private func calculateEnhancedCompletionRate(records: [WorkoutRecord]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        
        // Get completed workouts in the last 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentRecords = records.filter { $0.date >= sevenDaysAgo }
        let completedRecords = recentRecords.filter { $0.isCompleted }
        
        // Calculate completion rate as percentage
        let rate = Double(completedRecords.count) / max(Double(recentRecords.count), 1.0) * 100
        return min(rate, 100.0) // Cap at 100%
    }
    
    private func generateEnhancedProgressTrendsSummary(records: [WorkoutRecord], allRecords: [WorkoutRecord]) -> String {
        var summary: [String] = []
        
        // Recent vs historical comparison
        let historicalAverage = calculateHistoricalAverage(allRecords: allRecords)
        let recentAverage = calculateRecentAverage(records: records)
        
        if recentAverage > historicalAverage * 1.1 {
            summary.append("📈 最近のパフォーマンスが歴史的平均を上回っています")
        } else if recentAverage < historicalAverage * 0.9 {
            summary.append("📉 最近のパフォーマンスが低下傾向にあります")
        } else {
            summary.append("📊 パフォーマンスは安定しています")
        }
        
        // Workout type distribution
        let distribution = analyzeWorkoutTypeDistribution(records: records)
        summary.append("💪 トレーニング構成: \(distribution)")
        
        // Enhanced trends by type
        let cyclingRecords = records.filter { $0.workoutType == .cycling }
        let strengthRecords = records.filter { $0.workoutType == .strength }
        let flexibilityRecords = records.filter { $0.workoutType == .flexibility }
        
        if !cyclingRecords.isEmpty {
            let analysis = analyzeCyclingTrends(records: records)
            summary.append("🚴‍♂️ サイクリング: \(trendToString(analysis.powerTrend)) (一貫性: \(String(format: "%.0f", analysis.consistencyScore * 100))%)")
        }
        
        if !strengthRecords.isEmpty {
            let analysis = analyzeStrengthTrends(records: records)
            summary.append("💪 筋トレ: \(trendToString(analysis.volumeTrend)) (一貫性: \(String(format: "%.0f", analysis.consistencyScore * 100))%)")
        }
        
        if !flexibilityRecords.isEmpty {
            let analysis = analyzeFlexibilityTrends(records: records)
            summary.append("🧘‍♀️ 柔軟性: \(trendToString(analysis.splitAngleTrend)) (一貫性: \(String(format: "%.0f", analysis.consistencyScore * 100))%)")
        }
        
        return summary.joined(separator: "\n")
    }
    
    private func calculateAnalysisMetrics(recentRecords: [WorkoutRecord], totalRecords: [WorkoutRecord]) -> String {
        let recentCount = recentRecords.count
        let totalCount = totalRecords.count
        let dataPoints = totalCount > 0 ? totalCount : 0
        let analysisDepth = recentCount > 20 ? "詳細" : recentCount > 10 ? "標準" : "基本"
        
        return "データポイント: \(dataPoints), 分析対象: \(recentCount)件, 深度: \(analysisDepth)"
    }
    
    private func calculateHistoricalAverage(allRecords: [WorkoutRecord]) -> Double {
        guard allRecords.count > 7 else { return 0.0 }
        
        // Calculate weekly average over all historical data
        let totalWeeks = max(1.0, Double(allRecords.count) / 7.0)
        return Double(allRecords.filter { $0.isCompleted }.count) / totalWeeks
    }
    
    private func calculateRecentAverage(records: [WorkoutRecord]) -> Double {
        guard records.count > 0 else { return 0.0 }
        
        // Calculate weekly average for recent period
        let recentWeeks = max(1.0, Double(records.count) / 7.0)
        return Double(records.filter { $0.isCompleted }.count) / recentWeeks
    }
    
    private func analyzeWorkoutTypeDistribution(records: [WorkoutRecord]) -> String {
        let cycling = records.filter { $0.workoutType == .cycling }.count
        let strength = records.filter { $0.workoutType == .strength }.count
        let flexibility = records.filter { $0.workoutType == .flexibility }.count
        let total = max(records.count, 1)
        
        let cyclingPct = Int(Double(cycling) / Double(total) * 100)
        let strengthPct = Int(Double(strength) / Double(total) * 100)
        let flexibilityPct = Int(Double(flexibility) / Double(total) * 100)
        
        return "サイクリング \(cyclingPct)%, 筋トレ \(strengthPct)%, 柔軟性 \(flexibilityPct)%"
    }
}

// AI分析用の追加データ構造
struct DetailedWeeklyReport {
    let weeklyStats: WeeklyStats
    let progress: Progress
    let cyclingAnalysis: CyclingTrendAnalysis
    let strengthAnalysis: StrengthTrendAnalysis
    let flexibilityAnalysis: FlexibilityTrendAnalysis
    let recommendations: [String]
}

struct CyclingTrendAnalysis {
    let powerTrend: TrendDirection
    let distanceTrend: TrendDirection
    let consistencyScore: Double
    let recommendations: [String]
}

struct StrengthTrendAnalysis {
    let volumeTrend: TrendDirection
    let strengthTrend: TrendDirection
    let consistencyScore: Double
    let recommendations: [String]
}

struct FlexibilityTrendAnalysis {
    let forwardBendTrend: TrendDirection
    let splitAngleTrend: TrendDirection
    let consistencyScore: Double
    let recommendations: [String]
}

enum TrendDirection {
    case improving
    case stable
    case declining
}