import SwiftUI
import SwiftData

// MARK: - Metric History Row

struct MetricHistoryRow: View {
    let metric: DailyMetric
    let onEdit: () -> Void
    let onDelete: (DailyMetric) -> Void
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs.value) {
                        Text(metric.formattedDate)
                            .font(Typography.headlineMedium.font)
                            .foregroundColor(SemanticColor.primaryText)
                        
                        HStack {
                            Image(systemName: metric.dataSource.iconName)
                                .foregroundColor(SemanticColor.secondaryText)
                                .font(Typography.captionMedium.font)
                            
                            Text(metric.dataSource.displayName)
                                .font(Typography.captionMedium.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: Spacing.xs.value) {
                        if let weight = metric.formattedWeight {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(SemanticColor.warningAction)
                                    .font(Typography.captionMedium.font)
                                Text(weight)
                                    .font(Typography.bodyMedium.font)
                                    .fontWeight(.medium)
                                    .foregroundColor(SemanticColor.primaryText)
                            }
                        }
                        
                        if let restingHR = metric.formattedRestingHR {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(SemanticColor.errorAction)
                                    .font(Typography.captionMedium.font)
                                Text(restingHR)
                                    .font(Typography.captionMedium.font)
                                    .foregroundColor(SemanticColor.primaryText)
                            }
                        }
                        
                        if let maxHR = metric.formattedMaxHR {
                            HStack {
                                Image(systemName: "heart.circle.fill")
                                    .foregroundColor(SemanticColor.primaryAction)
                                    .font(Typography.captionMedium.font)
                                Text(maxHR)
                                    .font(Typography.captionMedium.font)
                                    .foregroundColor(SemanticColor.primaryText)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xs.value)
        .contentShape(Rectangle())
        .swipeActions(edge: .leading) {
            Button("編集") {
                onEdit()
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing) {
            Button("削除", role: .destructive) {
                onDelete(metric)
            }
        }
    }
}

// MARK: - Metric Edit Sheet

struct MetricEditSheet: View {
    let metric: DailyMetric
    let onSave: (DailyMetric) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var editedWeight: String = ""
    @State private var editedRestingHR: String = ""
    @State private var editedMaxHR: String = ""
    @State private var editedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("日時") {
                    DatePicker("記録日時", selection: $editedDate)
                }
                
                Section("体重") {
                    HStack {
                        TextField("体重", text: $editedWeight)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("心拍数") {
                    HStack {
                        TextField("安静時心拍数", text: $editedRestingHR)
                            .keyboardType(.numberPad)
                        Text("bpm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("最大心拍数", text: $editedMaxHR)
                            .keyboardType(.numberPad)
                        Text("bpm")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Text("※ 空欄にすると該当データが削除されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("メトリクス編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            editedWeight = metric.weightKg.map { String(format: "%.1f", $0) } ?? ""
            editedRestingHR = metric.restingHeartRate.map { String($0) } ?? ""
            editedMaxHR = metric.maxHeartRate.map { String($0) } ?? ""
            editedDate = metric.date
        }
    }
    
    private func saveChanges() {
        let editedMetric = DailyMetric(date: editedDate)
        
        // 体重
        if !editedWeight.isEmpty, let weight = Double(editedWeight), DailyMetric.isValidWeight(weight) {
            editedMetric.weightKg = weight
        }
        
        // 安静時心拍数
        if !editedRestingHR.isEmpty, let restingHR = Int(editedRestingHR), DailyMetric.isValidRestingHeartRate(restingHR) {
            editedMetric.restingHeartRate = restingHR
        }
        
        // 最大心拍数
        if !editedMaxHR.isEmpty, let maxHR = Int(editedMaxHR), DailyMetric.isValidMaxHeartRate(maxHR) {
            editedMetric.maxHeartRate = maxHR
        }
        
        onSave(editedMetric)
    }
}

// MARK: - Metrics Filter Sheet

struct MetricsFilterSheet: View {
    @Binding var selectedDataSource: MetricDataSource?
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("データソース") {
                    Picker("データソース", selection: $selectedDataSource) {
                        Text("全て").tag(MetricDataSource?.none)
                        ForEach(MetricDataSource.allCases, id: \.self) { source in
                            Label(source.displayName, systemImage: source.iconName)
                                .tag(MetricDataSource?.some(source))
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("期間") {
                    DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                    DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                }
                
                Section {
                    Button("フィルターをリセット") {
                        selectedDataSource = nil
                        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                        endDate = Date()
                    }
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Metric Summary Card

struct MetricSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(Typography.captionMedium.font)
                    Spacer()
                }
                
                Text(value)
                    .font(Typography.headlineSmall.font)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColor.primaryText)
                
                HStack {
                    Text(title)
                        .font(Typography.captionSmall.font)
                        .foregroundColor(SemanticColor.secondaryText)
                    Spacer()
                    Text(subtitle)
                        .font(Typography.captionSmall.font)
                        .foregroundColor(color)
                }
            }
        }
        .frame(width: 90, height: 60)
    }
}