import Foundation
import SwiftData

// MARK: - WPR AI Analysis Integration

extension WeeklyPlanAIService {
    
    /// WPR最適化を考慮したAI分析データ生成
    func generateWPROptimizedAnalysisData(
        wprSystem: WPRTrackingSystem,
        bottlenecks: [BottleneckAnalysis],
        unifiedProgress: UnifiedProgressSummary?
    ) -> WPREnhancedAnalysisRequest {
        
        // Base analysis data structure - would be populated from WeeklyPlanAIService
        // Currently using template structure for WPR integration
        let baseAnalysis = AIAnalysisRequest(
            weeklyStats: WeeklyStats(
                weekStartDate: Date(),
                totalWorkouts: 0,
                completedWorkouts: 0,
                cyclingStats: WorkoutTypeStats(type: .cycling, completed: 0, target: 0, improvements: [], averageMetric: 0.0),
                strengthStats: WorkoutTypeStats(type: .strength, completed: 0, target: 0, improvements: [], averageMetric: 0.0),
                flexibilityStats: WorkoutTypeStats(type: .flexibility, completed: 0, target: 0, improvements: [], averageMetric: 0.0),
                achievements: []
            ),
            progress: Progress(
                currentStreak: 0,
                longestStreak: 0,
                totalWorkouts: 0,
                weeklyAverage: 0.0,
                recentAchievements: []
            ),
            currentTemplate: WeeklyTemplate(name: "Default Template"),
            userPreferences: UserPreferences(
                preferredWorkoutDays: [],
                availableTime: 60,
                fitnessGoals: [],
                limitations: []
            )
        )
        
        // WPR特化の追加データ
        let wprData = WPRAnalysisData(
            currentWPR: wprSystem.calculatedWPR,
            targetWPR: wprSystem.targetWPR,
            progressPercentage: wprSystem.targetProgressRatio * 100,
            daysToTarget: wprSystem.daysToTarget ?? 999,
            confidenceLevel: wprSystem.confidenceLevel,
            primaryBottleneck: bottlenecks.first?.bottleneckType.rawValue ?? "なし",
            scientificMetrics: ScientificMetricsData(
                efficiencyFactor: wprSystem.efficiencyFactor,
                efProgress: wprSystem.efficiencyProgress * 100,
                powerProfileProgress: wprSystem.powerProfileProgress * 100,
                strengthProgress: (wprSystem.strengthBaseline / wprSystem.strengthTarget) * 100,
                flexibilityProgress: (wprSystem.flexibilityBaseline / wprSystem.flexibilityTarget) * 100
            ),
            bottleneckAnalysis: bottlenecks.map { bottleneck in
                BottleneckData(
                    type: bottleneck.bottleneckType.rawValue,
                    severity: bottleneck.severity.rawValue,
                    gapPercentage: bottleneck.gapPercentage,
                    impactOnWPR: bottleneck.impactOnWPR * 100,
                    timeToResolve: bottleneck.timeToResolve,
                    recommendedProtocols: bottleneck.recommendedProtocols.map { trainingProtocol in
                        ProtocolData(
                            name: trainingProtocol.name,
                            frequency: trainingProtocol.frequency,
                            duration: trainingProtocol.duration,
                            intensity: trainingProtocol.intensity,
                            expectedImprovement: trainingProtocol.expectedImprovement * 100,
                            evidenceBase: trainingProtocol.evidenceBase
                        )
                    }
                )
            }
        )
        
        // 統合レスポンス生成
        return WPREnhancedAnalysisRequest(
            baseRequest: baseAnalysis,
            wprData: wprData,
            unifiedProgress: unifiedProgress
        )
    }
    
    /// WPR特化のプロンプト生成
    func generateWPROptimizedPrompt(analysisData: WPREnhancedAnalysisRequest) -> String {
        guard let wprData = analysisData.wprData else {
            // Fallback to base analysis when WPR data not available
            // Base prompt generation handled by WeeklyPlanAIService
            return "標準的なトレーニング分析を実行中..."
        }
        
        return """
        # WPR 4.5達成のための科学的トレーニング分析

        ## 現在の状況
        - **現在のWPR**: \(String(format: "%.2f", wprData.currentWPR)) W/kg
        - **目標WPR**: \(String(format: "%.1f", wprData.targetWPR)) W/kg
        - **進捗率**: \(String(format: "%.1f", wprData.progressPercentage))%
        - **目標達成まで**: \(wprData.daysToTarget)日（信頼度: \(String(format: "%.0f", wprData.confidenceLevel * 100))%）

        ## 科学的指標の現状
        - **効率性 (EF)**: \(String(format: "%.3f", wprData.scientificMetrics.efficiencyFactor)) (進捗: \(String(format: "%.1f", wprData.scientificMetrics.efProgress))%)
        - **パワープロファイル**: 進捗 \(String(format: "%.1f", wprData.scientificMetrics.powerProfileProgress))%
        - **筋力開発**: 進捗 \(String(format: "%.1f", wprData.scientificMetrics.strengthProgress))%
        - **柔軟性**: 進捗 \(String(format: "%.1f", wprData.scientificMetrics.flexibilityProgress))%

        ## 主要ボトルネック
        **優先度1**: \(wprData.primaryBottleneck)
        
        \(generateBottleneckAnalysisText(wprData.bottleneckAnalysis))

        ## エビデンスベース要求事項
        以下の科学的研究に基づいて分析してください：
        1. **Seiler & Tønnessen (2009)**: 閾値トレーニング最適頻度
        2. **Krzysztofik et al. (2019)**: 筋肥大のための最適ボリューム
        3. **Hopker et al. (2010)**: サイクリング効率と体重の関係
        4. **Vikmoen et al. (2021)**: 筋トレによるパワー向上
        5. **Holliday et al. (2021)**: 柔軟性とパワー出力の相関

        ## 分析依頼内容
        1. **ボトルネック解決の優先順位**: どの指標を最初に改善すべきか
        2. **具体的なトレーニング処方**: 週次プランの提案
        3. **リスク評価**: オーバーウトレーニングや怪我のリスク
        4. **WPR 4.5達成のロードマップ**: 段階的な目標設定
        5. **モチベーション維持戦略**: 科学的根拠を示しながらの励まし

        ## 回答形式
        - 具体的な数値目標を含む
        - 各提案に科学的根拠を併記
        - 実行可能性を重視した現実的な提案
        - ユーザーの理解しやすい日本語で回答

        ※ 週間統計データ: 実装予定
        """
    }
    
    private func generateBottleneckAnalysisText(_ bottlenecks: [BottleneckData]) -> String {
        guard !bottlenecks.isEmpty else { return "ボトルネックは検出されていません。" }
        
        var text = ""
        for (index, bottleneck) in bottlenecks.enumerated() {
            text += """
            
            **\(index + 1). \(bottleneck.type)** (\(bottleneck.severity))
            - ギャップ: \(String(format: "%.1f", bottleneck.gapPercentage))%
            - WPR影響度: \(String(format: "%.1f", bottleneck.impactOnWPR))%
            - 解決予想期間: \(bottleneck.timeToResolve)日
            
            推奨プロトコル:
            """
            
            for trainingProtocol in bottleneck.recommendedProtocols.prefix(2) {
                text += """
                - **\(trainingProtocol.name)**: \(trainingProtocol.frequency), \(trainingProtocol.duration)
                  強度: \(trainingProtocol.intensity) (期待改善: \(String(format: "%.1f", trainingProtocol.expectedImprovement))%)
                  根拠: \(trainingProtocol.evidenceBase)
                
                """
            }
        }
        
        return text
    }
}

// MARK: - ProgressAnalyzer Extensions for WPR

extension ProgressAnalyzer {
    
    /// WPR特化の詳細分析レポート生成
    func generateWPRDetailedReport(
        wprSystem: WPRTrackingSystem,
        records: [WorkoutRecord],
        template: WeeklyTemplate
    ) -> WPRDetailedAnalysisReport {
        
        let baseReport = generateDetailedWeeklyReport(records: records, template: template)
        
        // WPR特化の分析
        let wprTrend = analyzeWPRTrend(wprSystem: wprSystem, records: records)
        let scientificCorrelations = analyzeScientificCorrelations(wprSystem: wprSystem, records: records)
        
        return WPRDetailedAnalysisReport(
            baseReport: baseReport,
            wprTrend: wprTrend,
            efficiencyAnalysis: CyclingTrendAnalysis(
                powerTrend: .stable,
                distanceTrend: .stable,
                consistencyScore: 0.0,
                recommendations: []
            ),
            scientificCorrelations: scientificCorrelations,
            wprPrediction: generateWPRPrediction(wprSystem: wprSystem),
            actionPriority: generateActionPriority(wprSystem: wprSystem),
            riskAssessment: assessWPRRisks(wprSystem: wprSystem, records: records)
        )
    }
    
    private func analyzeWPRTrend(wprSystem: WPRTrackingSystem, records: [WorkoutRecord]) -> WPRTrendAnalysis {
        // 過去30日のWPR変化を分析
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentRecords = records.filter { $0.date >= thirtyDaysAgo }
        
        let wprValues = recentRecords.compactMap { record -> Double? in
            // 各ワークアウト時点でのWPR計算（体重変化を考慮）
            guard let weight = getDailyWeight(for: record.date) else { return nil }
            let ftp = getFTPAtDate(record.date)
            return Double(ftp) / weight
        }
        
        let trend = wprValues.isEmpty ? 0.0 : (wprValues.last! - wprValues.first!)
        let averageWPR = wprValues.isEmpty ? 0.0 : wprValues.reduce(0, +) / Double(wprValues.count)
        let wprVariability = wprValues.isEmpty ? 0.0 : 0.1  // プレースホルダー
        
        return WPRTrendAnalysis(
            trend: trend > 0 ? .improving : trend < 0 ? .declining : .stable,
            averageWPR: averageWPR,
            variability: wprVariability,
            dataPoints: wprValues.count,
            projectedGain: calculateProjectedWPRGain(trend: trend > 0 ? .improving : trend < 0 ? .declining : .stable, currentWPR: wprSystem.calculatedWPR),
            confidenceLevel: calculateTrendConfidence(dataPoints: wprValues.count, variability: wprVariability)
        )
    }
    
    private func analyzeScientificCorrelations(wprSystem: WPRTrackingSystem, records: [WorkoutRecord]) -> ScientificCorrelationAnalysis {
        // 科学的指標とWPRの相関分析
        var efWPRCorrelation = 0.0
        var volumeWPRCorrelation = 0.0
        var flexibilityWPRCorrelation = 0.0
        
        // 実際の相関計算ロジックをここに実装
        // 現在は理論値を使用
        efWPRCorrelation = 0.78  // 強い正の相関
        volumeWPRCorrelation = 0.65  // 中程度の正の相関
        flexibilityWPRCorrelation = 0.45  // 弱い正の相関
        
        return ScientificCorrelationAnalysis(
            efficiencyFactorCorrelation: efWPRCorrelation,
            volumeLoadCorrelation: volumeWPRCorrelation,
            flexibilityCorrelation: flexibilityWPRCorrelation,
            strongestPredictor: determinStrongestPredictor(ef: efWPRCorrelation, volume: volumeWPRCorrelation, flexibility: flexibilityWPRCorrelation),
            recommendations: generateCorrelationRecommendations(ef: efWPRCorrelation, volume: volumeWPRCorrelation, flexibility: flexibilityWPRCorrelation)
        )
    }
    
    private func generateWPRPrediction(wprSystem: WPRTrackingSystem) -> WPRPredictionAnalysis {
        let currentRate = (wprSystem.calculatedWPR - wprSystem.baselineWPR) / daysSinceBaseline(wprSystem)
        
        return WPRPredictionAnalysis(
            currentRate: currentRate,
            projected30Days: wprSystem.calculatedWPR + (currentRate * 30),
            projected60Days: wprSystem.calculatedWPR + (currentRate * 60),
            projected100Days: wprSystem.calculatedWPR + (currentRate * 100),
            targetAchievableProbability: calculateTargetProbability(wprSystem: wprSystem, currentRate: currentRate),
            alternativeScenarios: generateAlternativeScenarios(wprSystem: wprSystem)
        )
    }
    
    private func generateActionPriority(wprSystem: WPRTrackingSystem) -> ActionPriorityAnalysis {
        var priorities: [(action: String, impact: Double, difficulty: String)] = []
        
        // 効率性改善
        if wprSystem.efficiencyProgress < 0.7 {
            priorities.append((
                action: "Efficiency Factor向上（SST強化）",
                impact: wprSystem.efficiencyCoefficient,
                difficulty: "中"
            ))
        }
        
        // パワープロファイル改善
        if wprSystem.powerProfileProgress < 0.6 {
            priorities.append((
                action: "パワープロファイル全域強化",
                impact: wprSystem.powerProfileCoefficient,
                difficulty: "高"
            ))
        }
        
        // 体重管理
        let weightImpact = (wprSystem.currentWeight - wprSystem.baselineWeight) / wprSystem.baselineWeight
        if weightImpact > -0.03 {  // 3%未満の減量
            priorities.append((
                action: "体重管理・体組成改善",
                impact: 0.35,  // 直接的なWPR分母影響
                difficulty: "中"
            ))
        }
        
        // 影響度順にソート
        priorities.sort { $0.impact > $1.impact }
        
        return ActionPriorityAnalysis(
            topPriorities: priorities.prefix(3).map { $0 },
            quickWins: identifyQuickWins(wprSystem: wprSystem),
            longTermGoals: identifyLongTermGoals(wprSystem: wprSystem)
        )
    }
    
    private func assessWPRRisks(wprSystem: WPRTrackingSystem, records: [WorkoutRecord]) -> WPRRiskAssessment {
        var risks: [String] = []
        var riskLevel = "低"
        
        // オーバートレーニングリスク
        let recentWorkoutFrequency = calculateRecentWorkoutFrequency(records: records)
        if recentWorkoutFrequency > 1.5 {  // 1.5回/日以上
            risks.append("高頻度トレーニングによるオーバートレーニングリスク")
            riskLevel = "中"
        }
        
        // 急激な体重減少リスク
        let weightLossRate = (wprSystem.baselineWeight - wprSystem.currentWeight) / wprSystem.baselineWeight
        if weightLossRate > 0.08 {  // 8%以上の体重減少
            risks.append("急激な体重減少による筋量低下リスク")
            riskLevel = "高"
        }
        
        // 不均衡なトレーニングリスク
        let balanceRisk = assessTrainingBalance(records: records)
        if balanceRisk > 0.3 {
            risks.append("トレーニングバランスの偏りによる怪我リスク")
            if riskLevel == "低" { riskLevel = "中" }
        }
        
        return WPRRiskAssessment(
            overallRiskLevel: riskLevel,
            identifiedRisks: risks,
            mitigationStrategies: generateMitigationStrategies(risks: risks),
            recommendedMonitoring: generateMonitoringRecommendations(risks: risks)
        )
    }
    
    // MARK: - Helper Methods
    
    private func getDailyWeight(for date: Date) -> Double? {
        // DailyMetricから体重データを取得
        // Database query implementation requires ModelContext instance
        // Currently returns default value for calculation purposes
        return 70.0
    }
    
    private func getFTPAtDate(_ date: Date) -> Int {
        // 指定日時点でのFTP値を取得
        // FTPHistory search implementation requires ModelContext instance
        // Currently returns baseline value for calculation purposes
        return 250
    }
    
    private func daysSinceBaseline(_ wprSystem: WPRTrackingSystem) -> Double {
        return Date().timeIntervalSince(wprSystem.createdDate) / (24 * 60 * 60)
    }
    
    private func calculateVariability(values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance) / mean  // 変動係数
    }
    
    private func calculateProjectedWPRGain(trend: TrendDirection, currentWPR: Double) -> Double {
        switch trend {
        case .improving: return 0.3  // 3ヶ月で0.3改善
        case .stable: return 0.1     // 3ヶ月で0.1改善
        case .declining: return -0.05 // 3ヶ月で0.05低下
        }
    }
    
    private func calculateTrendConfidence(dataPoints: Int, variability: Double) -> Double {
        let dataConfidence = min(Double(dataPoints) / 20.0, 1.0)  // 20ポイントで100%
        let stabilityConfidence = max(1.0 - variability, 0.1)      // 変動が少ないほど高信頼
        return (dataConfidence + stabilityConfidence) / 2.0
    }
    
    private func determinStrongestPredictor(ef: Double, volume: Double, flexibility: Double) -> String {
        let correlations = [("効率性", ef), ("筋力", volume), ("柔軟性", flexibility)]
        return correlations.max(by: { $0.1 < $1.1 })?.0 ?? "効率性"
    }
    
    private func generateCorrelationRecommendations(ef: Double, volume: Double, flexibility: Double) -> [String] {
        var recommendations: [String] = []
        
        if ef > 0.7 {
            recommendations.append("効率性指標がWPRと強い相関を示しています。SSTを継続してください。")
        }
        
        if volume > 0.6 {
            recommendations.append("筋力開発がWPR向上に有効です。Volume Loadの増加を継続してください。")
        }
        
        if flexibility < 0.5 {
            recommendations.append("柔軟性の改善がWPRにあまり寄与していません。他の要素を優先してください。")
        }
        
        return recommendations
    }
    
    private func calculateTargetProbability(wprSystem: WPRTrackingSystem, currentRate: Double) -> Double {
        let remainingGain = wprSystem.targetWPR - wprSystem.calculatedWPR
        let timeToTarget = remainingGain / currentRate
        
        if timeToTarget <= 100 {
            return 0.85  // 85%確率
        } else if timeToTarget <= 150 {
            return 0.65  // 65%確率
        } else {
            return 0.35  // 35%確率
        }
    }
    
    private func generateAlternativeScenarios(wprSystem: WPRTrackingSystem) -> [String] {
        let scenarios = [
            "楽観シナリオ: 全指標改善で90日で達成",
            "現実シナリオ: 現在ペースで120日で達成",
            "保守シナリオ: ボトルネック解決に180日必要"
        ]
        return scenarios
    }
    
    private func identifyQuickWins(wprSystem: WPRTrackingSystem) -> [(action: String, impact: Double, difficulty: String)] {
        return [
            (action: "体重1kg減量", impact: 0.15, difficulty: "低"),
            (action: "SST頻度を週1→2回", impact: 0.08, difficulty: "中"),
            (action: "柔軟性ルーチン導入", impact: 0.03, difficulty: "低")
        ]
    }
    
    private func identifyLongTermGoals(wprSystem: WPRTrackingSystem) -> [(action: String, impact: Double, difficulty: String)] {
        return [
            (action: "FTP20W向上", impact: 0.25, difficulty: "高"),
            (action: "筋力30%向上", impact: 0.15, difficulty: "高"),
            (action: "体組成改善（筋量維持+脂肪減）", impact: 0.20, difficulty: "中")
        ]
    }
    
    private func calculateRecentWorkoutFrequency(records: [WorkoutRecord]) -> Double {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentRecords = records.filter { $0.date >= sevenDaysAgo }
        return Double(recentRecords.count) / 7.0
    }
    
    private func assessTrainingBalance(records: [WorkoutRecord]) -> Double {
        let cyclingCount = records.filter { $0.workoutType == .cycling }.count
        let strengthCount = records.filter { $0.workoutType == .strength }.count
        let flexibilityCount = records.filter { $0.workoutType == .flexibility }.count
        
        let total = cyclingCount + strengthCount + flexibilityCount
        guard total > 0 else { return 0.0 }
        
        let idealRatios = [0.5, 0.3, 0.2]  // サイクリング50%, 筋トレ30%, 柔軟性20%
        let actualRatios = [
            Double(cyclingCount) / Double(total),
            Double(strengthCount) / Double(total),
            Double(flexibilityCount) / Double(total)
        ]
        
        let deviations = zip(idealRatios, actualRatios).map { abs($0 - $1) }
        return deviations.reduce(0, +) / Double(deviations.count)
    }
    
    private func generateMitigationStrategies(risks: [String]) -> [String] {
        var strategies: [String] = []
        
        for risk in risks {
            if risk.contains("オーバートレーニング") {
                strategies.append("適切な休息日の設定と心拍変動モニタリング")
            }
            if risk.contains("体重減少") {
                strategies.append("栄養摂取量の見直しと筋量維持のための十分なタンパク質摂取")
            }
            if risk.contains("トレーニングバランス") {
                strategies.append("週次プランの見直しと各種目の適切な配分")
            }
        }
        
        return strategies
    }
    
    private func generateMonitoringRecommendations(risks: [String]) -> [String] {
        var recommendations: [String] = []
        
        if !risks.isEmpty {
            recommendations.append("週次でのWPR進捗確認")
            recommendations.append("体重・体組成の定期測定")
            recommendations.append("主観的疲労感（RPE）の記録")
            recommendations.append("睡眠品質と回復度の追跡")
        }
        
        return recommendations
    }
}

// MARK: - Extended Data Structures

struct WPRAnalysisData {
    let currentWPR: Double
    let targetWPR: Double
    let progressPercentage: Double
    let daysToTarget: Int
    let confidenceLevel: Double
    let primaryBottleneck: String
    let scientificMetrics: ScientificMetricsData
    let bottleneckAnalysis: [BottleneckData]
}

struct ScientificMetricsData {
    let efficiencyFactor: Double
    let efProgress: Double
    let powerProfileProgress: Double
    let strengthProgress: Double
    let flexibilityProgress: Double
}

struct BottleneckData {
    let type: String
    let severity: String
    let gapPercentage: Double
    let impactOnWPR: Double
    let timeToResolve: Int
    let recommendedProtocols: [ProtocolData]
}

struct ProtocolData {
    let name: String
    let frequency: String
    let duration: String
    let intensity: String
    let expectedImprovement: Double
    let evidenceBase: String
}

struct WPRDetailedAnalysisReport {
    let baseReport: DetailedWeeklyReport
    let wprTrend: WPRTrendAnalysis
    let efficiencyAnalysis: CyclingTrendAnalysis
    let scientificCorrelations: ScientificCorrelationAnalysis
    let wprPrediction: WPRPredictionAnalysis
    let actionPriority: ActionPriorityAnalysis
    let riskAssessment: WPRRiskAssessment
}

struct WPRTrendAnalysis {
    let trend: TrendDirection
    let averageWPR: Double
    let variability: Double
    let dataPoints: Int
    let projectedGain: Double
    let confidenceLevel: Double
}

struct ScientificCorrelationAnalysis {
    let efficiencyFactorCorrelation: Double
    let volumeLoadCorrelation: Double
    let flexibilityCorrelation: Double
    let strongestPredictor: String
    let recommendations: [String]
}

struct WPRPredictionAnalysis {
    let currentRate: Double
    let projected30Days: Double
    let projected60Days: Double
    let projected100Days: Double
    let targetAchievableProbability: Double
    let alternativeScenarios: [String]
}

struct ActionPriorityAnalysis {
    let topPriorities: [(action: String, impact: Double, difficulty: String)]
    let quickWins: [(action: String, impact: Double, difficulty: String)]
    let longTermGoals: [(action: String, impact: Double, difficulty: String)]
}

struct WPRRiskAssessment {
    let overallRiskLevel: String
    let identifiedRisks: [String]
    let mitigationStrategies: [String]
    let recommendedMonitoring: [String]
}

// MARK: - AIAnalysisRequest Extension

// MARK: - WPR Enhanced Analysis Request
struct WPREnhancedAnalysisRequest {
    let baseRequest: AIAnalysisRequest
    let wprData: WPRAnalysisData?
    let unifiedProgress: UnifiedProgressSummary?
    
    init(baseRequest: AIAnalysisRequest,
         wprData: WPRAnalysisData? = nil,
         unifiedProgress: UnifiedProgressSummary? = nil) {
        self.baseRequest = baseRequest
        self.wprData = wprData
        self.unifiedProgress = unifiedProgress
    }
}