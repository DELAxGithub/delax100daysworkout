import SwiftUI
import SwiftData

// MARK: - Main Data Management View

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var workoutRecords: [WorkoutRecord]
    @Query private var ftpHistory: [FTPHistory]
    @Query private var dailyMetrics: [DailyMetric]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyTemplates: [WeeklyTemplate]
    @Query private var userProfiles: [UserProfile]
    
    @State private var viewModel = DataManagementViewModel()
    
    private var queries: DataManagementQueries {
        DataManagementQueries(
            workoutRecords: workoutRecords,
            ftpHistory: ftpHistory,
            dailyMetrics: dailyMetrics,
            dailyTasks: dailyTasks,
            weeklyTemplates: weeklyTemplates,
            userProfiles: userProfiles
        )
    }
    
    var body: some View {
        NavigationStack {
            DataManagementListView(
                queries: queries,
                viewModel: viewModel,
                onEdit: { model in
                    viewModel.selectedEditModel = model
                },
                onDelete: { model in
                    viewModel.showDeleteAlert(for: model)
                },
                onDeleteAll: {
                    viewModel.showingResetAlert = true
                },
                onGenerateDemo: {
                    viewModel.showingDemoDataOptions = true
                }
            )
            .navigationTitle("データ管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $viewModel.selectedEditModel) { model in
                NavigationStack {
                    Text("編集機能: \(model.displayName)")
                        .navigationTitle("編集")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("完了") {
                                    viewModel.selectedEditModel = nil
                                }
                            }
                        }
                }
            }
        }
        .addDataManagementAlerts(viewModel: viewModel, queries: queries, modelContext: modelContext)
    }
}

// MARK: - Alert Extension

extension View {
    func addDataManagementAlerts(
        viewModel: DataManagementViewModel,
        queries: DataManagementQueries,
        modelContext: ModelContext
    ) -> some View {
        self
            .alert("全データ削除", isPresented: Binding(
                get: { viewModel.showingResetAlert },
                set: { viewModel.showingResetAlert = $0 }
            )) {
                TextField("削除を確認するために「削除」と入力", text: .constant(""))
                Button("削除", role: .destructive) {
                    DataManagementService.deleteAllData(queries: queries, modelContext: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての記録データ（\(viewModel.getTotalDataCount(queries: queries))件）が完全に削除されます。この操作は取り消せません。\n\n本当に実行しますか？")
            }
            .alert("ワークアウト記録削除", isPresented: Binding(
                get: { viewModel.showingWorkoutDeleteAlert },
                set: { viewModel.showingWorkoutDeleteAlert = $0 }
            )) {
                Button("削除", role: .destructive) {
                    DataManagementService.deleteWorkoutRecords(workoutRecords: queries.workoutRecords, modelContext: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのワークアウト記録（\(queries.workoutRecords.count)件）を削除してもよろしいですか？")
            }
            .alert("FTP記録削除", isPresented: Binding(
                get: { viewModel.showingFTPDeleteAlert },
                set: { viewModel.showingFTPDeleteAlert = $0 }
            )) {
                Button("削除", role: .destructive) {
                    DataManagementService.deleteFTPHistory(ftpHistory: queries.ftpHistory, modelContext: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのFTP記録（\(queries.ftpHistory.count)件）を削除してもよろしいですか？")
            }
            .alert("メトリクス削除", isPresented: Binding(
                get: { viewModel.showingMetricsDeleteAlert },
                set: { viewModel.showingMetricsDeleteAlert = $0 }
            )) {
                Button("削除", role: .destructive) {
                    DataManagementService.deleteDailyMetrics(validDailyMetrics: queries.validDailyMetrics, modelContext: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての体重・メトリクス記録（\(queries.validDailyMetrics.count)件）を削除してもよろしいですか？")
            }
            .alert("タスク記録削除", isPresented: Binding(
                get: { viewModel.showingTasksDeleteAlert },
                set: { viewModel.showingTasksDeleteAlert = $0 }
            )) {
                Button("削除", role: .destructive) {
                    DataManagementService.deleteDailyTasks(dailyTasks: queries.dailyTasks, modelContext: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのタスク記録（\(queries.dailyTasks.count)件）を削除してもよろしいですか？")
            }
            .alert("テンプレート削除", isPresented: Binding(
                get: { viewModel.showingTemplatesDeleteAlert },
                set: { viewModel.showingTemplatesDeleteAlert = $0 }
            )) {
                Button("削除", role: .destructive) {
                    DataManagementService.deleteWeeklyTemplates(weeklyTemplates: queries.weeklyTemplates, modelContext: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての週間テンプレート（\(queries.weeklyTemplates.count)件）を削除してもよろしいですか？")
            }
            .alert("プロファイル削除", isPresented: Binding(
                get: { viewModel.showingProfileDeleteAlert },
                set: { viewModel.showingProfileDeleteAlert = $0 }
            )) {
                Button("削除", role: .destructive) {
                    DataManagementService.deleteUserProfiles(userProfiles: queries.userProfiles, modelContext: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのユーザープロファイル（\(queries.userProfiles.count)件）を削除してもよろしいですか？")
            }
            .alert("デモデータ生成", isPresented: Binding(
                get: { viewModel.showingDemoDataOptions },
                set: { viewModel.showingDemoDataOptions = $0 }
            )) {
                Button("生成") {
                    DataManagementService.generateDemoData(modelContext: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("July 2025のリアルなデモデータを生成しますか？")
            }
    }
}

#Preview {
    DataManagementView()
        .modelContainer(for: [WorkoutRecord.self, FTPHistory.self, DailyMetric.self, DailyTask.self, WeeklyTemplate.self, UserProfile.self])
}