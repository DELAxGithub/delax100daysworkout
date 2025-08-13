import SwiftUI
import Charts

// MARK: - Summary Card Header

struct SummaryCardHeader: View {
    let configuration: SummaryCardConfiguration
    
    var body: some View {
        HStack {
            Image(systemName: configuration.icon)
                .foregroundColor(configuration.color)
                .font(Typography.headlineMedium.font)
            
            Spacer()
            
            if configuration.expandedData != nil {
                Image(systemName: "chevron.down")
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.secondaryText)
            }
        }
        
        Text(configuration.value)
            .font(Typography.displaySmall.font)
            .fontWeight(.bold)
            .foregroundColor(SemanticColor.primaryText)
        
        VStack(alignment: .leading, spacing: Spacing.xs.value) {
            Text(configuration.title)
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.secondaryText)
            
            Text(configuration.subtitle)
                .font(Typography.captionSmall.font)
                .foregroundColor(configuration.color)
        }
    }
}

// MARK: - Expanded Content

struct SummaryCardExpandedContent: View {
    let data: ChartData?
    let chartType: ChartType
    
    var body: some View {
        Group {
            if let data = data {
                switch chartType {
                case .line:
                    CompactLineChart(data: data)
                case .progress:
                    ProgressChart(data: data)
                case .donut:
                    DonutChart(data: data)
                case .none:
                    EmptyView()
                }
            }
        }
        .frame(height: 80)
    }
}

// MARK: - Chart Components

struct CompactLineChart: View {
    let data: ChartData
    
    var body: some View {
        Chart(data.points) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .foregroundStyle(data.trend.color)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

struct ProgressChart: View {
    let data: ChartData
    
    var body: some View {
        let progress = data.points.last?.value ?? 0
        
        VStack(spacing: Spacing.xs.value) {
            ProgressView(value: progress / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: data.trend.color))
            
            Text("\(Int(progress))%")
                .font(Typography.captionMedium.font)
                .foregroundColor(data.trend.color)
        }
    }
}

struct DonutChart: View {
    let data: ChartData
    
    var body: some View {
        // Simplified donut chart placeholder
        ZStack {
            Circle()
                .stroke(SemanticColor.secondaryBorder.color, lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: (data.points.last?.value ?? 0) / 100)
                .stroke(data.trend.color, lineWidth: 8)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 60, height: 60)
    }
}