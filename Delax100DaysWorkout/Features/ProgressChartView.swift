import SwiftUI
import Charts

struct ProgressChartView: View {
    @State var viewModel: ProgressChartViewModel

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.dailyLogs.isEmpty {
                    ContentUnavailableView(
                        "No Progress Data",
                        systemImage: "chart.bar.xaxis.ascending",
                        description: Text("Log your daily weight to see your progress chart.")
                    )
                } else {
                    Chart {
                        // Draw the goal line first so it's in the background
                        if let goalWeight = viewModel.userProfile?.goalWeightKg, goalWeight > 0 {
                            RuleMark(y: .value("Goal", goalWeight))
                                .foregroundStyle(.green)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("Goal: \(goalWeight, specifier: "%.1f") kg")
                                        .font(.caption).foregroundColor(.green)
                                }
                        }

                        ForEach(viewModel.dailyLogs) { log in
                            LineMark(
                                x: .value("Date", log.date, unit: .day),
                                y: .value("Weight (kg)", log.weightKg)
                            )
                            .foregroundStyle(.red.gradient)
                            
                            PointMark(
                                x: .value("Date", log.date, unit: .day),
                                y: .value("Weight (kg)", log.weightKg)
                            )
                            .foregroundStyle(.red)
                        }
                    }
                    .chartYScale(domain: .automatic)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Weight Progress")
            .onAppear {
                viewModel.fetchData()
            }
        }
    }
}