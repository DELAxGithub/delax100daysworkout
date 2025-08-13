import SwiftUI
import Charts

// MARK: - Interactive Summary Card

struct InteractiveSummaryCard: View {
    let configuration: SummaryCardConfiguration
    let onTap: (() -> Void)?
    
    @State private var isExpanded = false
    
    var body: some View {
        BaseCard(onTap: handleTap) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SummaryCardHeader(configuration: configuration)
                
                if isExpanded {
                    SummaryCardExpandedContent(
                        data: configuration.expandedData,
                        chartType: configuration.chartType
                    )
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
    
    private func handleTap() {
        HapticManager.shared.trigger(.impact(.medium))
        
        if configuration.expandedData != nil {
            withAnimation {
                isExpanded.toggle()
            }
        }
        
        onTap?()
    }
}

// MARK: - Configuration

struct SummaryCardConfiguration {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    let expandedData: ChartData?
    let chartType: ChartType
    
    static func basic(title: String, value: String, subtitle: String, color: Color, icon: String) -> Self {
        SummaryCardConfiguration(
            title: title, value: value, subtitle: subtitle, 
            color: color, icon: icon, expandedData: nil, chartType: .none
        )
    }
}

enum ChartType {
    case none, line, progress, donut
}

struct ChartData {
    let points: [DataPoint]
    let trend: CardTrendDirection
    
    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
}

enum CardTrendDirection {
    case up, down, stable
    
    var color: Color {
        switch self {
        case .up: return SemanticColor.successAction.color
        case .down: return SemanticColor.destructiveAction.color  
        case .stable: return SemanticColor.secondaryText.color
        }
    }
}