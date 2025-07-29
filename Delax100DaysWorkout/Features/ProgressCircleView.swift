import SwiftUI

struct ProgressCircleView: View {
    let progress: Double
    let title: String
    let currentValue: String
    let goalValue: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.1)
                .foregroundColor(color)

            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)

            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(currentValue)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Goal: \(goalValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(4)
    }
}