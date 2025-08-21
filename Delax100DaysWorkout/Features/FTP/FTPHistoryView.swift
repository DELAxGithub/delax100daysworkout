import SwiftUI
import SwiftData
import Charts

struct FTPHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FTPHistory.date, order: .reverse) private var ftpHistory: [FTPHistory]
    
    @State private var showingEntrySheet = false
    @State private var showingChart = true
    @State private var showingBulkDeleteAlert = false
    @State private var isEditMode = false
    @State private var selectedRecord: FTPHistory?
    @State private var showingEditSheet = false
    
    // Search functionality
    @State private var searchViewModel = HistorySearchViewModel<FTPHistory>()
    @State private var showingSearchResults = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Unified Header
                UnifiedHeaderComponent(
                    configuration: .history(
                        title: "FTP履歴",
                        onAdd: {
                            showingEntrySheet = true
                        },
                        onEdit: ftpHistory.isEmpty ? nil : {
                            withAnimation {
                                isEditMode.toggle()
                            }
                        },
                        isEditMode: isEditMode
                    )
                )
                .padding(.horizontal)
                .padding(.top, Spacing.sm.value)
                
                // Content
                if ftpHistory.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "FTP記録なし",
                        systemImage: "chart.bar.xaxis.ascending",
                        description: Text("ヘッダーの「+」ボタンでFTPを記録しましょう")
                    )
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.lg.value) {
                        // Chart Section
                        if showingChart {
                            BaseCard(style: ElevatedCardStyle()) {
                                VStack(alignment: .leading, spacing: Spacing.md.value) {
                                    HStack {
                                        Text("FTP推移")
                                            .font(Typography.headlineMedium.font)
                                            .foregroundColor(SemanticColor.primaryText)
                                        Spacer()
                                        Button(action: {
                                            withAnimation {
                                                showingChart.toggle()
                                            }
                                        }) {
                                            Image(systemName: showingChart ? "eye.slash" : "eye")
                                                .foregroundColor(SemanticColor.primaryAction)
                                        }
                                    }
                                
                                    if ftpHistory.count >= 2 {
                                        Chart(ftpHistory.reversed(), id: \.id) { record in
                                            LineMark(
                                                x: .value("日付", record.date),
                                                y: .value("FTP", record.ftpValue)
                                            )
                                            .foregroundStyle(SemanticColor.primaryAction.color)
                                            .lineStyle(StrokeStyle(lineWidth: 2))
                                            
                                            PointMark(
                                                x: .value("日付", record.date),
                                                y: .value("FTP", record.ftpValue)
                                            )
                                            .foregroundStyle(SemanticColor.primaryAction.color)
                                            .symbol(.circle)
                                        }
                                        .frame(height: 200)
                                        .chartYAxisLabel("FTP (W)")
                                        .chartXAxisLabel("日付")
                                    } else {
                                        Text("チャート表示には2つ以上のFTP記録が必要です")
                                            .font(Typography.bodyMedium.font)
                                            .foregroundColor(SemanticColor.secondaryText)
                                            .frame(height: 200)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Current FTP Section
                        if let currentFTP = ftpHistory.first {
                            BaseCard(style: ElevatedCardStyle()) {
                                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                                    HStack {
                                        Text("現在のFTP")
                                            .font(Typography.headlineMedium.font)
                                            .foregroundColor(SemanticColor.primaryText)
                                        Spacer()
                                        Text(currentFTP.formattedFTP)
                                            .font(Typography.displaySmall.font)
                                            .fontWeight(.bold)
                                            .foregroundColor(SemanticColor.primaryAction)
                                    }
                                
                                    // Show improvement if we have previous data
                                    if ftpHistory.count > 1 {
                                        let previousFTP = ftpHistory[1]
                                        if let change = currentFTP.ftpChange(from: previousFTP),
                                           let changePercent = currentFTP.ftpChangePercentage(from: previousFTP) {
                                            HStack {
                                                Image(systemName: change > 0 ? "arrow.up.right" : change < 0 ? "arrow.down.right" : "arrow.right")
                                                    .foregroundColor(change > 0 ? SemanticColor.successAction : change < 0 ? SemanticColor.errorAction : SemanticColor.secondaryText)
                                                Text("前回から \(change > 0 ? "+" : "")\(change)W (\(String(format: "%.1f", changePercent))%)")
                                                    .font(Typography.captionMedium.font)
                                                    .foregroundColor(SemanticColor.secondaryText)
                                            }
                                        }
                                    }
                                
                                    Text("記録日: \(currentFTP.formattedDate)")
                                        .font(Typography.captionMedium.font)
                                        .foregroundColor(SemanticColor.secondaryText)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                            // History List
                            LazyVStack(spacing: Spacing.sm.value) {
                                ForEach(ftpHistory) { record in
                                    FTPRecordRow(
                                        record: record,
                                        onEdit: {
                                            selectedRecord = record
                                            showingEditSheet = true
                                            HapticManager.shared.trigger(.selection)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // Edit Mode Actions
                            if isEditMode && !ftpHistory.isEmpty {
                                BaseCard(style: OutlinedCardStyle()) {
                                    Button(action: {
                                        showingBulkDeleteAlert = true
                                    }) {
                                        HStack {
                                            Image(systemName: "trash")
                                                .foregroundColor(SemanticColor.destructiveAction)
                                            Text("一括削除")
                                                .font(Typography.labelMedium)
                                                .foregroundColor(SemanticColor.destructiveAction)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(Spacing.md.value)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, Spacing.md.value)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEntrySheet) {
            FTPEntryView()
        }
        .alert("一括削除", isPresented: $showingBulkDeleteAlert) {
            Button("全て削除", role: .destructive) {
                deleteAllFTPRecords()
                isEditMode = false
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("\(ftpHistory.count)件のFTP記録を全て削除してもよろしいですか？この操作は取り消せません。")
        }
    }
    
    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(ftpHistory[index])
            }
            try? modelContext.save()
        }
    }
    
    private func deleteAllFTPRecords() {
        withAnimation {
            for record in ftpHistory {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
}

struct FTPRecordRow: View {
    let record: FTPHistory
    let onEdit: () -> Void
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs.value) {
                        Text(record.formattedFTP)
                            .font(Typography.headlineMedium.font)
                            .foregroundColor(SemanticColor.primaryText)
                        Text(record.methodDisplayText)
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: Spacing.xs.value) {
                        Text(record.formattedDate)
                            .font(Typography.bodyMedium.font)
                            .foregroundColor(SemanticColor.primaryText)
                        if record.isAutoCalculated {
                            HStack {
                                Image(systemName: "function")
                                    .foregroundColor(SemanticColor.primaryAction)
                                Text("自動計算")
                                    .font(Typography.captionSmall.font)
                                    .foregroundColor(SemanticColor.primaryAction)
                            }
                        }
                    }
                }
                
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                        .padding(.top, Spacing.xs.value)
                }
            }
            
            // Edit button overlay
            Button(action: onEdit) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, Spacing.xs.value)
    }
}

#Preview {
    FTPHistoryView()
        .modelContainer(for: [FTPHistory.self])
}

#Preview("FTPRecordRow") {
    List {
        FTPRecordRow(record: FTPHistory.sample, onEdit: {})
    }
    .listStyle(.plain)
    .modelContainer(for: [FTPHistory.self])
}