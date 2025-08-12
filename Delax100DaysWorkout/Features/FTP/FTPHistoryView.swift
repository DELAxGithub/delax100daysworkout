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
    
    var body: some View {
        NavigationStack {
            VStack {
                if ftpHistory.isEmpty {
                    ContentUnavailableView(
                        "FTP記録なし",
                        systemImage: "chart.bar.xaxis.ascending",
                        description: Text("右上の「+」ボタンでFTPを記録しましょう")
                    )
                } else {
                    VStack(spacing: 20) {
                        // Chart Section
                        if showingChart {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("FTP推移")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: {
                                        withAnimation {
                                            showingChart.toggle()
                                        }
                                    }) {
                                        Image(systemName: showingChart ? "eye.slash" : "eye")
                                    }
                                }
                                .padding(.horizontal)
                                
                                if ftpHistory.count >= 2 {
                                    Chart(ftpHistory.reversed(), id: \.id) { record in
                                        LineMark(
                                            x: .value("日付", record.date),
                                            y: .value("FTP", record.ftpValue)
                                        )
                                        .foregroundStyle(.blue)
                                        
                                        PointMark(
                                            x: .value("日付", record.date),
                                            y: .value("FTP", record.ftpValue)
                                        )
                                        .foregroundStyle(.blue)
                                        .symbol(.circle)
                                    }
                                    .frame(height: 200)
                                    .chartYAxisLabel("FTP (W)")
                                    .chartXAxisLabel("日付")
                                    .padding(.horizontal)
                                } else {
                                    Text("チャート表示には2つ以上のFTP記録が必要です")
                                        .foregroundColor(.secondary)
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(.systemGroupedBackground))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Current FTP Section
                        if let currentFTP = ftpHistory.first {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("現在のFTP")
                                        .font(.headline)
                                    Spacer()
                                    Text(currentFTP.formattedFTP)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                // Show improvement if we have previous data
                                if ftpHistory.count > 1 {
                                    let previousFTP = ftpHistory[1]
                                    if let change = currentFTP.ftpChange(from: previousFTP),
                                       let changePercent = currentFTP.ftpChangePercentage(from: previousFTP) {
                                        HStack {
                                            Image(systemName: change > 0 ? "arrow.up.right" : change < 0 ? "arrow.down.right" : "arrow.right")
                                                .foregroundColor(change > 0 ? .green : change < 0 ? .red : .gray)
                                            Text("前回から \(change > 0 ? "+" : "")\(change)W (\(String(format: "%.1f", changePercent))%)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Text("記録日: \(currentFTP.formattedDate)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // History List
                        List {
                            ForEach(ftpHistory) { record in
                                FTPRecordRow(record: record)
                            }
                            .onDelete(perform: deleteRecords)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("FTP履歴")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !ftpHistory.isEmpty {
                        Button(isEditMode ? "完了" : "編集") {
                            withAnimation {
                                isEditMode.toggle()
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isEditMode && !ftpHistory.isEmpty {
                            Button("一括削除") {
                                showingBulkDeleteAlert = true
                            }
                            .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            showingEntrySheet = true
                        }) {
                            Image(systemName: "plus")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(record.formattedFTP)
                        .font(.headline)
                    Text(record.methodDisplayText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(record.formattedDate)
                        .font(.subheadline)
                    if record.isAutoCalculated {
                        HStack {
                            Image(systemName: "function")
                                .foregroundColor(.purple)
                            Text("自動計算")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FTPHistoryView()
        .modelContainer(for: [FTPHistory.self])
}