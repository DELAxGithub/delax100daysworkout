import SwiftUI

// MARK: - Generic Analytics Card Framework (Issue #67)

/// Protocol for any data that can be displayed in an analytics card
protocol MetricDisplayable {
    var title: String { get }
    var icon: String { get }
    var currentValue: Double { get }
    var targetValue: Double { get }
    var unit: String { get }
    var color: Color { get }
    var progress: Double { get }
    var insight: String { get }
}

/// Generic analytics card that can display any MetricDisplayable data
struct AnalyticsCard<Data: MetricDisplayable>: View {
    let data: Data
    let onTap: (() -> Void)?
    let animationDelay: Double
    
    @State private var animatedValue: Double = 0
    @State private var animatedProgress: Double = 0
    @State private var isPressed: Bool = false
    
    init(
        data: Data,
        onTap: (() -> Void)? = nil,
        animationDelay: Double = 0
    ) {
        self.data = data
        self.onTap = onTap
        self.animationDelay = animationDelay
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
                .pressEvents(
                    onPress: { isPressed = true },
                    onRelease: { isPressed = false }
                )
            } else {
                cardContent
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(animationDelay)) {
                animatedValue = data.currentValue
                animatedProgress = data.progress
            }
        }
        .onChange(of: data.currentValue) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedValue = newValue
            }
        }
    }
    
    private var cardContent: some View {
        BaseCard(
            style: AnalyticsCardStyle(
                accentColor: data.color,
                isPressed: isPressed
            )
        ) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                AnalyticsCardHeader(
                    title: data.title,
                    icon: data.icon,
                    color: data.color,
                    progress: animatedProgress
                )
                
                AnalyticsCardValue(
                    value: animatedValue,
                    targetValue: data.targetValue,
                    unit: data.unit,
                    color: data.color
                )
                
                AnalyticsCardProgress(
                    progress: animatedProgress,
                    color: data.color
                )
                
                AnalyticsCardInsight(
                    insight: data.insight,
                    color: data.color
                )
            }
        }
    }
}

// MARK: - Analytics Card Components

private struct AnalyticsCardHeader: View {
    let title: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        HStack(spacing: Spacing.sm.value) {
            Image(systemName: icon)
                .font(Typography.labelMedium)
                .foregroundColor(color)
                .frame(width: 16, height: 16)
            
            Text(title)
                .font(Typography.captionLarge)
                .foregroundColor(SemanticColor.secondaryText)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(Int(progress * 100))%")
                .font(Typography.captionSmall)
                .foregroundColor(color)
                .contentTransition(.numericText())
        }
    }
}

private struct AnalyticsCardValue: View {
    let value: Double
    let targetValue: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs.value) {
            Text(String(format: "%.2f", value))
                .font(Typography.numeric)
                .foregroundColor(color)
                .contentTransition(.numericText())
            
            if !unit.isEmpty {
                Text(unit)
                    .font(Typography.captionMedium)
                    .foregroundColor(SemanticColor.secondaryText)
            }
            
            Spacer()
            
            Text("/ \(String(format: "%.1f", targetValue))")
                .font(Typography.captionMedium)
                .foregroundColor(SemanticColor.secondaryText)
        }
    }
}

private struct AnalyticsCardProgress: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ProgressView(value: progress)
            .progressViewStyle(LinearProgressViewStyle(tint: color))
            .frame(height: 4)
            .animation(.easeInOut(duration: 0.8), value: progress)
    }
}

private struct AnalyticsCardInsight: View {
    let insight: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(insight)
                .font(Typography.captionSmall)
                .foregroundColor(color)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(Typography.captionSmall)
                .foregroundColor(SemanticColor.secondaryText.opacity(0.6))
        }
    }
}

// MARK: - Analytics Card Style

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

// MARK: - Analytics Grid Layout

struct AnalyticsGrid<Data: MetricDisplayable>: View {
    let metrics: [Data]
    let columns: Int
    let onMetricTap: ((Data) -> Void)?
    
    init(
        metrics: [Data],
        columns: Int = 2,
        onMetricTap: ((Data) -> Void)? = nil
    ) {
        self.metrics = metrics
        self.columns = columns
        self.onMetricTap = onMetricTap
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm.value), count: columns),
            spacing: Spacing.sm.value
        ) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                AnalyticsCard(
                    data: metric,
                    onTap: onMetricTap != nil ? { onMetricTap?(metric) } : nil,
                    animationDelay: Double(index) * 0.1
                )
            }
        }
    }
}

// MARK: - Generic Analytics Section

struct AnalyticsSection<Data: MetricDisplayable>: View {
    let title: String
    let subtitle: String?
    let metrics: [Data]
    let onMetricTap: ((Data) -> Void)?
    let headerAction: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        metrics: [Data],
        onMetricTap: ((Data) -> Void)? = nil,
        headerAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.metrics = metrics
        self.onMetricTap = onMetricTap
        self.headerAction = headerAction
    }
    
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                AnalyticsSectionHeader(
                    title: title,
                    subtitle: subtitle,
                    onAction: headerAction
                )
                
                AnalyticsGrid(
                    metrics: metrics,
                    onMetricTap: onMetricTap
                )
            }
        }
    }
}

// MARK: - Section Header

private struct AnalyticsSectionHeader: View {
    let title: String
    let subtitle: String?
    let onAction: (() -> Void)?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                Text(title)
                    .font(Typography.headlineMedium)
                    .foregroundColor(SemanticColor.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.captionMedium)
                        .foregroundColor(SemanticColor.secondaryText)
                }
            }
            
            Spacer()
            
            if let onAction = onAction {
                Button("詳細", action: onAction)
                    .font(Typography.captionMedium)
                    .foregroundColor(SemanticColor.primaryAction)
            }
        }
    }
}

#Preview {
    struct SampleMetric: MetricDisplayable {
        let title: String
        let icon: String
        let currentValue: Double
        let targetValue: Double
        let unit: String
        let color: Color
        let progress: Double
        let insight: String
    }
    
    let sampleMetrics = [
        SampleMetric(
            title: "効率性",
            icon: "bolt.fill",
            currentValue: 1.28,
            targetValue: 1.5,
            unit: "",
            color: .yellow,
            progress: 0.85,
            insight: "優秀"
        ),
        SampleMetric(
            title: "パワー",
            icon: "speedometer",
            currentValue: 0.12,
            targetValue: 0.15,
            unit: "%",
            color: .red,
            progress: 0.8,
            insight: "良好"
        )
    ]
    
    return AnalyticsSection(
        title: "メトリクス分析",
        subtitle: "科学的指標",
        metrics: sampleMetrics
    )
    .padding()
}