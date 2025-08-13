import SwiftUI

struct WorkoutCardView: View {
    let workoutType: WorkoutType
    let title: String
    let summary: String

    var body: some View {
        BaseCard(onTap: {}) {
            HStack(spacing: Spacing.md.value) {
                Image(systemName: workoutType.iconName)
                    .font(Typography.headlineLarge.font)
                    .foregroundColor(SemanticColor.primaryAction.color)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    Text(summary)
                        .font(Typography.bodySmall.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                }
                Spacer()
            }
        }
    }
}