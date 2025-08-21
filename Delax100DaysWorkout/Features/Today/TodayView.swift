import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodayViewModel?
    @State private var showingLogEntry = false
    @State private var selectedTask: DailyTask?
    @State private var showingQuickRecord = false
    @State private var quickRecordTask: DailyTask?
    @State private var quickRecordWorkout: WorkoutRecord?
    @State private var showDeleteAlert = false
    @State private var taskToDelete: DailyTask?
    @State private var isAnalyzing = false
    @State private var lastCompletedTask: DailyTask?
    
    private let bugReportManager = BugReportManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let viewModel = viewModel {
                    VStack(spacing: 20) {
                        // 挨拶とプログレス
                        VStack(alignment: .leading, spacing: 12) {
                            Text(viewModel.greeting)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            // プログレスバー
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("今日の進捗")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(viewModel.progressPercentage * 100))%")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.blue, .green],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(
                                                width: geometry.size.width * viewModel.progressPercentage,
                                                height: 8
                                            )
                                            .animation(.easeInOut(duration: 0.3), value: viewModel.progressPercentage)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // AI Advice Section
                        if viewModel.progressPercentage > 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.purple)
                                    Text("今日のパフォーマンス分析")
                                        .font(.headline)
                                    Spacer()
                                    
                                    if isAnalyzing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                                
                                Text("完了したワークアウトを基に、AIがアドバイスを提供します")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Spacer()
                                    
                                    Button(action: {
                                        Task {
                                            await runDailyAnalysis()
                                        }
                                    }) {
                                        HStack {
                                            if isAnalyzing {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8)
                                            }
                                            Text(isAnalyzing ? "分析中..." : "AIアドバイス")
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.purple)
                                    .disabled(isAnalyzing || viewModel.progressPercentage == 0)
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // タスクカード
                        if viewModel.todaysTasks.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                
                                Text("今日のタスクはありません")
                                    .font(.headline)
                                
                                Text("お休みの日ですね。ゆっくり休養してください！")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        } else {
                            ForEach(viewModel.todaysTasks) { task in
                                TaskCardView(
                                    task: task,
                                    onQuickComplete: {
                                        // Create workout record and show sheet
                                        if let record = viewModel.quickCompleteTask(task) {
                                            quickRecordTask = task
                                            quickRecordWorkout = record
                                            showingQuickRecord = true
                                            lastCompletedTask = task
                                        }
                                    },
                                    onDetailTap: {
                                        selectedTask = task
                                        showingLogEntry = true
                                    }
                                )
                                .opacity(viewModel.completedTasks.contains(task.id) ? 0.6 : 1.0)
                                .disabled(viewModel.completedTasks.contains(task.id))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if viewModel.completedTasks.contains(task.id) {
                                        Button(role: .destructive) {
                                            taskToDelete = task
                                            showDeleteAlert = true
                                        } label: {
                                            Label("取り消し", systemImage: "arrow.uturn.backward")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 完了メッセージ
                        if viewModel.progressPercentage >= 1.0 {
                            VStack(spacing: 12) {
                                Text("🎉")
                                    .font(.system(size: 50))
                                
                                Text("今日のトレーニング完了！")
                                    .font(.headline)
                                
                                Text("素晴らしい！この調子で続けましょう")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.green.opacity(0.1), .blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(100)
                }
            }
            .navigationTitle("今日のタスク")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Undo the last completed task
                        if let task = lastCompletedTask,
                           let vm = viewModel,
                           vm.completedTasks.contains(task.id) {
                            vm.deleteCompletedTask(task)
                            lastCompletedTask = nil
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled({
                        guard let task = lastCompletedTask,
                              let viewModel = viewModel else { return true }
                        return !viewModel.completedTasks.contains(task.id)
                    }())
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = TodayViewModel(modelContext: modelContext)
                }
                // WeeklyPlanManagerは単純化のため削除
            }
            .sheet(isPresented: $showingLogEntry) {
                if selectedTask != nil {
                    // TODO: タスクの詳細を事前入力したLogEntryViewを表示
                    LogEntryView(viewModel: LogEntryViewModel(modelContext: modelContext))
                }
            }
            .sheet(isPresented: $showingQuickRecord) {
                if let task = quickRecordTask, let record = quickRecordWorkout {
                    QuickRecordSheet(task: task, workoutRecord: record)
                }
            }
            .alert("記録を取り消しますか？", isPresented: $showDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("取り消し", role: .destructive) {
                    if let task = taskToDelete {
                        viewModel?.deleteCompletedTask(task)
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            } message: {
                Text("このタスクの完了記録が削除されます。")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func runDailyAnalysis() async {
        // AI分析は単純化されました - 設定画面で管理
        isAnalyzing = true
        // 将来的にAI分析を実装
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        isAnalyzing = false
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [WorkoutRecord.self, WeeklyTemplate.self, DailyTask.self])
}