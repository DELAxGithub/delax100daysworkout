import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - Bottleneck Analysis System

enum BottleneckSeverity: String, Codable, CaseIterable {
    case critical = "緊急"      // -2σ以下
    case major = "重要"         // -1σ〜-2σ
    case moderate = "中程度"    // -0.5σ〜-1σ
    case minor = "軽微"         // 0σ〜-0.5σ
    case none = "なし"          // 0σ以上
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .major: return .orange
        case .moderate: return .yellow
        case .minor: return .blue
        case .none: return .green
        }
    }
    
    var priority: Int {
        switch self {
        case .critical: return 5
        case .major: return 4
        case .moderate: return 3
        case .minor: return 2
        case .none: return 1
        }
    }
}

struct BottleneckAnalysis {
    let bottleneckType: BottleneckType
    let severity: BottleneckSeverity
    let zScore: Double
    let currentValue: Double
    let targetValue: Double
    let gapPercentage: Double
    let impactOnWPR: Double           // WPR目標達成への影響度
    let timeToResolve: Int            // 解決予想日数
    let recommendedProtocols: [TrainingProtocol]
    let riskFactors: [String]
    let supportingEvidence: [String]  // 科学的根拠
}

struct TrainingProtocol {
    let name: String
    let description: String
    let frequency: String             // "週3回", "毎日"等
    let duration: String              // "20分", "45分"等
    let intensity: String             // "FTP 90%", "RPE 7-8"等
    let expectedImprovement: Double   // 予想改善率
    let evidenceBase: String          // 科学的根拠
    let riskLevel: String            // "低", "中", "高"
}

@MainActor
class BottleneckDetectionSystem: ObservableObject {
    private let modelContext: ModelContext
    private let optimizationEngine: WPROptimizationEngine
    
    @Published var detectedBottlenecks: [BottleneckAnalysis] = []
    @Published var prioritizedActions: [TrainingProtocol] = []
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    @Published var analysisError: String?
    
    // 分析結果統計
    @Published var criticalBottlenecks: Int = 0
    @Published var majorBottlenecks: Int = 0
    @Published var overallRiskScore: Double = 0.0
    
    init(modelContext: ModelContext, optimizationEngine: WPROptimizationEngine) {
        self.modelContext = modelContext
        self.optimizationEngine = optimizationEngine
    }
    
    // MARK: - Core Analysis Methods
    
    /// 包括的ボトルネック解析
    func performComprehensiveBottleneckAnalysis(_ system: WPRTrackingSystem) async {
        await MainActor.run {
            isAnalyzing = true
            analysisError = nil
        }
        
        await Task.detached { [weak self] in
            guard let self = self else { return }
            
            var bottlenecks: [BottleneckAnalysis] = []
            
            // 1. Efficiency Factor解析
            if let efAnalysis = await self.analyzeEfficiencyBottleneck(system) {
                bottlenecks.append(efAnalysis)
            }
            
            // 2. Power Profile解析
            if let ppAnalysis = await self.analyzePowerProfileBottleneck(system) {
                bottlenecks.append(ppAnalysis)
            }
            
            // 3. HR Efficiency解析
            if let hrAnalysis = await self.analyzeHREfficiencyBottleneck(system) {
                bottlenecks.append(hrAnalysis)
            }
            
            // 4. Strength/Volume Load解析
            if let vlAnalysis = await self.analyzeStrengthBottleneck(system) {
                bottlenecks.append(vlAnalysis)
            }
            
            // 5. Flexibility/ROM解析
            if let romAnalysis = await self.analyzeFlexibilityBottleneck(system) {
                bottlenecks.append(romAnalysis)
            }
            
            // 6. 体重管理解析
            if let weightAnalysis = await self.analyzeWeightBottleneck(system) {
                bottlenecks.append(weightAnalysis)
            }
            
            // 深刻度順にソート
            bottlenecks.sort { $0.severity.priority > $1.severity.priority }
            
            // 優先アクション生成
            let prioritizedProtocols = await self.generatePrioritizedProtocols(from: bottlenecks)
            
            await MainActor.run {
                self.detectedBottlenecks = bottlenecks
                self.prioritizedActions = prioritizedProtocols
                self.criticalBottlenecks = bottlenecks.filter { $0.severity == .critical }.count
                self.majorBottlenecks = bottlenecks.filter { $0.severity == .major }.count
                self.overallRiskScore = self.calculateOverallRiskScore(bottlenecks)
                self.isAnalyzing = false
                self.lastAnalysisDate = Date()
            }
        }.value
    }
    
    // MARK: - Individual Bottleneck Analysis
    
    private func analyzeEfficiencyBottleneck(_ system: WPRTrackingSystem) async -> BottleneckAnalysis? {
        guard system.efficiencyFactor > 0 else { return nil }
        
        let current = system.efficiencyFactor
        let target = system.efficiencyTarget
        let _ = system.efficiencyBaseline
        
        let zScore = calculateZScore(current: current, mean: target, standardDeviation: 0.1)
        let severity = determineSeverity(from: zScore)
        let gap = (target - current) / target * 100
        
        return BottleneckAnalysis(
            bottleneckType: .efficiency,
            severity: severity,
            zScore: zScore,
            currentValue: current,
            targetValue: target,
            gapPercentage: gap,
            impactOnWPR: system.efficiencyCoefficient,
            timeToResolve: calculateTimeToResolve(gap: gap, improvementRate: 0.02),
            recommendedProtocols: generateEfficiencyProtocols(gap: gap),
            riskFactors: [
                gap > 20 ? "効率改善の遅れ" : nil,
                "心肺機能の適応不足",
                "トレーニング強度の不適切性"
            ].compactMap { $0 },
            supportingEvidence: [
                "Hopker et al. (2010): EF向上による有酸素適応",
                "TrainingPeaks: 同心拍でのパワー向上指標"
            ]
        )
    }
    
    private func analyzePowerProfileBottleneck(_ system: WPRTrackingSystem) async -> BottleneckAnalysis? {
        guard let powerProfile = await getLatestPowerProfile() else { return nil }
        
        let current = powerProfile.improvementScore
        let target = system.powerProfileTarget
        
        let zScore = calculateZScore(current: current, mean: target, standardDeviation: 0.05)
        let severity = determineSeverity(from: zScore)
        let gap = (target - current) / target * 100
        
        return BottleneckAnalysis(
            bottleneckType: .power,
            severity: severity,
            zScore: zScore,
            currentValue: current,
            targetValue: target,
            gapPercentage: gap,
            impactOnWPR: system.powerProfileCoefficient,
            timeToResolve: calculateTimeToResolve(gap: gap, improvementRate: 0.03),
            recommendedProtocols: generatePowerProfileProtocols(powerProfile: powerProfile),
            riskFactors: [
                gap > 30 ? "パワー開発の停滞" : nil,
                powerProfile.profileBalance < 0.7 ? "パワープロファイルの不均衡" : nil
            ].compactMap { $0 },
            supportingEvidence: [
                "Cesanelli et al. (2021): S&Cプログラムでのパワー向上",
                "Seiler理論: 多時間域パワー能力の重要性"
            ]
        )
    }
    
    private func analyzeHREfficiencyBottleneck(_ system: WPRTrackingSystem) async -> BottleneckAnalysis? {
        guard let hrTracking = await getLatestHRAtPowerTracking() else { return nil }
        
        let current = hrTracking.efficiencyImprovement
        let target = abs(system.hrEfficiencyTarget) / 15.0  // -15bpm → 1.0に正規化
        
        let zScore = calculateZScore(current: current, mean: target, standardDeviation: 0.2)
        let severity = determineSeverity(from: zScore)
        let gap = (target - current) / target * 100
        
        return BottleneckAnalysis(
            bottleneckType: .cardio,
            severity: severity,
            zScore: zScore,
            currentValue: current,
            targetValue: target,
            gapPercentage: gap,
            impactOnWPR: system.hrEfficiencyCoefficient,
            timeToResolve: calculateTimeToResolve(gap: gap, improvementRate: 0.025),
            recommendedProtocols: generateHREfficiencyProtocols(hrTracking: hrTracking),
            riskFactors: [
                gap > 40 ? "心肺適応の遅延" : nil,
                hrTracking.cardioFitnessIndex < 1.5 ? "基礎的持久力不足" : nil
            ].compactMap { $0 },
            supportingEvidence: [
                "Lunn et al. (2009): 循環器適応による効率向上",
                "固定ワット時HR低下 = 内的負荷軽減"
            ]
        )
    }
    
    private func analyzeStrengthBottleneck(_ system: WPRTrackingSystem) async -> BottleneckAnalysis? {
        guard let vlSystem = await getLatestVolumeLoadSystem() else { return nil }
        
        let current = vlSystem.improvementScore
        let target = system.strengthTarget
        
        let zScore = calculateZScore(current: current, mean: target, standardDeviation: 0.1)
        let severity = determineSeverity(from: zScore)
        let gap = (target - current) / target * 100
        
        return BottleneckAnalysis(
            bottleneckType: .strength,
            severity: severity,
            zScore: zScore,
            currentValue: current,
            targetValue: target,
            gapPercentage: gap,
            impactOnWPR: system.strengthCoefficient,
            timeToResolve: calculateTimeToResolve(gap: gap, improvementRate: 0.04),
            recommendedProtocols: generateStrengthProtocols(vlSystem: vlSystem),
            riskFactors: [
                gap > 25 ? "筋力開発の不足" : nil,
                vlSystem.balanceScore < 0.6 ? "筋力バランスの不均衡" : nil,
                vlSystem.averagePushRPE > 8 ? "オーバートレーニングリスク" : nil
            ].compactMap { $0 },
            supportingEvidence: [
                "Vikmoen et al. (2021): 筋トレによる8%パワー向上",
                "Krzysztofik et al. (2019): 週28-30セット/筋群最適"
            ]
        )
    }
    
    private func analyzeFlexibilityBottleneck(_ system: WPRTrackingSystem) async -> BottleneckAnalysis? {
        guard let romTracking = await getLatestROMTracking() else { return nil }
        
        let current = romTracking.improvementScore
        let target = system.flexibilityTarget / 15.0  // +15° → 1.0に正規化
        
        let zScore = calculateZScore(current: current, mean: target, standardDeviation: 0.3)
        let severity = determineSeverity(from: zScore)
        let gap = (target - current) / target * 100
        
        return BottleneckAnalysis(
            bottleneckType: .flexibility,
            severity: severity,
            zScore: zScore,
            currentValue: current,
            targetValue: target,
            gapPercentage: gap,
            impactOnWPR: system.flexibilityCoefficient,
            timeToResolve: calculateTimeToResolve(gap: gap, improvementRate: 0.05),
            recommendedProtocols: generateFlexibilityProtocols(romTracking: romTracking),
            riskFactors: [
                gap > 50 ? "柔軟性改善の遅れ" : nil,
                romTracking.functionalMobilityScore < 0.5 ? "機能的可動域の制限" : nil
            ].compactMap { $0 },
            supportingEvidence: [
                "Holliday et al. (2021): 柔軟性とパワー出力の相関",
                "Konrad (2024): 2週間でのROM有意改善"
            ]
        )
    }
    
    private func analyzeWeightBottleneck(_ system: WPRTrackingSystem) async -> BottleneckAnalysis? {
        guard system.currentWeight > 0, system.baselineWeight > 0 else { return nil }
        
        let currentWeightLoss = (system.baselineWeight - system.currentWeight) / system.baselineWeight
        let targetWeightLoss = 0.05  // 5%減量目標と仮定
        
        let zScore = calculateZScore(current: currentWeightLoss, mean: targetWeightLoss, standardDeviation: 0.02)
        let severity = determineSeverity(from: zScore)
        let gap = (targetWeightLoss - currentWeightLoss) / targetWeightLoss * 100
        
        return BottleneckAnalysis(
            bottleneckType: .weight,
            severity: severity,
            zScore: zScore,
            currentValue: currentWeightLoss,
            targetValue: targetWeightLoss,
            gapPercentage: gap,
            impactOnWPR: 0.35,  // 体重はWPR分母に直接影響
            timeToResolve: calculateTimeToResolve(gap: gap, improvementRate: 0.01),
            recommendedProtocols: generateWeightManagementProtocols(system: system),
            riskFactors: [
                gap > 30 ? "体重管理の遅延" : nil,
                currentWeightLoss < 0 ? "体重増加傾向" : nil
            ].compactMap { $0 },
            supportingEvidence: [
                "PWR = FTP ÷ 体重による直接的影響",
                "体重1kg減 = WPR 0.1-0.15向上"
            ]
        )
    }
    
    // MARK: - Protocol Generation
    
    private func generateEfficiencyProtocols(gap: Double) -> [TrainingProtocol] {
        var protocols: [TrainingProtocol] = []
        
        if gap > 20 {
            protocols.append(TrainingProtocol(
                name: "集中SST（Sweet Spot Training）",
                description: "FTP 88-94%で20-40分間の持続的努力",
                frequency: "週3回",
                duration: "20-40分",
                intensity: "FTP 88-94%",
                expectedImprovement: 0.04,
                evidenceBase: "Seiler & Tønnessen (2009)",
                riskLevel: "中"
            ))
        }
        
        protocols.append(TrainingProtocol(
            name: "Zone 2有酸素ベース構築",
            description: "低強度長時間での基礎的持久力向上",
            frequency: "週2-3回",
            duration: "60-90分",
            intensity: "Zone 2 (65-75% HRmax)",
            expectedImprovement: 0.02,
            evidenceBase: "Polarized Training Model",
            riskLevel: "低"
        ))
        
        return protocols
    }
    
    private func generatePowerProfileProtocols(powerProfile: PowerProfile) -> [TrainingProtocol] {
        var protocols: [TrainingProtocol] = []
        
        // 各時間域の弱点に応じたプロトコル
        if powerProfile.neuromuscularImprovement < 0.1 {
            protocols.append(TrainingProtocol(
                name: "神経筋パワー開発",
                description: "5-10秒の最大努力スプリント",
                frequency: "週2回",
                duration: "10-15分（実働時間）",
                intensity: "最大努力（>150% FTP）",
                expectedImprovement: 0.08,
                evidenceBase: "神経筋適応理論",
                riskLevel: "中"
            ))
        }
        
        if powerProfile.vo2maxImprovement < 0.1 {
            protocols.append(TrainingProtocol(
                name: "VO2maxインターバル",
                description: "3-8分間の高強度インターバル",
                frequency: "週1-2回",
                duration: "30-45分",
                intensity: "105-120% FTP",
                expectedImprovement: 0.06,
                evidenceBase: "VO2max向上プロトコル",
                riskLevel: "高"
            ))
        }
        
        return protocols
    }
    
    private func generateHREfficiencyProtocols(hrTracking: HRAtPowerTracking) -> [TrainingProtocol] {
        return [
            TrainingProtocol(
                name: "固定ワットHR効率化トレーニング",
                description: "200W, 250W, 300Wでの1分間維持×心拍モニタリング",
                frequency: "週1回",
                duration: "20分",
                intensity: "固定ワット",
                expectedImprovement: 0.03,
                evidenceBase: "Lunn et al. (2009)",
                riskLevel: "低"
            ),
            TrainingProtocol(
                name: "心拍変動改善プログラム",
                description: "回復重視の低強度トレーニング",
                frequency: "週2-3回",
                duration: "45-60分",
                intensity: "Zone 1-2",
                expectedImprovement: 0.02,
                evidenceBase: "HRV研究",
                riskLevel: "低"
            )
        ]
    }
    
    private func generateStrengthProtocols(vlSystem: VolumeLoadSystem) -> [TrainingProtocol] {
        return [
            TrainingProtocol(
                name: "Push筋群Volume Load増加",
                description: "ベンチプレス、ショルダープレス中心の高ボリューム",
                frequency: "週2-3回",
                duration: "45-60分",
                intensity: "70-85% 1RM, RPE 7-8",
                expectedImprovement: 0.05,
                evidenceBase: "Krzysztofik et al. (2019)",
                riskLevel: "中"
            ),
            TrainingProtocol(
                name: "Pull筋群強化プログラム",
                description: "懸垂、ローイング系の漸進的過負荷",
                frequency: "週2回",
                duration: "40-50分",
                intensity: "75-85% 1RM",
                expectedImprovement: 0.04,
                evidenceBase: "Vikmoen et al. (2021)",
                riskLevel: "中"
            )
        ]
    }
    
    private func generateFlexibilityProtocols(romTracking: ROMTracking) -> [TrainingProtocol] {
        return [
            TrainingProtocol(
                name: "股関節可動域拡大プログラム",
                description: "ヒップフレクサー、ハムストリング重点ストレッチ",
                frequency: "毎日",
                duration: "15-20分",
                intensity: "中程度の伸張感",
                expectedImprovement: 0.06,
                evidenceBase: "Konrad (2024)",
                riskLevel: "低"
            ),
            TrainingProtocol(
                name: "動的柔軟性向上",
                description: "Y-Balance, 動的ストレッチの組み合わせ",
                frequency: "週3回",
                duration: "10-15分",
                intensity: "制御された動作",
                expectedImprovement: 0.04,
                evidenceBase: "機能的可動域研究",
                riskLevel: "低"
            )
        ]
    }
    
    private func generateWeightManagementProtocols(system: WPRTrackingSystem) -> [TrainingProtocol] {
        return [
            TrainingProtocol(
                name: "体組成改善プログラム",
                description: "筋量維持しながらの体脂肪削減",
                frequency: "継続的",
                duration: "生活習慣",
                intensity: "適切なカロリー収支",
                expectedImprovement: 0.02,
                evidenceBase: "Body Composition研究",
                riskLevel: "低"
            )
        ]
    }
    
    // MARK: - Helper Methods
    
    private func calculateZScore(current: Double, mean: Double, standardDeviation: Double) -> Double {
        guard standardDeviation > 0 else { return 0.0 }
        return (current - mean) / standardDeviation
    }
    
    private func determineSeverity(from zScore: Double) -> BottleneckSeverity {
        switch zScore {
        case ..<(-2.0): return .critical
        case -2.0..<(-1.0): return .major
        case -1.0..<(-0.5): return .moderate
        case -0.5..<0: return .minor
        default: return .none
        }
    }
    
    private func calculateTimeToResolve(gap: Double, improvementRate: Double) -> Int {
        guard improvementRate > 0 else { return 999 }
        let monthsToResolve = (gap / 100.0) / improvementRate
        return max(Int(monthsToResolve * 30), 7)  // 最低1週間
    }
    
    private func generatePrioritizedProtocols(from bottlenecks: [BottleneckAnalysis]) -> [TrainingProtocol] {
        return bottlenecks
            .filter { $0.severity.priority >= 3 }  // moderate以上
            .sorted { $0.impactOnWPR > $1.impactOnWPR }
            .flatMap { $0.recommendedProtocols }
            .prefix(5)  // トップ5プロトコル
            .map { $0 }
    }
    
    private func calculateOverallRiskScore(_ bottlenecks: [BottleneckAnalysis]) -> Double {
        guard !bottlenecks.isEmpty else { return 0.0 }
        
        let riskScore = bottlenecks.reduce(0.0) { sum, bottleneck in
            sum + (Double(bottleneck.severity.priority) * bottleneck.impactOnWPR)
        } / Double(bottlenecks.count)
        
        return min(riskScore / 5.0, 1.0)  // 0-1正規化
    }
    
    // MARK: - Data Fetching
    
    private func getLatestPowerProfile() async -> PowerProfile? {
        // TODO: ModelContextからの非同期データ取得
        // 現在は同期的実装、本来は非同期で最適化
        return nil
    }
    
    private func getLatestHRAtPowerTracking() async -> HRAtPowerTracking? {
        return nil
    }
    
    private func getLatestVolumeLoadSystem() async -> VolumeLoadSystem? {
        return nil
    }
    
    private func getLatestROMTracking() async -> ROMTracking? {
        return nil
    }
}

extension BottleneckDetectionSystem {
    /// サンプルボトルネック解析結果
    static func sampleBottleneckAnalysis() -> [BottleneckAnalysis] {
        return [
            BottleneckAnalysis(
                bottleneckType: .strength,
                severity: .major,
                zScore: -1.5,
                currentValue: 0.12,
                targetValue: 0.30,
                gapPercentage: 60.0,
                impactOnWPR: 0.20,
                timeToResolve: 45,
                recommendedProtocols: [
                    TrainingProtocol(
                        name: "Volume Load増加プログラム",
                        description: "週28-30セット/筋群の高ボリューム筋トレ",
                        frequency: "週3回",
                        duration: "45-60分",
                        intensity: "70-85% 1RM",
                        expectedImprovement: 0.05,
                        evidenceBase: "Krzysztofik et al. (2019)",
                        riskLevel: "中"
                    )
                ],
                riskFactors: ["筋力開発の不足", "筋力バランスの不均衡"],
                supportingEvidence: ["Vikmoen et al. (2021): 筋トレによる8%パワー向上"]
            )
        ]
    }
}