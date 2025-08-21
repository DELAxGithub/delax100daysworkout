import SwiftUI
import SwiftData
import Charts

struct SSTDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SSTDashboardViewModel()
    @State private var showingFTPEntry = false
    @State private var showingDemoDataAlert = false
    @State private var demoDataMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Current FTP Card
                    CurrentFTPCard(
                        currentFTP: viewModel.currentFTP,
                        goalFTP: viewModel.goalFTP,
                        progress: viewModel.ftpProgress,
                        change: viewModel.formattedFTPChange,
                        trend: viewModel.getFTPTrend(),
                        onAddFTP: {
                            showingFTPEntry = true
                        }
                    )
                    
                    // 20-Minute Power Target Card
                    if let twentyMinTarget = viewModel.twentyMinutePowerTarget {
                        TwentyMinutePowerTargetCard(
                            currentFTP: viewModel.currentFTP ?? 0,
                            twentyMinTarget: twentyMinTarget
                        )
                    }
                    
                    // FTP Progress Chart
                    FTPProgressChart(history: viewModel.ftpHistory)
                    
                    // W/HR Efficiency Chart
                    if !viewModel.whrData.isEmpty {
                        WHREfficiencyChart(
                            whrData: viewModel.whrData,
                            trend: viewModel.getWHRTrend()
                        )
                    }
                    
                    // Debug Demo Data Section
                    #if DEBUG
                    DemoDataSection(
                        modelContext: modelContext,
                        onDemoDataGenerated: {
                            viewModel.refreshData()
                        },
                        onShowMessage: { message in
                            demoDataMessage = message
                            showingDemoDataAlert = true
                        }
                    )
                    #endif
                }
                .padding()
            }
            .navigationTitle("SST進捗")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("更新", systemImage: "arrow.clockwise") {
                        viewModel.refreshData()
                    }
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
        }
        .sheet(isPresented: $showingFTPEntry) {
            NavigationStack {
                FTPEntryView()
                    .navigationTitle("FTP記録")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("キャンセル") {
                                showingFTPEntry = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.loadData()
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("デモデータ", isPresented: $showingDemoDataAlert) {
            Button("OK") { }
        } message: {
            Text(demoDataMessage)
        }
    }
}

// MARK: - Current FTP Card

struct CurrentFTPCard: View {
    let currentFTP: Int?
    let goalFTP: Int?
    let progress: Double
    let change: String?
    let trend: FTPTrend
    let onAddFTP: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("現在のFTP")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onAddFTP) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            if let currentFTP = currentFTP {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("\(currentFTP)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("W")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .offset(y: -8)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let change = change {
                            Text(change)
                                .font(.caption)
                                .foregroundColor(change.hasPrefix("+") ? .green : .red)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: trend.iconName)
                                .font(.caption)
                                .foregroundColor(trend.color)
                            
                            Text(trend.displayText)
                                .font(.caption)
                                .foregroundColor(trend.color)
                        }
                    }
                }
                
                if let goalFTP = goalFTP {
                    VStack(spacing: 8) {
                        HStack {
                            Text("目標: \(goalFTP)W")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(progress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "bolt.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("FTPを記録して\n進捗を確認しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("FTPを記録", action: onAddFTP)
                        .buttonStyle(.borderedProminent)
                }
                .frame(minHeight: 120)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 20-Minute Power Target Card

struct TwentyMinutePowerTargetCard: View {
    let currentFTP: Int
    let twentyMinTarget: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("20分パワー目標")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(twentyMinTarget)")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                
                Text("W")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .offset(y: -6)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("FTP + 5%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("= \(currentFTP) + \(twentyMinTarget - currentFTP)W")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("20分間の平均パワーでこの目標を達成できれば、FTP向上の可能性があります")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - FTP Progress Chart

struct FTPProgressChart: View {
    let history: [FTPHistory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FTP推移")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !history.isEmpty {
                    Text("過去\(history.count)回の記録")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("FTPを記録して推移を確認しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
            } else {
                Chart(history.reversed(), id: \.id) { record in
                    LineMark(
                        x: .value("日付", record.date),
                        y: .value("FTP", record.ftpValue)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("日付", record.date),
                        y: .value("FTP", record.ftpValue)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                    .symbolSize(60)
                }
                .frame(height: 180)
                .chartYScale(domain: .automatic)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)W")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - W/HR Efficiency Chart

struct WHREfficiencyChart: View {
    let whrData: [WHRDataPoint]
    let trend: WHRTrend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("W/HR効率")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(trend.displayText)
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
            }
            
            if whrData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("心拍数データを記録して\n効率を確認しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
            } else {
                Chart(whrData, id: \.id) { dataPoint in
                    LineMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("W/HR", dataPoint.whrRatio)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("W/HR", dataPoint.whrRatio)
                    )
                    .foregroundStyle(.red.opacity(0.1))
                }
                .frame(height: 140)
                .chartYScale(domain: .automatic)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(String(format: "%.1f", doubleValue))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    SSTDashboardView()
        .modelContainer(for: [FTPHistory.self, DailyMetric.self, WorkoutRecord.self])
}

#Preview("Sample Data") {
    let viewModel = SSTDashboardViewModel.sampleViewModel()
    
    return NavigationStack {
        ScrollView {
            LazyVStack(spacing: 20) {
                CurrentFTPCard(
                    currentFTP: viewModel.currentFTP,
                    goalFTP: viewModel.goalFTP,
                    progress: viewModel.ftpProgress,
                    change: viewModel.formattedFTPChange,
                    trend: viewModel.getFTPTrend(),
                    onAddFTP: {}
                )
                
                if let twentyMinTarget = viewModel.twentyMinutePowerTarget {
                    TwentyMinutePowerTargetCard(
                        currentFTP: viewModel.currentFTP ?? 0,
                        twentyMinTarget: twentyMinTarget
                    )
                }
                
                FTPProgressChart(history: viewModel.ftpHistory)
                
                WHREfficiencyChart(
                    whrData: viewModel.whrData,
                    trend: viewModel.getWHRTrend()
                )
            }
            .padding()
        }
        .navigationTitle("SST進捗")
    }
}

// MARK: - Demo Data Section (Debug Only)

#if DEBUG
struct DemoDataSection: View {
    let modelContext: ModelContext
    let onDemoDataGenerated: () -> Void
    let onShowMessage: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text("開発者ツール")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("DEBUG")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                // TODO: Re-implement demo data manager
                // Demo data generation temporarily disabled
                
                Text("デモデータ機能は一時的に無効化されています")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("デモデータ生成（無効）") {
                    // generateDemoData()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.gray)
                .disabled(true)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func generateDemoData() {
        DispatchQueue.global(qos: .userInitiated).async {
            // TODO: Re-implement demo data generation
            // DemoDataManager.generateJuly2025DemoData(modelContext: modelContext)
            
            DispatchQueue.main.async {
                onDemoDataGenerated()
                onShowMessage("2025年7月のデモデータを生成しました！\n\n• FTP: 260W → 275W の成長\n• 13回のサイクリングワークアウト\n• 31日間の体重・心拍数記録")
            }
        }
    }
}
#endif