import SwiftUI
import SwiftData

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var workoutRecords: [WorkoutRecord]
    @Query private var ftpHistory: [FTPHistory]
    @Query private var dailyMetrics: [DailyMetric]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyTemplates: [WeeklyTemplate]
    
    @State private var showingResetAlert = false
    @State private var showingWorkoutDeleteAlert = false
    @State private var showingFTPDeleteAlert = false
    @State private var showingMetricsDeleteAlert = false
    @State private var showingTasksDeleteAlert = false
    @State private var showingTemplatesDeleteAlert = false
    
    var totalDataCount: Int {
        workoutRecords.count + ftpHistory.count + validDailyMetrics.count + dailyTasks.count + weeklyTemplates.count
    }
    
    var validDailyMetrics: [DailyMetric] {
        dailyMetrics.filter { $0.hasAnyData }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("データベース概要")
                            .font(.headline)
                        
                        Text("総データ数: \(totalDataCount) 件")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if totalDataCount > 0 {
                            Text("全てのデータを削除すると、アプリの状態が初期化されます。")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("データ種別") {
                    DataTypeRow(
                        title: "ワークアウト記録",
                        count: workoutRecords.count,
                        icon: "figure.run",
                        color: .green,
                        action: { showingWorkoutDeleteAlert = true }
                    )
                    
                    DataTypeRow(
                        title: "FTP記録",
                        count: ftpHistory.count,
                        icon: "bolt.fill",
                        color: .blue,
                        action: { showingFTPDeleteAlert = true }
                    )
                    
                    DataTypeRow(
                        title: "体重・メトリクス",
                        count: validDailyMetrics.count,
                        icon: "scalemass.fill",
                        color: .orange,
                        action: { showingMetricsDeleteAlert = true }
                    )
                    
                    DataTypeRow(
                        title: "タスク記録",
                        count: dailyTasks.count,
                        icon: "checkmark.circle.fill",
                        color: .purple,
                        action: { showingTasksDeleteAlert = true }
                    )
                    
                    DataTypeRow(
                        title: "週間テンプレート",
                        count: weeklyTemplates.count,
                        icon: "calendar",
                        color: .indigo,
                        action: { showingTemplatesDeleteAlert = true }
                    )
                }
                
                Section("危険な操作") {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("全データを削除")
                            Spacer()
                            Text("\(totalDataCount) 件")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.red)
                    .disabled(totalDataCount == 0)
                }
            }
            .navigationTitle("データ管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("全データ削除", isPresented: $showingResetAlert) {
                TextField("削除を確認するために「削除」と入力", text: .constant(""))
                Button("削除", role: .destructive) {
                    deleteAllData()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての記録データ（\(totalDataCount)件）が完全に削除されます。この操作は取り消せません。\n\n本当に実行しますか？")
            }
            .alert("ワークアウト記録削除", isPresented: $showingWorkoutDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteWorkoutRecords()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのワークアウト記録（\(workoutRecords.count)件）を削除してもよろしいですか？")
            }
            .alert("FTP記録削除", isPresented: $showingFTPDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteFTPHistory()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのFTP記録（\(ftpHistory.count)件）を削除してもよろしいですか？")
            }
            .alert("メトリクス削除", isPresented: $showingMetricsDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteDailyMetrics()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての体重・メトリクス記録（\(validDailyMetrics.count)件）を削除してもよろしいですか？")
            }
            .alert("タスク記録削除", isPresented: $showingTasksDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteDailyTasks()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのタスク記録（\(dailyTasks.count)件）を削除してもよろしいですか？")
            }
            .alert("テンプレート削除", isPresented: $showingTemplatesDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteWeeklyTemplates()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての週間テンプレート（\(weeklyTemplates.count)件）を削除してもよろしいですか？")
            }
        }
    }
    
    // MARK: - Delete Methods
    
    private func deleteAllData() {
        withAnimation {
            // 全てのデータタイプを削除
            for record in workoutRecords {
                modelContext.delete(record)
            }
            for record in ftpHistory {
                modelContext.delete(record)
            }
            for record in dailyMetrics {
                modelContext.delete(record)
            }
            for record in dailyTasks {
                modelContext.delete(record)
            }
            for record in weeklyTemplates {
                modelContext.delete(record)
            }
            
            try? modelContext.save()
        }
    }
    
    private func deleteWorkoutRecords() {
        withAnimation {
            for record in workoutRecords {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteFTPHistory() {
        withAnimation {
            for record in ftpHistory {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteDailyMetrics() {
        withAnimation {
            // 実際にデータがあるメトリクスのみを削除
            for record in validDailyMetrics {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteDailyTasks() {
        withAnimation {
            for record in dailyTasks {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteWeeklyTemplates() {
        withAnimation {
            for record in weeklyTemplates {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
}

struct DataTypeRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("\(count) 件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if count > 0 {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                } else {
                    Text("データなし")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .disabled(count == 0)
    }
}

#Preview {
    DataManagementView()
        .modelContainer(for: [WorkoutRecord.self, FTPHistory.self, DailyMetric.self, DailyTask.self, WeeklyTemplate.self])
}