import SwiftUI

// MARK: - History Summary Card

struct HistorySummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(Typography.captionMedium.font)
                    Spacer()
                }
                
                Text(value)
                    .font(Typography.headlineSmall.font)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColor.primaryText)
                
                Text(title)
                    .font(Typography.captionSmall.font)
                    .foregroundColor(SemanticColor.secondaryText)
            }
        }
        .frame(width: 80, height: 60)
    }
}