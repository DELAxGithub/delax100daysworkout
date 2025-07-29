import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: DashboardViewModel
    
    @State private var isShowingLogEntry = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Countdown Timer
                    VStack {
                        Text("\(viewModel.daysRemaining)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(.accentColor)
                        Text("Days Remaining")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Progress Circles
                    HStack(spacing: 8) {
                        ProgressCircleView(
                            progress: viewModel.weightProgress,
                            title: "Weight",
                            currentValue: viewModel.currentWeightFormatted,
                            goalValue: viewModel.goalWeightFormatted,
                            color: .red
                        )
                        ProgressCircleView(
                            progress: viewModel.ftpProgress,
                            title: "FTP",
                            currentValue: viewModel.currentFtpFormatted,
                            goalValue: viewModel.goalFtpFormatted,
                            color: .blue
                        )
                        ProgressCircleView(
                            progress: viewModel.pwrProgress,
                            title: "PWR",
                            currentValue: viewModel.currentPwrFormatted,
                            goalValue: viewModel.goalPwrFormatted,
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    // Today's Workout Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Workout")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding([.horizontal, .top])

                        if viewModel.todaysWorkouts.isEmpty {
                            ContentUnavailableView(
                                "No Workouts Logged Today",
                                systemImage: "plus.circle",
                                description: Text("Tap the '+' button to add a workout.")
                            )
                            .padding()
                        } else {
                            ForEach(viewModel.todaysWorkouts, id: \.self) { workout in
                                WorkoutCardView(
                                    workoutType: workout.workoutType,
                                    title: workout.workoutType.rawValue,
                                    summary: workout.summary
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingLogEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                viewModel.refreshData()
            }
            .sheet(isPresented: $isShowingLogEntry, onDismiss: {
                viewModel.refreshData()
            }) {
                LogEntryView(viewModel: LogEntryViewModel(modelContext: modelContext))
            }
        }
    }
}