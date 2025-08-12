import SwiftUI

struct WorkoutCardView: View {
    let workoutType: WorkoutType
    let title: String
    let summary: String

    var body: some View {
        BaseCard.workout {
            HStack(spacing: Spacing.md.value) {
                Image(systemName: workoutType.iconName)
                    .font(Typography.headlineLarge.font)
                    .foregroundColor(SemanticColor.primaryAction)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    Text(summary)
                        .font(Typography.bodySmall.font)
                        .foregroundColor(SemanticColor.secondaryText)
                }
                Spacer()
            }
        }
    }
}