import Foundation
import SwiftData
import Combine

// MARK: - WPR Optimization Engine

@MainActor
class WPROptimizationEngine: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    @Published var analysisError: String?
    
    // 統計分析結果
    @Published var currentBottleneck: BottleneckType = .efficiency
    @Published var recommendedActions: [String] = []
    @Published var confidenceLevel: Double = 0.0
    
    // 予測結果
    @Published var projectedWPRIn30Days: Double = 0.0
    @Published var projectedWPRIn60Days: Double = 0.0
    @Published var projectedWPRIn100Days: Double = 0.0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Core Algorithm Methods
    
    /// 多変量重み付け進捗スコア計算
    func calculateProgressScore(_ system: WPRTrackingSystem) -> Double {
        var score = 0.0
        var validComponents = 0
        
        // 1. Efficiency Factor寄与 (25%)
        if system.efficiencyFactor > 0 {
            let efImprovement = normalizeMetric(
                current: system.efficiencyFactor,
                baseline: system.efficiencyBaseline,
                target: system.efficiencyTarget
            )
            score += efImprovement * system.efficiencyCoefficient
            validComponents += 1
        }
        
        // 2. Power Profile寄与 (30%)
        if let powerProfile = getLatestPowerProfile() {
            let ppImprovement = calculatePowerProfileScore(powerProfile)
            score += ppImprovement * system.powerProfileCoefficient
            validComponents += 1
        }
        
        // 3. HR Efficiency寄与 (15%)
        if let hrMetrics = getLatestHRAtPowerTracking() {
            let hrImprovement = calculateHREfficiencyScore(hrMetrics)
            score += hrImprovement * system.hrEfficiencyCoefficient
            validComponents += 1
        }
        
        // 4. 筋力Volume Load寄与 (20%)
        if let vlMetrics = getLatestVolumeLoadSystem() {
            let vlImprovement = calculateVolumeLoadScore(vlMetrics)
            score += vlImprovement * system.strengthCoefficient
            validComponents += 1
        }
        
        // 5. 柔軟性ROM寄与 (10%)
        if let romMetrics = getLatestROMTracking() {
            let romImprovement = calculateROMScore(romMetrics)
            score += romImprovement * system.flexibilityCoefficient
            validComponents += 1
        }
        
        // スコア正規化（有効なコンポーネントがある場合のみ）
        return validComponents > 0 ? min(score, 1.0) : 0.0
    }
    
    /// ボトルネック検出 (Z-score基準)
    func detectBottleneck(_ system: WPRTrackingSystem) -> BottleneckType {
        var metrics: [(String, Double)] = []
        
        // 各指標の正規化スコア収集
        if system.efficiencyFactor > 0 {
            let efScore = normalizeMetric(
                current: system.efficiencyFactor,
                baseline: system.efficiencyBaseline,
                target: system.efficiencyTarget
            )
            metrics.append(("efficiency", efScore))
        }
        
        if let powerProfile = getLatestPowerProfile() {
            let ppScore = calculatePowerProfileScore(powerProfile)
            metrics.append(("power", ppScore))
        }
        
        if let hrMetrics = getLatestHRAtPowerTracking() {
            let hrScore = calculateHREfficiencyScore(hrMetrics)
            metrics.append(("cardio", hrScore))
        }
        
        if let vlMetrics = getLatestVolumeLoadSystem() {
            let vlScore = calculateVolumeLoadScore(vlMetrics)
            metrics.append(("strength", vlScore))
        }
        
        if let romMetrics = getLatestROMTracking() {
            let romScore = calculateROMScore(romMetrics)
            metrics.append(("flexibility", romScore))
        }
        
        guard !metrics.isEmpty else { return .efficiency }
        
        // Z-score計算
        let values = metrics.map { $0.1 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        guard standardDeviation > 0 else { return .efficiency }
        
        let zScores = values.enumerated().map { (index, value) in
            ((value - mean) / standardDeviation, metrics[index].0)
        }
        
        // 最低Z-scoreが現在のボトルネック
        let bottleneckIndex = zScores.enumerated().min(by: { $0.element.0 < $1.element.0 })?.offset ?? 0
        let bottleneckName = metrics[bottleneckIndex].0
        
        // BottleneckType mapping
        switch bottleneckName {
        case "efficiency": return .efficiency
        case "power": return .power
        case "cardio": return .cardio
        case "strength": return .strength
        case "flexibility": return .flexibility
        default: return .efficiency
        }
    }
    
    /// WPR進歩予測モデル
    func predictWPRProgression(_ system: WPRTrackingSystem, days: Int) -> WPRProjection {
        let currentScore = calculateProgressScore(system)
        let bottleneck = detectBottleneck(system)
        
        // 改善率の算出（過去のデータベース）
        let improvementRate = calculateImprovementRate(system)
        let projectedScore = min(currentScore + (improvementRate * Double(days) / 30.0), 1.0)
        
        // WPR予測計算
        let currentWPR = system.calculatedWPR
        let targetGain = system.targetWPR - currentWPR
        let projectedGain = targetGain * projectedScore
        let projectedWPR = currentWPR + projectedGain
        
        // 信頼度計算
        let confidence = calculateConfidenceLevel(system, projectedScore: projectedScore)
        
        // 推奨アクション生成
        let actions = generateRecommendedActions(bottleneck: bottleneck, system: system)
        
        return WPRProjection(
            currentWPR: currentWPR,
            projectedWPR: projectedWPR,
            daysToTarget: calculateDaysToTarget(system, improvementRate: improvementRate),
            confidenceLevel: confidence,
            bottleneck: bottleneck,
            recommendedActions: actions
        )
    }
    
    // MARK: - Individual Metric Calculations
    
    private func calculatePowerProfileScore(_ powerProfile: PowerProfile) -> Double {
        return powerProfile.improvementScore
    }
    
    private func calculateHREfficiencyScore(_ hrMetrics: HRAtPowerTracking) -> Double {
        return max(hrMetrics.efficiencyImprovement, 0.0)
    }
    
    private func calculateVolumeLoadScore(_ vlMetrics: VolumeLoadSystem) -> Double {
        return max(vlMetrics.improvementScore, 0.0)
    }
    
    private func calculateROMScore(_ romMetrics: ROMTracking) -> Double {
        return max(romMetrics.improvementScore, 0.0)
    }
    
    // MARK: - Helper Methods
    
    /// 指標正規化（0.0-1.0範囲）
    private func normalizeMetric(current: Double, baseline: Double, target: Double) -> Double {
        guard target != baseline else { return 0.0 }
        
        let progress = (current - baseline) / (target - baseline)
        return max(min(progress, 1.0), 0.0)
    }
    
    /// 改善率計算（過去30日の傾向）
    private func calculateImprovementRate(_ system: WPRTrackingSystem) -> Double {
        // TODO: 過去データからトレンド分析
        // 現在は固定値、実装時に実データベースの回帰分析
        return 0.02  // 月2%改善と仮定
    }
    
    /// 目標到達日数予測
    private func calculateDaysToTarget(_ system: WPRTrackingSystem, improvementRate: Double) -> Int {
        let currentScore = calculateProgressScore(system)
        let remainingProgress = 1.0 - currentScore
        
        guard improvementRate > 0 else { return 999 }
        
        let remainingDays = (remainingProgress / improvementRate) * 30.0
        return max(Int(remainingDays), 1)
    }
    
    /// 信頼度レベル計算
    private func calculateConfidenceLevel(_ system: WPRTrackingSystem, projectedScore: Double) -> Double {
        var confidence = 0.8  // ベース信頼度
        
        // データ品質による調整
        let validMetricsCount = [
            system.efficiencyFactor > 0,
            getLatestPowerProfile() != nil,
            getLatestHRAtPowerTracking() != nil,
            getLatestVolumeLoadSystem() != nil,
            getLatestROMTracking() != nil
        ].filter { $0 }.count
        
        confidence *= Double(validMetricsCount) / 5.0
        
        // 予測の妥当性チェック
        if projectedScore > 0.9 {
            confidence *= 0.9  // 過度に楽観的な予測は信頼度低下
        }
        
        return max(min(confidence, 1.0), 0.1)
    }
    
    /// 推奨アクション生成
    private func generateRecommendedActions(bottleneck: BottleneckType, system: WPRTrackingSystem) -> [String] {
        var actions: [String] = []
        
        switch bottleneck {
        case .efficiency:
            actions.append("SST（Sweet Spot Training）の頻度を週2回に増加")
            actions.append("20分間の閾値強度（FTP 88-94%）を維持するトレーニング")
            actions.append("心拍数とパワーの効率比改善に重点")
            
        case .power:
            actions.append("パワープロファイル全領域の強化")
            actions.append("5秒・1分・5分・20分・60分の各時間域でのインターバル")
            actions.append("月1回のパワーテストで進捗確認")
            
        case .cardio:
            actions.append("固定ワット数での心拍数低下トレーニング")
            actions.append("Zone 2（有酸素ベース）の長時間ライド")
            actions.append("心拍変動（HRV）モニタリングで回復管理")
            
        case .strength:
            actions.append("Volume Load月間30%増加目標")
            actions.append("Push/Pull/Legs各筋群の週28-30セット")
            actions.append("漸進的過負荷とRPE管理の併用")
            
        case .flexibility:
            actions.append("毎日15分のストレッチルーチン")
            actions.append("股関節・肩・脊椎の可動域拡大重点")
            actions.append("動的ストレッチとスタティックストレッチの組み合わせ")
            
        case .weight:
            actions.append("体重管理とBody Composition改善")
            actions.append("適切なカロリー収支と栄養バランス")
            actions.append("筋量維持しながらの体脂肪削減")
        }
        
        return actions
    }
    
    // MARK: - Data Fetching Methods
    
    private func getLatestPowerProfile() -> PowerProfile? {
        let descriptor = FetchDescriptor<PowerProfile>(
            sortBy: [SortDescriptor(\.testDate, order: .reverse)]
        )
        
        do {
            let profiles = try modelContext.fetch(descriptor)
            return profiles.first
        } catch {
            analysisError = "PowerProfile取得エラー: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func getLatestHRAtPowerTracking() -> HRAtPowerTracking? {
        let descriptor = FetchDescriptor<HRAtPowerTracking>(
            sortBy: [SortDescriptor(\.testDate, order: .reverse)]
        )
        
        do {
            let tracking = try modelContext.fetch(descriptor)
            return tracking.first
        } catch {
            analysisError = "HRAtPowerTracking取得エラー: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func getLatestVolumeLoadSystem() -> VolumeLoadSystem? {
        let descriptor = FetchDescriptor<VolumeLoadSystem>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        
        do {
            let systems = try modelContext.fetch(descriptor)
            return systems.first
        } catch {
            analysisError = "VolumeLoadSystem取得エラー: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func getLatestROMTracking() -> ROMTracking? {
        let descriptor = FetchDescriptor<ROMTracking>(
            sortBy: [SortDescriptor(\.measurementDate, order: .reverse)]
        )
        
        do {
            let tracking = try modelContext.fetch(descriptor)
            return tracking.first
        } catch {
            analysisError = "ROMTracking取得エラー: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func getLatestEfficiencyMetrics() -> EfficiencyMetrics? {
        let descriptor = FetchDescriptor<EfficiencyMetrics>(
            sortBy: [SortDescriptor(\.measurementDate, order: .reverse)]
        )
        
        do {
            let metrics = try modelContext.fetch(descriptor)
            return metrics.first
        } catch {
            analysisError = "EfficiencyMetrics取得エラー: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Public Analysis Methods
    
    /// 完全分析実行
    func performCompleteAnalysis(_ system: WPRTrackingSystem) async {
        await MainActor.run {
            isAnalyzing = true
            analysisError = nil
        }
        
        // バックグラウンドで分析実行
        await Task.detached { [weak self] in
            guard let self = self else { return }
            
            let progressScore = await self.calculateProgressScore(system)
            let bottleneck = await self.detectBottleneck(system)
            let projection30 = await self.predictWPRProgression(system, days: 30)
            let projection60 = await self.predictWPRProgression(system, days: 60)
            let projection100 = await self.predictWPRProgression(system, days: 100)
            
            await MainActor.run {
                system.overallProgressScore = progressScore
                system.currentBottleneck = bottleneck
                system.projectedWPRGain = projection100.projectedWPR - system.calculatedWPR
                system.daysToTarget = projection100.daysToTarget
                system.confidenceLevel = projection100.confidenceLevel
                system.lastUpdated = Date()
                
                self.currentBottleneck = bottleneck
                self.recommendedActions = projection100.recommendedActions
                self.confidenceLevel = projection100.confidenceLevel
                self.projectedWPRIn30Days = projection30.projectedWPR
                self.projectedWPRIn60Days = projection60.projectedWPR
                self.projectedWPRIn100Days = projection100.projectedWPR
                
                self.isAnalyzing = false
                self.lastAnalysisDate = Date()
            }
            
            // Swift 6 Sendable対応・データベース保存 (Issue #33)
            do {
                await MainActor.run {
                    do {
                        try self.modelContext.save()
                    } catch {
                        self.analysisError = "保存エラー: \(error.localizedDescription)"
                    }
                }
            }
        }.value
    }
    
    /// クイック分析（UI更新用）
    func performQuickAnalysis(_ system: WPRTrackingSystem) {
        let progressScore = calculateProgressScore(system)
        let bottleneck = detectBottleneck(system)
        
        system.overallProgressScore = progressScore
        system.currentBottleneck = bottleneck
        system.lastUpdated = Date()
        
        currentBottleneck = bottleneck
        confidenceLevel = calculateConfidenceLevel(system, projectedScore: progressScore)
    }
}

// MARK: - Supporting Data Structures

struct ScientificAnalyisResult {
    let progressScore: Double
    let bottleneck: BottleneckType
    let recommendations: [String]
    let confidence: Double
    let analysisDate: Date
    
    var summary: String {
        let progressPercent = Int(progressScore * 100)
        return "進捗スコア: \(progressPercent)%\nボトルネック: \(bottleneck.rawValue)\n信頼度: \(Int(confidence * 100))%"
    }
}

extension WPROptimizationEngine {
    /// デバッグ用サンプル分析結果
    static func sampleAnalysisResult() -> ScientificAnalyisResult {
        return ScientificAnalyisResult(
            progressScore: 0.64,
            bottleneck: .strength,
            recommendations: [
                "Volume Load月間30%増加目標",
                "Push/Pull/Legs各筋群の週28-30セット",
                "漸進的過負荷とRPE管理の併用"
            ],
            confidence: 0.85,
            analysisDate: Date()
        )
    }
}