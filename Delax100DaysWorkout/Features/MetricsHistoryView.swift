import SwiftUI
import SwiftData
import Charts

struct MetricsHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyMetric.date, order: .reverse) private var dailyMetrics: [DailyMetric]
    
    @State private var showingFilterSheet = false
    @State private var showingEditSheet = false
    @State private var selectedMetric: DailyMetric?
    @State private var showingDeleteAlert = false
    @State private var metricToDelete: DailyMetric?
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var selectedDataSource: MetricDataSource? = nil
    @State private var showingChart = true
    @State private var showingBulkDeleteAlert = false
    @State private var isEditMode = false
    
    private var filteredMetrics: [DailyMetric] {
        var filtered = dailyMetrics
        
        // フィルター適用
        if let selectedSource = selectedDataSource {
            filtered = filtered.filter { $0.dataSource == selectedSource }
        }
        
        filtered = filtered.filter { $0.date >= startDate && $0.date <= endDate }
        
        return filtered.filter { $0.hasAnyData }
    }
    
    private var metricsWithWeight: [DailyMetric] {
        filteredMetrics.compactMap { $0.weightKg != nil ? $0 : nil }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick Weight Entry
                QuickWeightEntry()
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 8)
                // Chart Toggle
                BaseCard(style: DefaultCardStyle()) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                showingChart.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: showingChart ? "eye.slash" : "eye")
                                    .foregroundColor(SemanticColor.primaryAction)
                                Text(showingChart ? "チャートを隠す" : "チャートを表示")
                                    .font(Typography.captionMedium.font)
                                    .foregroundColor(SemanticColor.primaryAction)
                            }
                        }
                        
                        Spacer()
                        
                        Text("データ数: \(filteredMetrics.count)")
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if showingChart && !metricsWithWeight.isEmpty {
                    // Weight Chart
                    BaseCard(style: ElevatedCardStyle()) {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            Text("体重推移")
                                .font(Typography.headlineMedium.font)
                                .foregroundColor(SemanticColor.primaryText)
                        
                            Chart(metricsWithWeight.reversed(), id: \.id) { metric in
                                if let weight = metric.weightKg {
                                    LineMark(
                                        x: .value("日付", metric.date),
                                        y: .value("体重", weight)
                                    )
                                    .foregroundStyle(SemanticColor.warningAction.color)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                    
                                    PointMark(
                                        x: .value("日付", metric.date),
                                        y: .value("体重", weight)
                                    )
                                    .foregroundStyle(SemanticColor.warningAction.color)
                                    .symbol(Circle())
                                }
                            }
                            .frame(height: 150)
                            .chartYAxisLabel("体重 (kg)")
                            .chartXAxisLabel("日付")
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Summary Cards
                if !filteredMetrics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            MetricSummaryCard(
                                title: "記録数",
                                value: "\(filteredMetrics.count)",
                                subtitle: "日",
                                color: .blue,
                                icon: "calendar.badge.plus"
                            )
                            
                            if let latestWeight = metricsWithWeight.first?.weightKg {
                                MetricSummaryCard(
                                    title: "最新体重",
                                    value: String(format: "%.1f", latestWeight),
                                    subtitle: "kg",
                                    color: .orange,
                                    icon: "scalemass.fill"
                                )
                            }
                            
                            if metricsWithWeight.count > 1 {
                                let weightChange = calculateWeightChange()
                                MetricSummaryCard(
                                    title: "体重変化",
                                    value: String(format: "%+.1f", weightChange),
                                    subtitle: "kg",
                                    color: weightChange < 0 ? .green : .red,
                                    icon: weightChange < 0 ? "arrow.down" : "arrow.up"
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                if filteredMetrics.isEmpty {
                    ContentUnavailableView(
                        "メトリクス履歴なし",
                        systemImage: "scalemass.circle",
                        description: Text("体重や心拍数を記録して履歴を確認しましょう")
                    )
                } else {
                    List {
                        ForEach(filteredMetrics) { metric in
                            MetricHistoryRow(
                                metric: metric,
                                onEdit: { 
                                    selectedMetric = metric
                                    showingEditSheet = true
                                },
                                onDelete: { metricToDelete in
                                    self.metricToDelete = metricToDelete
                                    showingDeleteAlert = true
                                }
                            )
                        }
                        .onDelete(perform: deleteMetrics)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("メトリクス履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !filteredMetrics.isEmpty {
                        Button(isEditMode ? "完了" : "編集") {
                            withAnimation {
                                isEditMode.toggle()
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isEditMode && !filteredMetrics.isEmpty {
                            Button("一括削除") {
                                showingBulkDeleteAlert = true
                            }
                            .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                MetricsFilterSheet(
                    selectedDataSource: $selectedDataSource,
                    startDate: $startDate,
                    endDate: $endDate
                )
            }
            .sheet(isPresented: $showingEditSheet) {
                if let metric = selectedMetric {
                    MetricEditSheet(
                        metric: metric,
                        onSave: { editedMetric in
                            updateMetric(metric, with: editedMetric)
                        }
                    )
                }
            }
            .alert("メトリクスを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let metric = metricToDelete {
                        deleteMetric(metric)
                        metricToDelete = nil
                    }
                }
                Button("キャンセル", role: .cancel) {
                    metricToDelete = nil
                }
            } message: {
                Text("このメトリクス記録を削除してもよろしいですか？この操作は取り消せません。")
            }
            .alert("一括削除", isPresented: $showingBulkDeleteAlert) {
                Button("全て削除", role: .destructive) {
                    deleteAllFilteredMetrics()
                    isEditMode = false
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("表示中の\(filteredMetrics.count)件のメトリクスを全て削除してもよろしいですか？この操作は取り消せません。")
            }
        }
    }
    
    // MARK: - Methods
    
    private func calculateWeightChange() -> Double {
        guard metricsWithWeight.count > 1,
              let latest = metricsWithWeight.first?.weightKg,
              let earliest = metricsWithWeight.last?.weightKg else {
            return 0.0
        }
        return latest - earliest
    }
    
    private func updateMetric(_ metric: DailyMetric, with editedMetric: DailyMetric) {
        metric.weightKg = editedMetric.weightKg
        metric.restingHeartRate = editedMetric.restingHeartRate
        metric.maxHeartRate = editedMetric.maxHeartRate
        metric.date = editedMetric.date
        metric.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    private func deleteMetrics(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredMetrics[index])
            }
            try? modelContext.save()
        }
    }
    
    private func deleteMetric(_ metric: DailyMetric) {
        withAnimation {
            modelContext.delete(metric)
            try? modelContext.save()
        }
    }
    
    private func deleteAllFilteredMetrics() {
        withAnimation {
            for metric in filteredMetrics {
                modelContext.delete(metric)
            }
            try? modelContext.save()
        }
    }
}