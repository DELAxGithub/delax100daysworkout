import Foundation
import SwiftData

/// WorkoutRecord変更時にWPRTrackingSystemを自動更新するサービス
@MainActor
class WPRAutoUpdateService: @unchecked Sendable {
    private let modelContext: ModelContext
    private var wprSystem: WPRTrackingSystem?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateWPRSystem()
    }
    
    // MARK: - WPRシステム初期化
    
    private func loadOrCreateWPRSystem() {
        do {
            let descriptor = FetchDescriptor<WPRTrackingSystem>()
            let systems = try modelContext.fetch(descriptor)
            
            if let existingSystem = systems.first {
                wprSystem = existingSystem
            } else {
                // 新規WPRシステム作成
                let newSystem = WPRTrackingSystem()
                modelContext.insert(newSystem)
                wprSystem = newSystem
                
                // 初期値設定（既存のFTPHistoryとDailyMetricから）
                setupInitialWPRValues(system: newSystem)
            }
        } catch {
            print("WPRTrackingSystem読み込みエラー: \(error)")
        }
    }
    
    private func setupInitialWPRValues(system: WPRTrackingSystem) {
        // 最新のFTPを取得
        if let latestFTP = getLatestFTP() {
            system.baselineFTP = latestFTP
            system.currentFTP = latestFTP
        }
        
        // 最新の体重を取得
        if let latestWeight = getLatestWeight() {
            system.baselineWeight = latestWeight
            system.currentWeight = latestWeight
        }
        
        // デフォルトのエビデンスベース係数を設定
        system.resetToEvidenceBasedCoefficients()
        
        try? modelContext.save()
    }
    
    // MARK: - WorkoutRecord更新処理
    
    /// 新しいWorkoutRecordが追加された時の処理
    func handleNewWorkoutRecord(_ record: WorkoutRecord) {
        guard let system = wprSystem else { return }
        
        switch record.workoutType {
        case .cycling:
            updateFromCyclingRecord(record, system: system)
        case .strength:
            updateFromStrengthRecord(record, system: system)
        case .flexibility:
            updateFromFlexibilityRecord(record, system: system)
        }
        
        // 全体的な進捗スコア再計算
        recalculateOverallProgress(system: system)
        
        try? modelContext.save()
    }
    
    /// WorkoutRecordが更新された時の処理
    func handleUpdatedWorkoutRecord(_ record: WorkoutRecord) {
        handleNewWorkoutRecord(record) // 同じロジックを使用
    }
    
    // MARK: - サイクリングデータからの更新
    
    private func updateFromCyclingRecord(_ record: WorkoutRecord, system: WPRTrackingSystem) {
        guard let cyclingDetail = record.cyclingDetail else { return }
        
        // 効率性指標の更新（SSTワークアウトの場合）
        if cyclingDetail.intensity == .sst {
            updateEfficiencyFactor(from: cyclingDetail, system: system)
        }
        
        // パワープロファイルの更新
        updatePowerProfile(from: cyclingDetail, system: system)
        
        // HR効率の更新
        updateHREfficiency(from: cyclingDetail, system: system)
        
        system.lastUpdated = Date()
    }
    
    private func updateEfficiencyFactor(from detail: CyclingDetail, system: WPRTrackingSystem) {
        // Efficiency Factor = NP / Average HR
        guard let normalizedPower = detail.normalizedPower,
              let averageHR = detail.averageHeartRate,
              averageHR > 0 else { return }
        
        let currentEF = normalizedPower / Double(averageHR)
        
        // 移動平均でEfficiency Factorを更新
        if system.efficiencyFactor > 0 {
            system.efficiencyFactor = (system.efficiencyFactor * 0.7) + (currentEF * 0.3)
        } else {
            system.efficiencyFactor = currentEF
        }
    }
    
    private func updatePowerProfile(from detail: CyclingDetail, system: WPRTrackingSystem) {
        // パワープロファイルスコアの改善を計算
        let powerImprovement = calculatePowerImprovement(detail)
        
        // ベースラインからの改善率を更新
        if system.powerProfileBaseline == 0 {
            system.powerProfileBaseline = detail.averagePower
        }
        
        let currentImprovement = (detail.averagePower - system.powerProfileBaseline) / system.powerProfileBaseline
        
        // 移動平均で更新
        system.powerProfileBaseline = max(system.powerProfileBaseline, detail.averagePower * 0.1 + system.powerProfileBaseline * 0.9)
    }
    
    private func updateHREfficiency(from detail: CyclingDetail, system: WPRTrackingSystem) {
        guard let averageHR = detail.averageHeartRate,
              detail.averagePower > 0 else { return }
        
        // 同等パワーでの心拍数効率を計算
        let hrAtPower = Double(averageHR) / detail.averagePower * 100 // HR per 100W
        
        if system.hrEfficiencyBaseline == 0 {
            system.hrEfficiencyBaseline = hrAtPower
        } else {
            // より低い心拍数は改善を意味する
            system.hrEfficiencyBaseline = min(system.hrEfficiencyBaseline, hrAtPower * 0.2 + system.hrEfficiencyBaseline * 0.8)
        }
    }
    
    // MARK: - 筋トレデータからの更新
    
    private func updateFromStrengthRecord(_ record: WorkoutRecord, system: WPRTrackingSystem) {
        guard let strengthDetails = record.strengthDetails else { return }
        
        // Volume Load計算
        let totalVolumeLoad = strengthDetails.reduce(0.0) { total, detail in
            return total + (detail.weight * Double(detail.reps * detail.sets))
        }
        
        // ベースラインVolume Loadの設定・更新
        if system.strengthBaseline == 0 {
            system.strengthBaseline = totalVolumeLoad
        } else {
            // 移動平均で更新（進歩的オーバーロード）
            system.strengthBaseline = max(system.strengthBaseline, totalVolumeLoad * 0.3 + system.strengthBaseline * 0.7)
        }
        
        system.lastUpdated = Date()
    }
    
    // MARK: - 柔軟性データからの更新
    
    private func updateFromFlexibilityRecord(_ record: WorkoutRecord, system: WPRTrackingSystem) {
        guard let flexibilityDetail = record.flexibilityDetail else { return }
        
        // ROM (Range of Motion) の改善を追跡
        let currentROM = flexibilityDetail.averageSplitAngle
        
        if system.flexibilityBaseline == 0 {
            system.flexibilityBaseline = currentROM
        } else {
            // より良い柔軟性は高い角度を意味する
            system.flexibilityBaseline = max(system.flexibilityBaseline, currentROM * 0.4 + system.flexibilityBaseline * 0.6)
        }
        
        system.lastUpdated = Date()
    }
    
    // MARK: - 全体進捗の再計算
    
    private func recalculateOverallProgress(system: WPRTrackingSystem) {
        // 各指標の進捗率を計算
        let efficiencyProgress = system.efficiencyProgress
        let powerProgress = system.powerProfileProgress
        let hrProgress = calculateHRProgress(system: system)
        let strengthProgress = calculateStrengthProgress(system: system)
        let flexibilityProgress = calculateFlexibilityProgress(system: system)
        
        // 重み付き平均で全体進捗を計算
        system.overallProgressScore = 
            efficiencyProgress * system.efficiencyCoefficient +
            powerProgress * system.powerProfileCoefficient +
            hrProgress * system.hrEfficiencyCoefficient +
            strengthProgress * system.strengthCoefficient +
            flexibilityProgress * system.flexibilityCoefficient
        
        // ボトルネック検出
        updateCurrentBottleneck(system: system)
        
        // WPR予測の更新
        updateWPRProjection(system: system)
    }
    
    private func calculateHRProgress(system: WPRTrackingSystem) -> Double {
        guard system.hrEfficiencyBaseline > 0 else { return 0.0 }
        
        // 心拍効率の改善は値の減少として表現される
        let improvement = (system.hrEfficiencyBaseline - abs(system.hrEfficiencyTarget)) / system.hrEfficiencyBaseline
        return max(0.0, min(1.0, improvement))
    }
    
    private func calculateStrengthProgress(system: WPRTrackingSystem) -> Double {
        guard system.strengthBaseline > 0, system.strengthTarget > 0 else { return 0.0 }
        
        let progress = system.strengthBaseline / (system.strengthBaseline * (1.0 + system.strengthTarget))
        return max(0.0, min(1.0, progress))
    }
    
    private func calculateFlexibilityProgress(system: WPRTrackingSystem) -> Double {
        guard system.flexibilityBaseline > 0, system.flexibilityTarget > 0 else { return 0.0 }
        
        let progress = (system.flexibilityBaseline - system.flexibilityBaseline) / system.flexibilityTarget
        return max(0.0, min(1.0, progress))
    }
    
    private func updateCurrentBottleneck(system: WPRTrackingSystem) {
        // 各指標の進捗率を比較してボトルネックを特定
        let progresses = [
            (BottleneckType.efficiency, system.efficiencyProgress),
            (BottleneckType.power, system.powerProfileProgress),
            (BottleneckType.cardio, calculateHRProgress(system: system)),
            (BottleneckType.strength, calculateStrengthProgress(system: system)),
            (BottleneckType.flexibility, calculateFlexibilityProgress(system: system))
        ]
        
        // 最も進捗が遅い項目をボトルネックとする
        if let bottleneck = progresses.min(by: { $0.1 < $1.1 }) {
            system.currentBottleneck = bottleneck.0
        }
    }
    
    private func updateWPRProjection(system: WPRTrackingSystem) {
        // 現在の進捗率から目標達成日数を推定
        let currentProgress = system.targetProgressRatio
        let timeElapsed = Date().timeIntervalSince(system.createdDate) / (24 * 60 * 60) // 日数
        
        if currentProgress > 0 && timeElapsed > 0 {
            let estimatedTotalDays = timeElapsed / currentProgress
            let remainingDays = max(0, estimatedTotalDays - timeElapsed)
            
            system.daysToTarget = Int(remainingDays)
            
            // 信頼度計算（データポイント数と一貫性に基づく）
            system.confidenceLevel = calculateConfidenceLevel(
                dataPoints: Int(timeElapsed),
                progressConsistency: system.overallProgressScore
            )
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    private func calculatePowerImprovement(_ detail: CyclingDetail) -> Double {
        // パワー改善の計算ロジック（プレースホルダー）
        return detail.averagePower > 200 ? 0.1 : 0.05
    }
    
    private func calculateConfidenceLevel(dataPoints: Int, progressConsistency: Double) -> Double {
        let dataConfidence = min(Double(dataPoints) / 30.0, 1.0) // 30日で100%
        let consistencyConfidence = progressConsistency
        
        return (dataConfidence + consistencyConfidence) / 2.0
    }
    
    private func getLatestFTP() -> Int? {
        do {
            var descriptor = FetchDescriptor<FTPHistory>()
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            descriptor.fetchLimit = 1
            
            let ftpRecords = try modelContext.fetch(descriptor)
            return ftpRecords.first?.ftpValue
        } catch {
            print("FTP取得エラー: \(error)")
            return nil
        }
    }
    
    private func getLatestWeight() -> Double? {
        do {
            var descriptor = FetchDescriptor<DailyMetric>()
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            descriptor.fetchLimit = 1
            
            let metrics = try modelContext.fetch(descriptor)
            return metrics.first?.weightKg
        } catch {
            print("体重取得エラー: \(error)")
            return nil
        }
    }
}

// MARK: - WorkoutRecord Extension for Auto-Update

extension WorkoutRecord {
    /// WorkoutRecordが保存された後にWPR自動更新を実行
    @MainActor
    func triggerWPRUpdate(context: ModelContext) {
        let updateService = WPRAutoUpdateService(modelContext: context)
        updateService.handleNewWorkoutRecord(self)
    }
}