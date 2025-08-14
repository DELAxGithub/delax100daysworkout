import Foundation
import SwiftData
import Combine

// MARK: - Unified Training System Integration (Main Orchestrator)

@MainActor
class WPRTrainingSavingsIntegration: ObservableObject {
    private let core: WPRIntegrationCore
    
    // Exposed properties
    @Published var wprSystem: WPRTrackingSystem?
    @Published var legacySavings: [TrainingSavings] = []
    @Published var unifiedProgress: UnifiedProgressSummary?
    @Published var isUpdating = false
    @Published var lastUpdateDate: Date?
    @Published var unifiedAchievements: [UnifiedAchievement] = []
    @Published var totalSavingsScore: Double = 0.0
    @Published var wprContribution: Double = 0.0
    
    init(modelContext: ModelContext) {
        self.core = WPRIntegrationCore(modelContext: modelContext)
        setupBindings()
    }
    
    // MARK: - Public Interface
    
    /// 既存システムとWPRシステムの初期化
    func initializeUnifiedSystem() {
        core.initializeUnifiedSystem()
    }
    
    /// ワークアウト完了時の統合更新
    func updateFromWorkout(_ workout: WorkoutRecord) {
        core.updateFromWorkout(workout)
    }
    
    /// 統合進捗の再計算
    func calculateUnifiedProgress() {
        core.calculateUnifiedProgress()
    }
    
    /// 統合達成システムの更新
    func generateUnifiedAchievements() {
        core.generateUnifiedAchievements()
    }
    
    // MARK: - Private Setup
    
    private func setupBindings() {
        // Bind core properties to published properties
        core.$wprSystem.assign(to: &$wprSystem)
        core.$legacySavings.assign(to: &$legacySavings)
        core.$unifiedProgress.assign(to: &$unifiedProgress)
        core.$isUpdating.assign(to: &$isUpdating)
        core.$lastUpdateDate.assign(to: &$lastUpdateDate)
        core.$unifiedAchievements.assign(to: &$unifiedAchievements)
        core.$totalSavingsScore.assign(to: &$totalSavingsScore)
        core.$wprContribution.assign(to: &$wprContribution)
    }
}