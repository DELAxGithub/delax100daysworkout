import SwiftUI

struct WorkoutCardView: View {
    let workoutType: WorkoutType
    let title: String
    let summary: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: workoutType.iconName)
                .font(.title)
                .foregroundColor(workoutType.iconColor)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}