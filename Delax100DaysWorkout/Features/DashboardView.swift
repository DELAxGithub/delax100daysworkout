import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: DashboardViewModel
    
    @State private var isShowingLogEntry = false
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: WorkoutRecord?
    
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
                                EditableWorkoutCardView(
                                    workout: workout,
                                    onEdit: { editedWorkout in
                                        viewModel.updateWorkout(workout, with: editedWorkout)
                                    },
                                    onDelete: { workoutToDelete in
                                        self.workoutToDelete = workoutToDelete
                                        showingDeleteAlert = true
                                    }
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
            .alert("ワークアウトを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let workout = workoutToDelete {
                        viewModel.deleteWorkout(workout)
                        workoutToDelete = nil
                    }
                }
                Button("キャンセル", role: .cancel) {
                    workoutToDelete = nil
                }
            } message: {
                Text("このワークアウトを削除してもよろしいですか？この操作は取り消せません。")
            }
        }
    }
}