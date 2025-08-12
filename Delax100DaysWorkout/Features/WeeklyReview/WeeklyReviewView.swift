import SwiftUI
import SwiftData

struct WeeklyReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var planManager: WeeklyPlanManager
    @State private var showingProgressDetails = false
    
    @Query private var workoutRecords: [WorkoutRecord]
    @Query private var activeTemplates: [WeeklyTemplate]
    
    init() {
        // 過去4週間のレコードを取得
        let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()
        self._workoutRecords = Query(
            filter: #Predicate<WorkoutRecord> { record in
                record.date >= fourWeeksAgo
            },
            sort: \WorkoutRecord.date,
            order: .reverse
        )
        
        // アクティブなテンプレートを取得
        self._activeTemplates = Query(
            filter: #Predicate<WeeklyTemplate> { template in
                template.isActive == true
            }
        )
        
        // ModelContainer作成時のエラーを適切に処理
        do {
            let container = try ModelContainer(for: WorkoutRecord.self, WeeklyTemplate.self)
            self._planManager = StateObject(wrappedValue: WeeklyPlanManager(modelContext: ModelContext(container)))
        } catch {
            // エラーが発生した場合は、メモリ内ストレージで fallback コンテナを作成
            print("Failed to create model container: \(error)")
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let fallbackContainer = try? ModelContainer(
                for: WorkoutRecord.self, WeeklyTemplate.self,
                configurations: config
            )
            // fallbackも失敗した場合は、空のModelContextを使用
            if let container = fallbackContainer {
                self._planManager = StateObject(wrappedValue: WeeklyPlanManager(modelContext: ModelContext(container)))
            } else {
                // 最後の手段として、デフォルトのModelContextを使用
                // 注意: この場合、機能が制限される可能性があります
                fatalError("Critical error: Unable to initialize model container. Please restart the app.")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(spacing: 20) {
                    headerSection
                    
                    if let activeTemplate = activeTemplates.first {
                        progressSummarySection(template: activeTemplate)
                        
                        aiAnalysisSection
                        
                        // AI分析の説明
                        aiSuggestionPlaceholder()
                    } else {
                        noActiveTemplateSection
                    }
                }
                .padding()
            }
            .navigationTitle("週次レビュー")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingProgressDetails) {
            if let activeTemplate = activeTemplates.first {
                ProgressDetailsSheet(records: workoutRecords, template: activeTemplate)
            }
        }
        .onAppear {
            setupPlanManager()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("今週のパフォーマンス")
                        .font(.headline)
                    Text("AIがあなたの進捗を分析します")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func progressSummarySection(template: WeeklyTemplate) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("進捗サマリー")
                    .font(.headline)
                
                Spacer()
                
                Button("詳細") {
                    showingProgressDetails = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            let analyzer = ProgressAnalyzer(modelContext: modelContext)
            let weeklyStats = analyzer.calculateWeeklyStats(records: workoutRecords, template: template)
            
            HStack(spacing: 20) {
                ProgressMetricCard(
                    title: "完了率",
                    value: "\(Int(weeklyStats.completionRate * 100))%",
                    color: weeklyStats.completionRate > 0.8 ? .green : weeklyStats.completionRate > 0.6 ? .orange : .red
                )
                
                ProgressMetricCard(
                    title: "総ワークアウト",
                    value: "\(weeklyStats.completedWorkouts)",
                    color: .blue
                )
                
                ProgressMetricCard(
                    title: "継続日数",
                    value: "\(analyzer.analyzeProgress(records: workoutRecords).currentStreak)",
                    color: .purple
                )
            }
            
            workoutTypeBreakdown(stats: weeklyStats)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func workoutTypeBreakdown(stats: WeeklyStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("種目別進捗")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                WorkoutTypeProgressRow(
                    type: "サイクリング",
                    icon: "bicycle",
                    stats: stats.cyclingStats,
                    color: .green
                )
                
                WorkoutTypeProgressRow(
                    type: "筋トレ",
                    icon: "dumbbell",
                    stats: stats.strengthStats,
                    color: .red
                )
                
                WorkoutTypeProgressRow(
                    type: "柔軟性",
                    icon: "figure.flexibility",
                    stats: stats.flexibilityStats,
                    color: .blue
                )
            }
        }
    }
    
    private var aiAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("AI分析")
                    .font(.headline)
                
                Spacer()
                
                if case .analyzing = planManager.updateStatus {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Text("Dashboard画面の「今すぐ分析」ボタンでAI分析を実行できます。分析結果は自動的に適用されます。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("状態:")
                    .font(.caption)
                Spacer()
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusText: String {
        switch planManager.updateStatus {
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
    
    private var aiIdleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("来週のトレーニングプランを最適化しませんか？")
                .font(.subheadline)
            
            Text("あなたの進捗データを基に、AIが最適なトレーニング調整を提案します。")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("AI分析を開始") {
                Task {
                    await planManager.initiateWeeklyPlanUpdate()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
    }
    
    private var aiAnalyzingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("データを分析中...")
                    .font(.subheadline)
            }
            
            Text("あなたの過去4週間のデータを分析し、最適なプランを作成しています。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    
    private var aiApplyingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("プランを適用中...")
                    .font(.subheadline)
            }
            
            Text("新しいトレーニングプランを設定しています。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var aiCompletedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("プラン更新完了")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text("新しいトレーニングプランが適用されました。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func aiFailedSection(error: Error) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("エラーが発生しました")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("再試行") {
                Task {
                    await planManager.initiateWeeklyPlanUpdate()
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }
    
    // AI提案セクションは新しい自動適用システムでは不要になりました
    private func aiSuggestionPlaceholder() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI分析結果")
                .font(.headline)
            
            Text("Dashboard画面で「今すぐ分析」を実行すると、AIが最適なプランを提案して自動適用します。")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var noActiveTemplateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("アクティブなテンプレートがありません")
                .font(.headline)
            
            Text("週次レビューを行うには、まずトレーニングテンプレートを設定してください。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func setupPlanManager() {
        // WeeklyPlanManagerのmodelContextを正しく設定
        let newPlanManager = WeeklyPlanManager(modelContext: modelContext)
        planManager.updateStatus = newPlanManager.updateStatus
    }
}

struct ProgressMetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct WorkoutTypeProgressRow: View {
    let type: String
    let icon: String
    let stats: WorkoutTypeStats
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(type)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(stats.completed)/\(stats.target)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ProgressView(value: stats.completionRate)
                .frame(width: 60)
                .tint(color)
        }
    }
}

#Preview {
    WeeklyReviewView()
}