import Foundation
import SwiftData

struct Performance {
    let workoutType: WorkoutType
    let completionRate: Double
    let averageIntensity: Double
    let recentTrend: Trend
    
    enum Trend {
        case improving
        case stable
        case declining
    }
}

enum SkipReason {
    case weather
    case fatigue
    case timeConstraint
    case injury
    case other
}

class TaskSuggestionManager {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // 今日のタスクを取得し、パフォーマンスに基づいて調整
    func getTodaysTasks(template: WeeklyTemplate, history: [WorkoutRecord]) -> [DailyTask] {
        let dayOfWeek = Calendar.current.component(.weekday, from: Date()) - 1
        let baseTasks = template.tasksForDay(dayOfWeek)
        
        // 過去のパフォーマンスを分析
        let performance = analyzeRecentPerformance(history: history)
        
        // タスクを調整
        return baseTasks.map { task in
            adjustTaskDifficulty(task: task, recentPerformance: performance[task.workoutType])
        }
    }
    
    // タスクの難易度を調整
    func adjustTaskDifficulty(task: DailyTask, recentPerformance: Performance?) -> DailyTask {
        guard task.isFlexible, let performance = recentPerformance else { return task }
        
        let adjustedTask = DailyTask(
            dayOfWeek: task.dayOfWeek,
            workoutType: task.workoutType,
            title: task.title,
            description: task.taskDescription,
            targetDetails: task.targetDetails,
            isFlexible: task.isFlexible
        )
        
        // 調整ロジック
        switch task.workoutType {
        case .cycling:
            adjustCyclingTask(task: adjustedTask, performance: performance)
        case .strength:
            adjustStrengthTask(task: adjustedTask, performance: performance)
        case .flexibility, .pilates, .yoga:
            adjustFlexibilityTask(task: adjustedTask, performance: performance)
            // Note: pilates and yoga are now handled under flexibility type
        }
        
        return adjustedTask
    }
    
    // 代替タスクを提案
    func suggestAlternative(originalTask: DailyTask, reason: SkipReason) -> DailyTask? {
        switch reason {
        case .weather:
            // 屋外活動の代替案
            if originalTask.workoutType == .cycling {
                return createIndoorAlternative(originalTask)
            }
        case .fatigue:
            // 軽めの代替案
            return createLighterAlternative(originalTask)
        case .timeConstraint:
            // 短時間の代替案
            return createShorterAlternative(originalTask)
        case .injury:
            // 負荷の少ない代替案
            return createLowImpactAlternative(originalTask)
        case .other:
            return nil
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func analyzeRecentPerformance(history: [WorkoutRecord]) -> [WorkoutType: Performance] {
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentRecords = history.filter { $0.date >= twoWeeksAgo }
        
        var performances: [WorkoutType: Performance] = [:]
        
        for type in WorkoutType.allCases {
            let typeRecords = recentRecords.filter { $0.workoutType == type }
            guard !typeRecords.isEmpty else { continue }
            
            // 完了率を計算
            let completionRate = Double(typeRecords.filter { $0.isCompleted }.count) / Double(typeRecords.count)
            
            // 平均強度を計算
            let averageIntensity = calculateAverageIntensity(records: typeRecords, type: type)
            
            // トレンドを分析
            let trend = analyzeTrend(records: typeRecords, type: type)
            
            performances[type] = Performance(
                workoutType: type,
                completionRate: completionRate,
                averageIntensity: averageIntensity,
                recentTrend: trend
            )
        }
        
        return performances
    }
    
    private func calculateAverageIntensity(records: [WorkoutRecord], type: WorkoutType) -> Double {
        switch type {
        case .cycling:
            let powers = records.compactMap { $0.cyclingData?.power }.map { Double($0) }
            return powers.isEmpty ? 1.0 : powers.reduce(0, +) / Double(powers.count)
        case .strength:
            // 総重量で計算 (simplified for SimpleStrengthData)
            let totalWeights: [Double] = records.compactMap { record in
                guard let data = record.strengthData else { return nil }
                return data.weight * Double(data.sets * data.reps)
            }
            return totalWeights.isEmpty ? 1.0 : totalWeights.reduce(0, +) / Double(totalWeights.count)
        case .flexibility, .pilates, .yoga:
            // 柔軟性の改善度で計算 (simplified for SimpleFlexibilityData)
            let measurements = records.compactMap { $0.flexibilityData?.measurement }
            return measurements.isEmpty ? 1.0 : measurements.reduce(0, +) / Double(measurements.count)
        // case .pilates, .yoga: // Migrated to flexibility
        //     return 1.0
        }
    }
    
    private func analyzeTrend(records: [WorkoutRecord], type: WorkoutType) -> Performance.Trend {
        guard records.count >= 3 else { return .stable }
        
        let sortedRecords = records.sorted { $0.date < $1.date }
        let firstHalf = Array(sortedRecords.prefix(sortedRecords.count / 2))
        let secondHalf = Array(sortedRecords.suffix(sortedRecords.count / 2))
        
        let firstAvg = calculateAverageIntensity(records: firstHalf, type: type)
        let secondAvg = calculateAverageIntensity(records: secondHalf, type: type)
        
        if secondAvg > firstAvg * 1.05 {
            return .improving
        } else if secondAvg < firstAvg * 0.95 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func adjustCyclingTask(task: DailyTask, performance: Performance) {
        guard var targetDetails = task.targetDetails else { return }
        
        switch performance.recentTrend {
        case .improving:
            // パワーを5%上げる
            if let power = targetDetails.targetPower {
                targetDetails.targetPower = Int(Double(power) * 1.05)
                task.targetDetails = targetDetails
                task.taskDescription = "調子が良いので少し強度を上げました！"
            }
        case .declining:
            // パワーを5%下げる
            if let power = targetDetails.targetPower {
                targetDetails.targetPower = Int(Double(power) * 0.95)
                task.targetDetails = targetDetails
                task.taskDescription = "無理せず、今日は少し軽めで"
            }
        case .stable:
            break
        }
    }
    
    private func adjustStrengthTask(task: DailyTask, performance: Performance) {
        guard var targetDetails = task.targetDetails else { return }
        
        switch performance.recentTrend {
        case .improving:
            // レップ数を増やす
            if let reps = targetDetails.targetReps {
                targetDetails.targetReps = reps + 1
                task.targetDetails = targetDetails
                task.taskDescription = "前回より1レップ多く挑戦！"
            }
        case .declining:
            // セット数を減らす
            if let sets = targetDetails.targetSets, sets > 2 {
                targetDetails.targetSets = sets - 1
                task.targetDetails = targetDetails
                task.taskDescription = "今日は1セット少なめで"
            }
        case .stable:
            break
        }
    }
    
    private func adjustFlexibilityTask(task: DailyTask, performance: Performance) {
        // 柔軟性は基本的に調整しない（怪我のリスクがあるため）
        // ただし、メッセージで励ます
        switch performance.recentTrend {
        case .improving:
            task.taskDescription = "柔軟性が向上しています！この調子で続けましょう"
        case .declining:
            task.taskDescription = "焦らずじっくり伸ばしていきましょう"
        case .stable:
            task.taskDescription = "継続は力なり。今日もコツコツと"
        }
    }
    
    private func createIndoorAlternative(_ originalTask: DailyTask) -> DailyTask {
        let alternative = DailyTask(
            dayOfWeek: originalTask.dayOfWeek,
            workoutType: .strength,
            title: "室内トレーニング",
            description: "雨天のため室内でクロストレーニング"
        )
        
        var details = TargetDetails()
        details.exercises = ["バーピー", "マウンテンクライマー", "プランク"]
        details.targetSets = 3
        details.targetReps = 15
        alternative.targetDetails = details
        
        return alternative
    }
    
    private func createLighterAlternative(_ originalTask: DailyTask) -> DailyTask {
        switch originalTask.workoutType {
        case .cycling:
            let alternative = DailyTask(
                dayOfWeek: originalTask.dayOfWeek,
                workoutType: .cycling,
                title: "リカバリーライド",
                description: "疲労回復のための軽めのライド"
            )
            var details = TargetDetails()
            details.duration = 30
            details.intensity = .recovery
            details.targetPower = 100
            alternative.targetDetails = details
            return alternative
            
        case .strength:
            let alternative = DailyTask(
                dayOfWeek: originalTask.dayOfWeek,
                workoutType: .flexibility,
                title: "アクティブリカバリー",
                description: "ストレッチとモビリティワーク"
            )
            var details = TargetDetails()
            details.targetDuration = 20
            alternative.targetDetails = details
            return alternative
            
        case .flexibility, .pilates, .yoga:
            // 柔軟性は既に軽いので変更なし
            return originalTask
        // case .pilates, .yoga: // Migrated to flexibility
        //     return originalTask
        }
    }
    
    private func createShorterAlternative(_ originalTask: DailyTask) -> DailyTask {
        let alternative = DailyTask(
            dayOfWeek: originalTask.dayOfWeek,
            workoutType: originalTask.workoutType,
            title: "クイック\(originalTask.title)",
            description: "時間がない日の短縮版"
        )
        
        switch originalTask.workoutType {
        case .cycling:
            var details = TargetDetails()
            details.duration = 20
            details.intensity = .sst
            details.targetPower = originalTask.targetDetails?.targetPower
            alternative.targetDetails = details
        case .strength:
            var details = TargetDetails()
            details.exercises = originalTask.targetDetails?.exercises?.prefix(2).map { $0 } ?? []
            details.targetSets = 2
            details.targetReps = originalTask.targetDetails?.targetReps ?? 10
            alternative.targetDetails = details
        case .flexibility, .pilates, .yoga:
            var details = TargetDetails()
            details.targetDuration = 10
            alternative.targetDetails = details
        // case .pilates, .yoga: // Migrated to flexibility
        //     alternative.targetDetails = TargetDetails(targetDuration: 15)
        }
        
        return alternative
    }
    
    private func createLowImpactAlternative(_ originalTask: DailyTask) -> DailyTask {
        let alternative = DailyTask(
            dayOfWeek: originalTask.dayOfWeek,
            workoutType: .flexibility,
            title: "リハビリストレッチ",
            description: "怪我に配慮した軽いストレッチ"
        )
        var details = TargetDetails()
        details.targetDuration = 15
        alternative.targetDetails = details
        return alternative
    }
}