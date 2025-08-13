import Foundation
import SwiftData
import Combine
import OSLog

// MARK: - Unified Training System Integration

@MainActor
class WPRTrainingSavingsIntegration: ObservableObject {
    private let modelContext: ModelContext
    private let wprOptimizationEngine: WPROptimizationEngine
    private let bottleneckSystem: BottleneckDetectionSystem
    
    @Published var wprSystem: WPRTrackingSystem?
    @Published var legacySavings: [TrainingSavings] = []
    @Published var unifiedProgress: UnifiedProgressSummary?
    @Published var isUpdating = false
    @Published var lastUpdateDate: Date?
    
    // 統合された達成システム
    @Published var unifiedAchievements: [UnifiedAchievement] = []
    @Published var totalSavingsScore: Double = 0.0
    @Published var wprContribution: Double = 0.0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.wprOptimizationEngine = WPROptimizationEngine(modelContext: modelContext)
        self.bottleneckSystem = BottleneckDetectionSystem(
            modelContext: modelContext,
            optimizationEngine: wprOptimizationEngine
        )
        
        loadExistingSystems()
    }
    
    // MARK: - System Integration Methods
    
    /// 既存システムとWPRシステムの初期化
    func initializeUnifiedSystem() {
        // WPRシステムの初期化
        if wprSystem == nil {
            let newWPRSystem = WPRTrackingSystem()
            newWPRSystem.setBaseline(ftp: getCurrentFTP(), weight: getCurrentWeight())
            modelContext.insert(newWPRSystem)
            wprSystem = newWPRSystem
        }
        
        // 既存TrainingSavingsの初期化（必要に応じて）
        initializeLegacySavingsIfNeeded()
        
        // 統合進捗の計算
        calculateUnifiedProgress()
        
        do {
            try modelContext.save()
        } catch {
            Logger.error.error("統合システム初期化エラー: \(error.localizedDescription)")
        }
    }
    
    /// ワークアウト完了時の統合更新
    func updateFromWorkout(_ workout: WorkoutRecord) {
        isUpdating = true
        
        Task {
            // 1. 既存TrainingSavingsシステムの更新
            await updateLegacySavings(from: workout)
            
            // 2. WPRシステムの更新
            await updateWPRSystem(from: workout)
            
            // 3. 科学的指標の更新
            await updateScientificMetrics(from: workout)
            
            // 4. 統合分析の実行
            if let wprSystem = wprSystem {
                await wprOptimizationEngine.performCompleteAnalysis(wprSystem)
                await bottleneckSystem.performComprehensiveBottleneckAnalysis(wprSystem)
            }
            
            // 5. 統合進捗の再計算
            await MainActor.run {
                calculateUnifiedProgress()
                generateUnifiedAchievements()
                lastUpdateDate = Date()
                isUpdating = false
            }
            
            // 6. データ保存
            do {
                try modelContext.save()
            } catch {
                Logger.error.error("統合更新保存エラー: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Legacy Savings Integration
    
    private func updateLegacySavings(from workout: WorkoutRecord) async {
        // 既存のTrainingSavingsロジックを統合
        switch workout.workoutType {
        case .cycling:
            await updateSSTSavings(from: workout)
        case .strength:
            await updateVolumeSavings(from: workout)
        case .flexibility:
            await updateFlexibilityStreaks(from: workout)
        case .pilates:
            // ピラティス節約は後で実装
            break
        case .yoga:
            // ヨガ節約は後で実装
            break
        }
    }
    
    private func updateSSTSavings(from workout: WorkoutRecord) async {
        guard let cyclingDetail = workout.cyclingDetail,
              let currentFTP = getCurrentFTPFromHistory() else { return }
        
        // SST判定ロジック（既存ロジックを活用）
        let isSST = isQualifiedSST(cyclingDetail: cyclingDetail, currentFTP: currentFTP)
        
        if isSST, let sstSavings = getSavings(for: .sstCounter) {
            sstSavings.currentCount += 1
            sstSavings.lastUpdated = Date()
            
            // WPRシステムにも貢献度を反映
            if let wprSystem = wprSystem {
                let sstContribution = calculateSSTContributionToWPR(sstSavings)
                wprSystem.efficiencyFactor += sstContribution * 0.01  // 1%改善
            }
            
            checkLegacyMilestones(sstSavings)
        }
    }
    
    private func updateVolumeSavings(from workout: WorkoutRecord) async {
        guard let strengthDetails = workout.strengthDetails else { return }
        
        let volumeCount = extractMuscleGroupSets(from: strengthDetails)
        
        // 各筋群の更新
        updateMuscleGroupSavings(.pushVolume, sets: volumeCount.push)
        updateMuscleGroupSavings(.pullVolume, sets: volumeCount.pull)
        updateMuscleGroupSavings(.legsVolume, sets: volumeCount.legs)
        
        // WPRシステムへの筋力寄与度更新
        if let wprSystem = wprSystem {
            let strengthContribution = calculateStrengthContributionToWPR(volumeCount)
            wprSystem.strengthBaseline += strengthContribution * 0.005  // 0.5%改善
        }
    }
    
    private func updateFlexibilityStreaks(from workout: WorkoutRecord) async {
        guard let flexDetail = workout.flexibilityDetail else { return }
        
        let today = Date()
        
        // 各柔軟性ストリークの更新
        if (flexDetail.forwardSplitLeft ?? 0) > 0 || (flexDetail.forwardSplitRight ?? 0) > 0 {
            updateFlexibilityStreak(.forwardSplitStreak, date: today)
        }
        
        if (flexDetail.sideSplitAngle ?? 0) > 0 {
            updateFlexibilityStreak(.sideSplitStreak, date: today)
        }
        
        if flexDetail.forwardBendDistance > 0 {
            updateFlexibilityStreak(.forwardBendStreak, date: today)
        }
        
        // WPRシステムへの柔軟性寄与度更新
        if let wprSystem = wprSystem {
            let flexibilityContribution = calculateFlexibilityContributionToWPR(flexDetail)
            wprSystem.flexibilityBaseline += flexibilityContribution * 0.002  // 0.2%改善
        }
    }
    
    // MARK: - WPR System Updates
    
    private func updateWPRSystem(from workout: WorkoutRecord) async {
        guard let wprSystem = wprSystem else { return }
        
        // FTPと体重の更新
        let currentFTP = getCurrentFTPFromHistory() ?? wprSystem.currentFTP
        let currentWeight = getCurrentWeightFromMetrics() ?? wprSystem.currentWeight
        
        wprSystem.updateCurrentMetrics(ftp: currentFTP, weight: currentWeight)
        
        // ワークアウト固有の更新
        switch workout.workoutType {
        case .cycling:
            updateWPRFromCycling(workout, system: wprSystem)
        case .strength:
            updateWPRFromStrength(workout, system: wprSystem)
        case .flexibility:
            updateWPRFromFlexibility(workout, system: wprSystem)
        case .pilates:
            // ピラティスWPR更新は後で実装
            break
        case .yoga:
            // ヨガWPR更新は後で実装
            break
        }
    }
    
    private func updateWPRFromCycling(_ workout: WorkoutRecord, system: WPRTrackingSystem) {
        guard let cyclingDetail = workout.cyclingDetail else { return }
        
        // Efficiency Factor更新
        if let avgHR = cyclingDetail.averageHeartRate, avgHR > 0 {
            let normalizedPower = cyclingDetail.averagePower
            let ef = normalizedPower / Double(avgHR)
            
            // 移動平均でEF更新
            system.efficiencyFactor = (system.efficiencyFactor * 0.8) + (ef * 0.2)
        }
    }
    
    private func updateWPRFromStrength(_ workout: WorkoutRecord, system: WPRTrackingSystem) {
        guard let strengthDetails = workout.strengthDetails else { return }
        
        // Volume Load計算と更新
        let totalVL = strengthDetails.reduce(0.0) { sum, detail in
            sum + (detail.weight * Double(detail.sets * detail.reps))
        }
        
        // 筋力ベースライン更新（指数移動平均）
        system.strengthBaseline = (system.strengthBaseline * 0.9) + (totalVL * 0.0001)
    }
    
    private func updateWPRFromFlexibility(_ workout: WorkoutRecord, system: WPRTrackingSystem) {
        guard let flexDetail = workout.flexibilityDetail else { return }
        
        // ROM改善の統合スコア計算
        let romScore = (flexDetail.averageSplitAngle + flexDetail.forwardBendDistance) / 2.0
        
        // 柔軟性ベースライン更新
        system.flexibilityBaseline = (system.flexibilityBaseline * 0.95) + (romScore * 0.05)
    }
    
    // MARK: - Scientific Metrics Updates
    
    private func updateScientificMetrics(from workout: WorkoutRecord) async {
        switch workout.workoutType {
        case .cycling:
            await updateEfficiencyMetrics(from: workout)
        case .strength:
            await updateVolumeLoadMetrics(from: workout)
        case .flexibility:
            await updateROMMetrics(from: workout)
        case .pilates:
            // ピラティス科学指標更新は後で実装
            break
        case .yoga:
            // ヨガ科学指標更新は後で実装
            break
        }
    }
    
    private func updateEfficiencyMetrics(from workout: WorkoutRecord) async {
        guard let cyclingDetail = workout.cyclingDetail,
              let avgHR = cyclingDetail.averageHeartRate, avgHR > 0 else { return }
        
        let efficiencyMetric = EfficiencyMetrics(
            normalizedPower: cyclingDetail.averagePower,
            averageHeartRate: avgHR,
            duration: Double(cyclingDetail.duration),
            workoutType: "SST"
        )
        
        modelContext.insert(efficiencyMetric)
    }
    
    private func updateVolumeLoadMetrics(from workout: WorkoutRecord) async {
        guard let strengthDetails = workout.strengthDetails else { return }
        
        let volumeCount = extractMuscleGroupSets(from: strengthDetails)
        
        // 週次VolumeLoadSystemの更新または作成
        let vlSystem = getCurrentWeekVolumeLoad() ?? VolumeLoadSystem()
        vlSystem.weeklyPushVL += Double(volumeCount.push) * getAverageWeight(from: strengthDetails, group: .push)
        vlSystem.weeklyPullVL += Double(volumeCount.pull) * getAverageWeight(from: strengthDetails, group: .pull)
        vlSystem.weeklyLegsVL += Double(volumeCount.legs) * getAverageWeight(from: strengthDetails, group: .legs)
        
        // VolumeLoadSystemが既にコンテキストに存在しない場合は挿入
        modelContext.insert(vlSystem)
    }
    
    private func updateROMMetrics(from workout: WorkoutRecord) async {
        guard let flexDetail = workout.flexibilityDetail else { return }
        
        let romTracking = ROMTracking()
        romTracking.forwardBendAngle = flexDetail.forwardBendDistance
        romTracking.hipFlexibility = flexDetail.averageSplitAngle
        romTracking.sessionDuration = Double(flexDetail.duration)
        
        modelContext.insert(romTracking)
    }
    
    // MARK: - Unified Progress Calculation
    
    private func calculateUnifiedProgress() {
        guard let wprSystem = wprSystem else { return }
        
        // WPR進捗スコア（60%）
        let wprProgress = wprSystem.targetProgressRatio * 0.6
        
        // レガシー貯金スコア（40%）
        let legacyProgress = calculateLegacySavingsProgress() * 0.4
        
        // 統合スコア
        totalSavingsScore = wprProgress + legacyProgress
        wprContribution = wprProgress / totalSavingsScore  // WPRの貢献割合
        
        // 統合進捗サマリー作成
        unifiedProgress = UnifiedProgressSummary(
            totalScore: totalSavingsScore,
            wprProgress: wprSystem.targetProgressRatio,
            wprCurrent: wprSystem.calculatedWPR,
            wprTarget: wprSystem.targetWPR,
            legacyProgress: legacyProgress / 0.4,  // 正規化
            sstCount: getSavings(for: .sstCounter)?.currentCount ?? 0,
            strengthVolume: calculateTotalStrengthVolume(),
            flexibilityStreak: calculateLongestFlexibilityStreak(),
            daysToWPRTarget: wprSystem.daysToTarget ?? 999,
            overallConfidence: wprSystem.confidenceLevel
        )
    }
    
    private func calculateLegacySavingsProgress() -> Double {
        let savings = legacySavings
        guard !savings.isEmpty else { return 0.0 }
        
        let progressSum = savings.map { saving in
            Double(saving.currentCount) / Double(saving.targetCount)
        }.reduce(0, +)
        
        return min(progressSum / Double(savings.count), 1.0)
    }
    
    // MARK: - Unified Achievement System
    
    private func generateUnifiedAchievements() {
        var achievements: [UnifiedAchievement] = []
        
        // WPRマイルストーン達成
        if let wprSystem = wprSystem {
            for milestone in WPRMilestone.milestones {
                if wprSystem.calculatedWPR >= milestone.wprValue {
                    achievements.append(UnifiedAchievement(
                        id: UUID(),
                        type: .wprMilestone,
                        title: "WPR \(milestone.wprValue) 達成",
                        description: milestone.description,
                        earnedDate: Date(),
                        badgeEmoji: milestone.badgeEmoji,
                        sourceSystem: .wpr,
                        value: String(format: "%.2f", milestone.wprValue)
                    ))
                }
            }
        }
        
        // レガシー貯金達成（簡易版）
        for saving in legacySavings {
            if saving.isCompleted {
                achievements.append(UnifiedAchievement(
                    id: UUID(),
                    type: .legacySavings,
                    title: "\(saving.savingsType.rawValue) 達成",
                    description: "目標達成",
                    earnedDate: saving.lastUpdated,
                    badgeEmoji: "🏆",
                    sourceSystem: .legacy,
                    value: String(saving.currentCount)
                ))
            }
        }
        
        // 科学的指標達成
        if let wprSystem = wprSystem {
            if wprSystem.efficiencyFactor >= wprSystem.efficiencyTarget {
                achievements.append(UnifiedAchievement(
                    id: UUID(),
                    type: .scientificMetric,
                    title: "効率性目標達成",
                    description: "Efficiency Factor \(wprSystem.efficiencyTarget) 達成",
                    earnedDate: Date(),
                    badgeEmoji: "⚡️",
                    sourceSystem: .scientific,
                    value: String(format: "%.3f", wprSystem.efficiencyFactor)
                ))
            }
        }
        
        unifiedAchievements = achievements.sorted { $0.earnedDate > $1.earnedDate }
    }
    
    // MARK: - Helper Methods
    
    private func loadExistingSystems() {
        // WPRシステムの読み込み
        let wprDescriptor = FetchDescriptor<WPRTrackingSystem>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        
        do {
            let wprSystems = try modelContext.fetch(wprDescriptor)
            wprSystem = wprSystems.first
        } catch {
            Logger.error.error("WPRシステム読み込みエラー: \(error.localizedDescription)")
        }
        
        // レガシー貯金システムの読み込み
        let savingsDescriptor = FetchDescriptor<TrainingSavings>()
        
        do {
            legacySavings = try modelContext.fetch(savingsDescriptor)
        } catch {
            Logger.error.error("レガシー貯金読み込みエラー: \(error.localizedDescription)")
        }
    }
    
    private func initializeLegacySavingsIfNeeded() {
        // 既存のTrainingSavingsが存在しない場合は作成
        if legacySavings.isEmpty {
            for savingsType in SavingsType.allCases {
                let savings = TrainingSavings(savingsType: savingsType, targetCount: savingsType.defaultTarget)
                modelContext.insert(savings)
                legacySavings.append(savings)
            }
        }
    }
    
    private func getSavings(for type: SavingsType) -> TrainingSavings? {
        return legacySavings.first { $0.savingsType == type }
    }
    
    private func getCurrentFTP() -> Int {
        return getCurrentFTPFromHistory() ?? 250  // デフォルトFTP
    }
    
    private func getCurrentWeight() -> Double {
        return getCurrentWeightFromMetrics() ?? 70.0  // デフォルト体重
    }
    
    private func getCurrentFTPFromHistory() -> Int? {
        let descriptor = FetchDescriptor<FTPHistory>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let ftpHistory = try modelContext.fetch(descriptor)
            return ftpHistory.first?.ftpValue
        } catch {
            return nil
        }
    }
    
    private func getCurrentWeightFromMetrics() -> Double? {
        let descriptor = FetchDescriptor<DailyMetric>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let metrics = try modelContext.fetch(descriptor)
            return metrics.first?.weightKg
        } catch {
            return nil
        }
    }
    
    // MARK: - Legacy Support Methods
    
    private func isQualifiedSST(cyclingDetail: CyclingDetail, currentFTP: Int) -> Bool {
        guard cyclingDetail.duration >= 1200 else { return false }  // 20分以上
        guard currentFTP > 0 else { return false }
        
        let sstLowerBound = Double(currentFTP) * 0.88  // FTPの88%
        let sstUpperBound = Double(currentFTP) * 0.94  // FTPの94%
        
        return cyclingDetail.averagePower >= sstLowerBound &&
               cyclingDetail.averagePower <= sstUpperBound
    }
    
    private func extractMuscleGroupSets(from strengthDetails: [StrengthDetail]) -> (push: Int, pull: Int, legs: Int) {
        var push = 0, pull = 0, legs = 0
        
        for detail in strengthDetails {
            let muscleGroup = categorizeMuscleGroup(detail.exercise)
            
            switch muscleGroup {
            case .push:
                push += detail.sets
            case .pull:
                pull += detail.sets
            case .legs:
                legs += detail.sets
            case .none:
                break
            }
        }
        
        return (push, pull, legs)
    }
    
    private func categorizeMuscleGroup(_ exerciseName: String) -> MuscleGroup? {
        let pushExercises = ["ベンチプレス", "ショルダープレス", "ディップス", "腕立て伏せ"]
        let pullExercises = ["懸垂", "プルアップ", "チンアップ", "ラットプルダウン", "ローイング"]
        let legsExercises = ["スクワット", "ランジ", "レッグプレス", "カーフレイズ", "プランク"]
        
        if pushExercises.contains(where: { exerciseName.contains($0) }) {
            return .push
        } else if pullExercises.contains(where: { exerciseName.contains($0) }) {
            return .pull
        } else if legsExercises.contains(where: { exerciseName.contains($0) }) {
            return .legs
        }
        return nil
    }
    
    // 追加のヘルパーメソッド
    private func calculateSSTContributionToWPR(_ sstSavings: TrainingSavings) -> Double {
        return Double(sstSavings.currentCount) * 0.001  // 1回につき0.1%貢献
    }
    
    private func calculateStrengthContributionToWPR(_ volumeCount: (push: Int, pull: Int, legs: Int)) -> Double {
        let totalSets = volumeCount.push + volumeCount.pull + volumeCount.legs
        return Double(totalSets) * 0.0005  // 1セットにつき0.05%貢献
    }
    
    private func calculateFlexibilityContributionToWPR(_ flexDetail: FlexibilityDetail) -> Double {
        return flexDetail.averageSplitAngle * 0.001  // 1度につき0.1%貢献
    }
    
    private func updateMuscleGroupSavings(_ type: SavingsType, sets: Int) {
        guard let savings = getSavings(for: type) else { return }
        savings.currentCount += sets
        savings.lastUpdated = Date()
        checkLegacyMilestones(savings)
    }
    
    private func updateFlexibilityStreak(_ type: SavingsType, date: Date) {
        guard let savings = getSavings(for: type) else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        if let lastStreakDate = savings.lastStreakDate {
            let lastDay = calendar.startOfDay(for: lastStreakDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                savings.currentStreak += 1
                savings.longestStreak = max(savings.longestStreak, savings.currentStreak)
            } else if daysDiff > 1 {
                savings.currentStreak = 1
            }
        } else {
            savings.currentStreak = 1
            savings.longestStreak = 1
        }
        
        savings.lastStreakDate = today
        savings.lastUpdated = Date()
        checkLegacyMilestones(savings)
    }
    
    private func checkLegacyMilestones(_ savings: TrainingSavings) {
        // 簡易版: 目標達成チェックのみ
        if savings.currentCount >= savings.targetCount {
            Logger.general.info("Milestone achieved for \(savings.savingsType.displayName)")
            // TODO: Achievement作成
        }
    }
    
    private func getCurrentWeekVolumeLoad() -> VolumeLoadSystem? {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let descriptor = FetchDescriptor<VolumeLoadSystem>(
            predicate: #Predicate<VolumeLoadSystem> { vlSystem in
                vlSystem.weekStartDate >= weekStart
            }
        )
        
        do {
            let systems = try modelContext.fetch(descriptor)
            return systems.first
        } catch {
            return nil
        }
    }
    
    private func getAverageWeight(from strengthDetails: [StrengthDetail], group: MuscleGroup) -> Double {
        let groupDetails = strengthDetails.filter { detail in
            categorizeMuscleGroup(detail.exercise) == group
        }
        
        guard !groupDetails.isEmpty else { return 0.0 }
        
        let totalWeight = groupDetails.reduce(0.0) { $0 + $1.weight }
        return totalWeight / Double(groupDetails.count)
    }
    
    private func calculateTotalStrengthVolume() -> Double {
        return legacySavings
            .filter { [.pushVolume, .pullVolume, .legsVolume].contains($0.savingsType) }
            .reduce(0.0) { $0 + Double($1.currentCount) }
    }
    
    private func calculateLongestFlexibilityStreak() -> Int {
        return legacySavings
            .filter { [.forwardSplitStreak, .sideSplitStreak, .forwardBendStreak].contains($0.savingsType) }
            .map { $0.longestStreak }
            .max() ?? 0
    }
}

// MARK: - Supporting Data Structures

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