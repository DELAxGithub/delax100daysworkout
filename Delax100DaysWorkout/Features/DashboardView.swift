import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: DashboardViewModel
    
    @State private var isShowingLogEntry = false
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: WorkoutRecord?
    @State private var weeklyPlanManager: WeeklyPlanManager?
    @State private var isAnalyzing = false
    @State private var showingMetricEntry = false
    
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

                    // AI Analysis Quick Access
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                            Text("AI分析")
                                .font(.headline)
                            Spacer()
                            
                            if isAnalyzing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if let manager = weeklyPlanManager {
                            Text(getAnalysisDescription(manager))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("状態: \(analysisStatusText(for: manager.updateStatus))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // 最後の更新内容表示
                            if manager.updateStatus == .completed,
                               let suggestion = manager.lastUpdateSuggestion {
                                VStack(alignment: .leading, spacing: 8) {
                                    Divider()
                                    
                                    Text("最新の変更内容")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                    
                                    Text(suggestion.reasoning)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if !suggestion.recommendedChanges.isEmpty {
                                        Text("適用された変更:")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        
                                        ForEach(suggestion.recommendedChanges.indices, id: \.self) { index in
                                            let change = suggestion.recommendedChanges[index]
                                            Text("✓ \(change.taskTitle): \(change.reason)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Text("適用日時: \(manager.lastUpdateDate?.formatted(date: .abbreviated, time: .shortened) ?? "")")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                            }
                        } else {
                            Text("進捗データを基に最適なトレーニング調整を提案")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            if let manager = weeklyPlanManager, manager.canRevert {
                                Button("元に戻す") {
                                    Task {
                                        await manager.revertLastUpdate()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await runQuickAnalysis()
                                }
                            }) {
                                HStack {
                                    if isAnalyzing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(isAnalyzing ? "分析中..." : "今すぐ分析")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .disabled(isAnalyzing || (weeklyPlanManager?.updateStatus == .analyzing))
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
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
                    Menu {
                        Button("ワークアウト記録", systemImage: "figure.run") {
                            isShowingLogEntry = true
                        }
                        Button("日次記録", systemImage: "heart.text.square") {
                            showingMetricEntry = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                viewModel.refreshData()
                if weeklyPlanManager == nil {
                    weeklyPlanManager = WeeklyPlanManager(modelContext: modelContext)
                }
            }
            .sheet(isPresented: $isShowingLogEntry, onDismiss: {
                viewModel.refreshData()
            }) {
                LogEntryView(viewModel: LogEntryViewModel(modelContext: modelContext))
            }
            .sheet(isPresented: $showingMetricEntry, onDismiss: {
                viewModel.refreshData()
            }) {  
                DailyMetricEntryView()
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
    
    // MARK: - Helper Methods
    
    @MainActor
    private func runQuickAnalysis() async {
        guard let manager = weeklyPlanManager else { return }
        isAnalyzing = true
        await manager.requestManualUpdate()
        isAnalyzing = false
    }
    
    private func analysisStatusText(for status: PlanUpdateStatus) -> String {
        switch status {
        case .idle:
            return "分析可能"
        case .analyzing:
            return "分析中..."
        case .completed:
            return "最新プラン適用済み"
        case .failed(_):
            return "エラー"
        }
    }
    
    private func getAnalysisDescription(_ manager: WeeklyPlanManager) -> String {
        if manager.updateStatus == .analyzing {
            return manager.analysisDataDescription
        } else if let result = manager.lastAnalysisResult {
            return "最新結果: \(result)"
        } else {
            return "進捗データを基に最適なトレーニング調整を提案"
        }
    }
}