import SwiftUI

// MARK: - WPR-Specific Metrics Implementation using Generic Analytics Framework

// MARK: - WPR Metric Data Types

struct WPRMetric: MetricDisplayable {
    let type: WPRMetricType
    let currentValue: Double
    let targetValue: Double
    let progress: Double
    
    var title: String { type.displayName }
    var icon: String { type.iconName }
    var unit: String { type.unit }
    var color: Color { type.color }
    var insight: String { type.getInsight(for: progress) }
}

enum WPRMetricType: CaseIterable {
    case efficiency
    case powerProfile
    case hrEfficiency
    case volumeLoad
    case rom
    
    var displayName: String {
        switch self {
        case .efficiency: return "効率性 (EF)"
        case .powerProfile: return "パワープロファイル"
        case .hrEfficiency: return "心拍効率"
        case .volumeLoad: return "筋力VL"
        case .rom: return "可動域ROM"
        }
    }
    
    var iconName: String {
        switch self {
        case .efficiency: return "bolt.fill"
        case .powerProfile: return "speedometer"
        case .hrEfficiency: return "heart.fill"
        case .volumeLoad: return "figure.strengthtraining.traditional"
        case .rom: return "figure.flexibility"
        }
    }
    
    var unit: String {
        switch self {
        case .efficiency: return ""
        case .powerProfile: return "%"
        case .hrEfficiency: return "bpm"
        case .volumeLoad: return ""
        case .rom: return "°"
        }
    }
    
    var color: Color {
        switch self {
        case .efficiency: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .powerProfile: return Color(red: 1.0, green: 0.0, blue: 0.0)
        case .hrEfficiency: return Color(red: 1.0, green: 0.0, blue: 0.5)
        case .volumeLoad: return Color(red: 0.0, green: 0.8, blue: 0.0)
        case .rom: return Color(red: 0.6, green: 0.0, blue: 1.0)
        }
    }
    
    func getInsight(for progress: Double) -> String {
        switch progress {
        case 0.8...: return "優秀"
        case 0.6..<0.8: return "良好"
        case 0.4..<0.6: return "改善中"
        case 0.2..<0.4: return "要改善"
        default: return "要注意"
        }
    }
}

// MARK: - WPR Metrics Factory

struct WPRMetricsFactory {
    static func createMetrics(from system: WPRTrackingSystem) -> [WPRMetric] {
        return WPRMetricType.allCases.map { type in
            WPRMetric(
                type: type,
                currentValue: getCurrentValue(for: type, from: system),
                targetValue: getTargetValue(for: type, from: system),
                progress: getProgress(for: type, from: system)
            )
        }
    }
    
    private static func getCurrentValue(for type: WPRMetricType, from system: WPRTrackingSystem) -> Double {
        switch type {
        case .efficiency: return system.efficiencyFactor
        case .powerProfile: return system.currentPowerProfileScore
        case .hrEfficiency: return abs(system.hrEfficiencyBaseline)
        case .volumeLoad: return system.strengthBaseline
        case .rom: return system.flexibilityBaseline
        }
    }
    
    private static func getTargetValue(for type: WPRMetricType, from system: WPRTrackingSystem) -> Double {
        switch type {
        case .efficiency: return system.efficiencyTarget
        case .powerProfile: return system.powerProfileTarget
        case .hrEfficiency: return abs(system.hrEfficiencyTarget)
        case .volumeLoad: return system.strengthTarget
        case .rom: return system.flexibilityTarget
        }
    }
    
    private static func getProgress(for type: WPRMetricType, from system: WPRTrackingSystem) -> Double {
        switch type {
        case .efficiency: return system.efficiencyProgress
        case .powerProfile: return system.powerProfileProgress
        case .hrEfficiency: return system.hrEfficiencyProgress
        case .volumeLoad: return system.strengthProgress
        case .rom: return system.flexibilityProgress
        }
    }
}

// MARK: - WPR Analytics Dashboard Component

struct WPRAnalyticsDashboard: View {
    let system: WPRTrackingSystem
    let onMetricTap: ((WPRMetric) -> Void)?
    
    private var metrics: [WPRMetric] {
        WPRMetricsFactory.createMetrics(from: system)
    }
    
    var body: some View {
        VStack(spacing: Spacing.md.value) {
            WPRAnalyticsHeader(system: system)
            
            AnalyticsSection(
                title: "科学的指標分析",
                subtitle: "エビデンスベース改善度",
                metrics: metrics,
                onMetricTap: onMetricTap,
                headerAction: {
                    // Navigate to detailed analytics
                }
            )
            
            WPRCorrelationAnalysis(system: system)
        }
    }
}

// MARK: - WPR Analytics Header

private struct WPRAnalyticsHeader: View {
    let system: WPRTrackingSystem
    
    var body: some View {
        BaseCard {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    Text("WPR アナリティクス")
                        .font(Typography.headlineLarge)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Text("「数字を見てニマニマ」統計特化")
                        .font(Typography.captionMedium)
                        .foregroundColor(SemanticColor.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Spacing.xs.value) {
                    Text("\(Int(system.overallProgressScore * 100))%")
                        .font(Typography.displaySmall)
                        .foregroundColor(SemanticColor.primaryAction)
                    
                    Text("統合スコア")
                        .font(Typography.captionSmall)
                        .foregroundColor(SemanticColor.secondaryText)
                }
            }
        }
    }
}

// MARK: - WPR Correlation Analysis

private struct WPRCorrelationAnalysis: View {
    let system: WPRTrackingSystem
    
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                HStack {
                    Image(systemName: "chart.dots.scatter")
                        .foregroundColor(SemanticColor.primaryAction)
                    
                    Text("相関分析")
                        .font(Typography.headlineSmall)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Spacer()
                    
                    Button("詳細") {
                        // Navigate to detailed correlation view
                    }
                    .font(Typography.captionMedium)
                    .foregroundColor(SemanticColor.primaryAction)
                }
                
                HStack(spacing: Spacing.lg.value) {
                    CorrelationIndicator(
                        label1: "効率性",
                        label2: "FTP",
                        correlation: system.efficiencyFactor * 0.85,
                        color: WPRMetricType.efficiency.color
                    )
                    
                    CorrelationIndicator(
                        label1: "筋力",
                        label2: "WPR",
                        correlation: system.strengthFactor * 0.72,
                        color: WPRMetricType.volumeLoad.color
                    )
                    
                    CorrelationIndicator(
                        label1: "ROM",
                        label2: "効率",
                        correlation: system.flexibilityFactor * 0.68,
                        color: WPRMetricType.rom.color
                    )
                    
                    Spacer()
                }
            }
        }
    }
}

private struct CorrelationIndicator: View {
    let label1: String
    let label2: String
    let correlation: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs.value) {
            Text("\(label1)↔\(label2)")
                .font(Typography.captionSmall)
                .foregroundColor(SemanticColor.secondaryText)
            
            Text(String(format: "%.2f", correlation))
                .font(Typography.labelMedium)
                .foregroundColor(color)
            
            ProgressView(value: abs(correlation))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(width: 40, height: 2)
        }
    }
}

#Preview {
    WPRAnalyticsDashboard(
        system: WPRTrackingSystem.sampleData(),
        onMetricTap: { metric in
            // Metric tapped - handled by parent
        }
    )
    .padding()
}