import SwiftUI
import Charts

// MARK: - Analytics-Focused WPR Components (Issue #57)

// MARK: - Enhanced Scientific Metrics Card

struct EnhancedScientificMetricsCard: View {
    let system: WPRTrackingSystem
    let optimizationEngine: WPROptimizationEngine
    @State private var selectedMetric: MetricType?
    @State private var showingMetricDetail = false
    
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                ScientificMetricsHeader(overallScore: system.overallProgressScore)
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm.value), count: 2),
                    spacing: Spacing.sm.value
                ) {
                    ForEach(Array(metricsData.enumerated()), id: \.element.type) { index, metric in
                        AnalyticsMetricCard(
                            data: metric,
                            animationDelay: Double(index) * 0.1,
                            onTap: { metricType in
                                selectedMetric = metricType
                                showingMetricDetail = true
                            }
                        )
                    }
                }
                
                CorrelationAnalysisSummary(system: system)
            }
        }
        .sheet(isPresented: $showingMetricDetail) {
            if let selectedMetric = selectedMetric {
                MetricDetailAnalyticsView(
                    metricType: selectedMetric,
                    system: system
                )
            }
        }
    }
    
    private var metricsData: [MetricDisplayData] {
        [
            MetricDisplayData(
                type: .efficiency,
                currentValue: system.efficiencyFactor,
                targetValue: system.efficiencyTarget,
                unit: "",
                icon: "bolt.fill",
                color: MetricColor.efficiency,
                progress: system.efficiencyProgress
            ),
            MetricDisplayData(
                type: .powerProfile,
                currentValue: system.currentPowerProfileScore,
                targetValue: system.powerProfileTarget,
                unit: "%",
                icon: "speedometer",
                color: MetricColor.powerProfile,
                progress: system.powerProfileProgress
            ),
            MetricDisplayData(
                type: .hrEfficiency,
                currentValue: abs(system.hrEfficiencyBaseline),
                targetValue: abs(system.hrEfficiencyTarget),
                unit: "bpm",
                icon: "heart.fill",
                color: MetricColor.hrEfficiency,
                progress: system.hrEfficiencyProgress
            ),
            MetricDisplayData(
                type: .volumeLoad,
                currentValue: system.strengthBaseline,
                targetValue: system.strengthTarget,
                unit: "",
                icon: "figure.strengthtraining.traditional",
                color: MetricColor.volumeLoad,
                progress: system.strengthProgress
            ),
            MetricDisplayData(
                type: .rom,
                currentValue: system.flexibilityBaseline,
                targetValue: system.flexibilityTarget,
                unit: "°",
                icon: "figure.flexibility",
                color: MetricColor.rom,
                progress: system.flexibilityProgress
            )
        ]
    }
}

// MARK: - Scientific Metrics Header

private struct ScientificMetricsHeader: View {
    let overallScore: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                Text("科学的指標分析")
                    .font(Typography.headlineMedium)
                    .foregroundColor(SemanticColor.primaryText)
                
                Text("エビデンスベース改善度")
                    .font(Typography.captionMedium)
                    .foregroundColor(SemanticColor.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xs.value) {
                Text("\(Int(overallScore * 100))%")
                    .font(Typography.displaySmall)
                    .foregroundColor(SemanticColor.primaryAction)
                
                Text("統合スコア")
                    .font(Typography.captionSmall)
                    .foregroundColor(SemanticColor.secondaryText)
            }
        }
    }
}

// MARK: - Analytics Metric Card

struct AnalyticsMetricCard: View {
    let data: MetricDisplayData
    let animationDelay: Double
    let onTap: (MetricType) -> Void
    
    @State private var animatedValue: Double = 0
    @State private var animatedProgress: Double = 0
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            onTap(data.type)
        }) {
            BaseCard(
                style: AnalyticsCardStyle(
                    accentColor: data.color,
                    isPressed: isPressed
                )
            ) {
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    AnalyticsMetricHeader(data: data, progress: animatedProgress)
                    AnalyticsMetricValue(data: data, animatedValue: animatedValue)
                    AnalyticsMetricProgress(progress: animatedProgress, color: data.color)
                    AnalyticsMetricInsight(data: data)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(animationDelay)) {
                animatedValue = data.currentValue
                animatedProgress = data.progress
            }
        }
    }
}

// MARK: - Metric Card Components

private struct AnalyticsMetricHeader: View {
    let data: MetricDisplayData
    let progress: Double
    
    var body: some View {
        HStack(spacing: Spacing.sm.value) {
            Image(systemName: data.icon)
                .font(Typography.labelMedium)
                .foregroundColor(data.color)
                .frame(width: 16, height: 16)
            
            Text(data.type.displayName)
                .font(Typography.captionLarge)
                .foregroundColor(SemanticColor.secondaryText)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(Int(progress * 100))%")
                .font(Typography.captionSmall)
                .foregroundColor(data.color)
                .contentTransition(.numericText())
        }
    }
}

private struct AnalyticsMetricValue: View {
    let data: MetricDisplayData
    let animatedValue: Double
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs.value) {
            Text(String(format: "%.2f", animatedValue))
                .font(Typography.numeric)
                .foregroundColor(data.color)
                .contentTransition(.numericText())
            
            if !data.unit.isEmpty {
                Text(data.unit)
                    .font(Typography.captionMedium)
                    .foregroundColor(SemanticColor.secondaryText)
            }
            
            Spacer()
            
            Text("/ \(String(format: "%.1f", data.targetValue))")
                .font(Typography.captionMedium)
                .foregroundColor(SemanticColor.secondaryText)
        }
    }
}

private struct AnalyticsMetricProgress: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ProgressView(value: progress)
            .progressViewStyle(LinearProgressViewStyle(tint: color))
            .frame(height: 4)
            .animation(.easeInOut(duration: 0.8), value: progress)
    }
}

private struct AnalyticsMetricInsight: View {
    let data: MetricDisplayData
    
    var body: some View {
        HStack {
            Text(insightText)
                .font(Typography.captionSmall)
                .foregroundColor(insightColor)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(Typography.captionSmall)
                .foregroundColor(SemanticColor.secondaryText.opacity(0.6))
        }
    }
    
    private var insightText: String {
        let progress = data.progress
        switch progress {
        case 0.8...: return "優秀"
        case 0.6..<0.8: return "良好"
        case 0.4..<0.6: return "改善中"
        case 0.2..<0.4: return "要改善"
        default: return "要注意"
        }
    }
    
    private var insightColor: SemanticColor {
        let progress = data.progress
        switch progress {
        case 0.8...: return .successAction
        case 0.6..<0.8: return .primaryAction
        case 0.4..<0.6: return .warningAction
        default: return .errorAction
        }
    }
}

// MARK: - Correlation Analysis Summary

struct CorrelationAnalysisSummary: View {
    let system: WPRTrackingSystem
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.value) {
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
            
            HStack(spacing: Spacing.md.value) {
                CorrelationItem(
                    label1: "効率性",
                    label2: "FTP",
                    correlation: system.efficiencyFactor * 0.85,
                    color: MetricColor.efficiency
                )
                
                CorrelationItem(
                    label1: "筋力",
                    label2: "WPR",
                    correlation: system.strengthFactor * 0.72,
                    color: MetricColor.volumeLoad
                )
                
                Spacer()
            }
        }
        .padding(Spacing.sm)
        .background(SemanticColor.secondaryBackground.opacity(0.5))
        .cornerRadius(.medium)
    }
}

private struct CorrelationItem: View {
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
        }
    }
}

// MARK: - Custom Card Style for Analytics

struct AnalyticsCardStyle: CardStyling {
    let accentColor: Color
    let isPressed: Bool
    
    var backgroundColor: SemanticColor { .cardBackground }
    var cornerRadius: CornerRadius { .large }
    var padding: Spacing { .md }
    var shadow: ShadowStyle { .medium }
    var borderColor: SemanticColor? { isPressed ? SemanticColor.focusBorder : nil }
    var borderWidth: CGFloat { isPressed ? 2 : 0 }
}

// MARK: - Supporting Types

enum MetricType: CaseIterable {
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
}

enum MetricColor {
    static let efficiency = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let powerProfile = Color(red: 1.0, green: 0.0, blue: 0.0)
    static let hrEfficiency = Color(red: 1.0, green: 0.0, blue: 0.5)
    static let volumeLoad = Color(red: 0.0, green: 0.8, blue: 0.0)
    static let rom = Color(red: 0.6, green: 0.0, blue: 1.0)
}

struct MetricDisplayData {
    let type: MetricType
    let currentValue: Double
    let targetValue: Double
    let unit: String
    let icon: String
    let color: Color
    let progress: Double
}

// MARK: - Press Events ViewModifier (Reusable)

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                if pressing {
                    onPress()
                } else {
                    onRelease()
                }
            }, perform: {})
    }
}

#Preview {
    EnhancedScientificMetricsCard(
        system: WPRTrackingSystem.sampleData(),
        optimizationEngine: WPROptimizationEngine(modelContext: PreviewContainer.previewContainer.mainContext)
    )
    .padding()
}

// MARK: - Preview Container Helper

struct PreviewContainer {
    static let previewContainer: ModelContainer = {
        do {
            let container = try ModelContainer(for: WPRTrackingSystem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            return container
        } catch {
            fatalError("Failed to create preview container")
        }
    }()
}