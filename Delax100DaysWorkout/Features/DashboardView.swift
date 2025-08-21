import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: DashboardViewModel
    
    @State private var isShowingLogEntry = false
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: WorkoutRecord?
    @State private var isAnalyzing = false
    @State private var showingMetricEntry = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    countdownSection
                    progressSection
                    aiAnalysisSection
                    todaysWorkoutSection
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
            }
            .sheet(isPresented: $isShowingLogEntry, onDismiss: {
                viewModel.refreshData()
            }) {
                QuickRecordView()
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
    
    // MARK: - View Components
    
    @ViewBuilder
    private var countdownSection: some View {
        VStack {
            Text("\(viewModel.daysRemaining)")
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(.accentColor)
            Text("残り日数")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
    
    @ViewBuilder
    private var progressSection: some View {
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
    }
    
    @ViewBuilder
    private var aiAnalysisSection: some View {
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
            
            // AI分析機能は単純化されました
            Text("AI分析機能は設定で管理されています")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
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
                .disabled(isAnalyzing)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var todaysWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日のワークアウト")
                .font(.title)
                .fontWeight(.bold)
                .padding([.horizontal, .top])

            if viewModel.todaysWorkouts.isEmpty {
                ContentUnavailableView(
                    "今日のワークアウトはありません",
                    systemImage: "plus.circle",
                    description: Text("「+」ボタンでワークアウトを追加してください")
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
    
    // MARK: - Helper Methods
    
    @MainActor
    private func runQuickAnalysis() async {
        isAnalyzing = true
        // 分析機能は単純化されました
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待機
        isAnalyzing = false
    }
}