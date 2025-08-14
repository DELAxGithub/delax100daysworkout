import Foundation
import SwiftData
import Combine
import OSLog

// MARK: - WPR Integration Core

@MainActor
class WPRIntegrationCore: ObservableObject {
    private let modelContext: ModelContext
    private let wprOptimizationEngine: WPROptimizationEngine
    private let bottleneckSystem: BottleneckDetectionSystem
    
    // Services
    private let savingsCalculator: SavingsCalculator
    private let metricsCalculator: MetricsCalculator
    private let trainingDataIntegration: TrainingDataIntegration
    private let achievementSystem: AchievementSystem
    
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
        
        // Initialize services
        self.savingsCalculator = SavingsCalculator(modelContext: modelContext)
        self.metricsCalculator = MetricsCalculator(modelContext: modelContext)
        self.trainingDataIntegration = TrainingDataIntegration(modelContext: modelContext)
        self.achievementSystem = AchievementSystem(modelContext: modelContext)
        
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
            await trainingDataIntegration.updateLegacySavings(from: workout, legacySavings: legacySavings)
            
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
    
    // MARK: - Progress Calculation
    
    func calculateUnifiedProgress() {
        unifiedProgress = metricsCalculator.calculateUnifiedProgress(
            wprSystem: wprSystem,
            legacySavings: legacySavings
        )
        
        // 総合スコア更新
        totalSavingsScore = legacySavings.map { $0.estimatedWPRContribution }.reduce(0, +)
        wprContribution = wprSystem?.currentWPR ?? 0.0
    }
    
    func generateUnifiedAchievements() {
        unifiedAchievements = achievementSystem.generateUnifiedAchievements(
            wprSystem: wprSystem,
            legacySavings: legacySavings,
            unifiedProgress: unifiedProgress
        )
    }
    
    // MARK: - System Updates
    
    private func updateWPRSystem(from workout: WorkoutRecord) async {
        guard let wprSystem = wprSystem else { return }
        
        switch workout.workoutType {
        case .cycling:
            if let cyclingDetail = workout.cyclingDetail {
                await updateWPRFromCycling(wprSystem, cyclingDetail: cyclingDetail)
            }
        case .strength:
            if let strengthDetails = workout.strengthDetails {
                await updateWPRFromStrength(wprSystem, strengthDetails: strengthDetails)
            }
        case .flexibility:
            if let flexDetail = workout.flexibilityDetail {
                await updateWPRFromFlexibility(wprSystem, flexDetail: flexDetail)
            }
        case .pilates, .yoga:
            // Future implementation
            break
        }
        
        wprSystem.lastUpdated = Date()
    }
    
    private func updateWPRFromCycling(
        _ wprSystem: WPRTrackingSystem,
        cyclingDetail: CyclingDetail
    ) async {
        // SST寄与度計算
        if let currentFTP = getCurrentFTPFromHistory(),
           savingsCalculator.isQualifiedSST(cyclingDetail: cyclingDetail, currentFTP: currentFTP) {
            wprSystem.efficiencyFactor += 0.01  // 1%改善
        }
        
        // 基本的なサイクリング寄与度
        let intensityContribution = Double(cyclingDetail.intensity.rawValue.count) * 0.002
        wprSystem.efficiencyFactor += intensityContribution
    }
    
    private func updateWPRFromStrength(
        _ wprSystem: WPRTrackingSystem,
        strengthDetails: [StrengthDetail]
    ) async {
        let volumeCount = savingsCalculator.extractMuscleGroupSets(from: strengthDetails)
        let strengthContribution = savingsCalculator.calculateStrengthContributionToWPR(volumeCount)
        wprSystem.strengthBaseline += strengthContribution * 0.005  // 0.5%改善
    }
    
    private func updateWPRFromFlexibility(
        _ wprSystem: WPRTrackingSystem,
        flexDetail: FlexibilityDetail
    ) async {
        let flexibilityContribution = savingsCalculator.calculateFlexibilityContributionToWPR(flexDetail)
        wprSystem.flexibilityBaseline += flexibilityContribution * 0.002  // 0.2%改善
    }
    
    private func updateScientificMetrics(from workout: WorkoutRecord) async {
        // 科学的指標の更新ロジック
        // 実装は必要に応じて追加
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
}