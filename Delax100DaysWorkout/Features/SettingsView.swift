import SwiftUI
import SwiftData

struct SettingsView: View {
    @State var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isMigratingCounters = false
    @State private var hasInitializationError = false

    var body: some View {
        if hasInitializationError {
            // エラー状態の表示
            NavigationStack {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("設定画面の初期化中にエラーが発生しました")
                        .font(.headline)
                    Button("再試行") {
                        hasInitializationError = false
                        // ViewModelを再作成
                        viewModel = SettingsViewModel(modelContext: modelContext)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("設定")
            }
        } else {
        NavigationStack {
            Form {
                Section(header: Text("チャレンジ期間")) {
                    DatePicker("目標日", selection: $viewModel.goalDate, displayedComponents: .date)
                }

                Section(header: Text("体重目標")) {
                    HStack {
                        Text("開始体重")
                        Spacer()
                        TextField("体重", value: $viewModel.startWeightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("目標体重")
                        Spacer()
                        TextField("体重", value: $viewModel.goalWeightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("サイクリングFTP目標")) {
                    HStack {
                        Text("開始FTP")
                        Spacer()
                        TextField("FTP", value: $viewModel.startFtp, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("目標FTP")
                        Spacer()
                        TextField("FTP", value: $viewModel.goalFtp, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                HealthcareSection(viewModel: viewModel)
                
                // HealthKit テストビュー
                Section(header: Text("HealthKit テスト")) {
                    NavigationLink("健康データビュー") {
                        HealthDataView()
                            .navigationTitle("HealthKit テスト")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
                
                // ClaudeApiSection(viewModel: viewModel) // Temporarily disabled
                
                AIAnalysisSection(viewModel: $viewModel)
                
                AnalysisInfoSection(viewModel: $viewModel)
                
                Section(header: Text("回数カウンター管理")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("履歴からカウンター移行")
                                    .font(.headline)
                                Text("既存のワークアウト履歴から回数を自動集計し、カウンターを更新します（8月1日以降）")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Text(isMigratingCounters ? "移行中..." : "準備完了")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await migrateCounters()
                                }
                            }) {
                                HStack {
                                    if isMigratingCounters {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text(isMigratingCounters ? "移行中..." : "履歴移行を実行")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isMigratingCounters)
                        }
                        
                        // カウンター統計表示
                        ForEach(getAllCounterStats(), id: \.taskType) { stat in
                            HStack {
                                Text(TaskIdentificationUtils.getDisplayName(for: stat.taskType))
                                    .font(.caption)
                                Spacer()
                                Text("\(stat.counter.completionCount)回 / \(stat.counter.currentTarget)回")
                                    .font(.caption)
                                    .foregroundColor(stat.counter.isTargetAchieved ? .green : .secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("AI分析実行")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("手動分析実行")
                                    .font(.headline)
                                Text("あなたの進捗データを基に、最適なトレーニング調整を提案します")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Text("状態: \(viewModel.analysisStatusText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await viewModel.runManualAnalysis()
                                }
                            }) {
                                HStack {
                                    if viewModel.isAnalyzing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text(viewModel.isAnalyzing ? "分析中..." : "今すぐ分析")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.canRunAnalysis)
                        }
                    }
                }
                
                // 開発時用データベースリセット
                #if DEBUG
                Section(header: Text("開発者ツール")) {
                    Button("データベースをリセット") {
                        viewModel.resetDatabase()
                    }
                    .foregroundColor(.red)
                }
                #endif
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if viewModel.save() {
                            dismiss()
                        }
                        // 保存失敗時は画面を閉じないでエラーを表示
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.refreshHealthKitStatus()
                }
            }
            .alert("保存エラー", isPresented: $viewModel.showSaveError) {
                Button("OK", role: .cancel) {
                    viewModel.showSaveError = false
                }
            } message: {
                Text(viewModel.saveError)
            }
            .alert("保存完了", isPresented: $viewModel.showSaveConfirmation) {
                Button("OK", role: .cancel) {
                    viewModel.showSaveConfirmation = false
                }
            } message: {
                Text("設定が正常に保存されました。")
            }
        }
        }
    }
    
    // MARK: - Helper Methods
    
    private func migrateCounters() async {
        isMigratingCounters = true
        
        TaskCounterService.shared.migrateFromHistory(
            startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 1)) ?? Date(),
            in: modelContext
        )
        
        isMigratingCounters = false
    }
    
    private func getAllCounterStats() -> [(taskType: String, counter: TaskCompletionCounter)] {
        return TaskCounterService.shared.getAllCounterStats(in: modelContext)
    }
}