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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let metric: DailyMetric
    
    @State private var weightValue: Double = 0.0
    @State private var restingHRValue: Int = 0
    @State private var maxHRValue: Int = 0
    @State private var selectedDate: Date = Date()
    @State private var selectedDataSource: MetricDataSource = .manual
    @State private var showingDeleteAlert = false
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg.value) {
                    // Edit Form
                    BaseCard(style: ElevatedCardStyle()) {
                        VStack(spacing: Spacing.md.value) {
                            // Weight Input
                            DecimalInputRow(
                                label: "体重",
                                value: $weightValue,
                                unit: "kg",
                                placeholder: "70.0"
                            )
                            
                            Divider()
                            
                            // Resting Heart Rate Input
                            NumericInputRow(
                                label: "安静時心拍数",
                                value: $restingHRValue,
                                unit: "bpm",
                                placeholder: "50"
                            )
                            
                            Divider()
                            
                            // Max Heart Rate Input
                            NumericInputRow(
                                label: "最大心拍数",
                                value: $maxHRValue,
                                unit: "bpm",
                                placeholder: "180"
                            )
                            
                            Divider()
                            
                            // Date Picker
                            DatePicker(
                                "記録日",
                                selection: $selectedDate,
                                displayedComponents: .date
                            )
                            .font(Typography.bodyLarge.font)
                            .foregroundColor(SemanticColor.primaryText.color)
                            .frame(minHeight: 44)
                            
                            Divider()
                            
                            // Data Source Picker
                            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                                Text("データソース")
                                    .font(Typography.bodyLarge.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                
                                Picker("データソース", selection: $selectedDataSource) {
                                    ForEach(MetricDataSource.allCases, id: \.self) { source in
                                        Label(source.displayName, systemImage: source.iconName)
                                            .tag(source)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(minHeight: 44)
                            }
                        }
                        .padding(Spacing.md.value)
                    }
                    
                    // Helper Text Card
                    BaseCard(style: OutlinedCardStyle()) {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            Text("編集のヒント")
                                .font(Typography.labelMedium.font)
                                .foregroundColor(SemanticColor.primaryText.color)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                                Text("• 値を0にすると該当データが削除されます")
                                Text("• 体重: 30.0 - 200.0 kg")
                                Text("• 安静時心拍数: 40 - 100 bpm")
                                Text("• 最大心拍数: 120 - 220 bpm")
                            }
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                        }
                        .padding(Spacing.md.value)
                    }
                    
                    // Delete Button
                    BaseCard(style: OutlinedCardStyle()) {
                        Button(action: {
                            showingDeleteAlert = true
                            HapticManager.shared.trigger(.notification(.warning))
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(SemanticColor.destructiveAction.color)
                                Text("この記録を削除")
                                    .font(Typography.labelMedium.font)
                                    .foregroundColor(SemanticColor.destructiveAction.color)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md.value)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(SemanticColor.primaryBackground.color)
            .navigationTitle("メトリクス編集")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                        HapticManager.shared.trigger(.selection)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                }
            }
        }
        .onAppear {
            loadMetricData()
        }
        .alert("メトリクス記録を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteRecord()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この記録を削除してもよろしいですか？この操作は取り消せません。")
        }
        .alert("入力エラー", isPresented: $showingValidationError) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
    }
    
    private var isValidInput: Bool {
        let hasValidWeight = weightValue <= 0 || DailyMetric.isValidWeight(weightValue)
        let hasValidRestingHR = restingHRValue <= 0 || DailyMetric.isValidRestingHeartRate(restingHRValue)
        let hasValidMaxHR = maxHRValue <= 0 || DailyMetric.isValidMaxHeartRate(maxHRValue)
        let hasValidDate = selectedDate <= Date()
        let hasAnyData = weightValue > 0 || restingHRValue > 0 || maxHRValue > 0
        
        return hasValidWeight && hasValidRestingHR && hasValidMaxHR && hasValidDate && hasAnyData
    }
    
    private func loadMetricData() {
        weightValue = metric.weightKg ?? 0.0
        restingHRValue = metric.restingHeartRate ?? 0
        maxHRValue = metric.maxHeartRate ?? 0
        selectedDate = metric.date
        selectedDataSource = metric.dataSource
    }
    
    private func saveChanges() {
        guard isValidInput else {
            validationMessage = "入力値を確認してください。有効な範囲内で入力し、記録日は今日以前を選択してください。"
            showingValidationError = true
            return
        }
        
        // Update the record
        metric.weightKg = weightValue > 0 ? weightValue : nil
        metric.restingHeartRate = restingHRValue > 0 ? restingHRValue : nil
        metric.maxHeartRate = maxHRValue > 0 ? maxHRValue : nil
        metric.date = selectedDate
        metric.dataSource = selectedDataSource
        metric.updatedAt = Date()
        
        do {
            try modelContext.save()
            
            // Trigger WPR update if weight was updated
            if let newWeight = metric.weightKg {
                Task { @MainActor in
                    metric.triggerWPRWeightUpdate(context: modelContext)
                }
            }
            
            HapticManager.shared.trigger(.notification(.success))
            dismiss()
        } catch {
            validationMessage = "保存中にエラーが発生しました: \(error.localizedDescription)"
            showingValidationError = true
        }
    }
    
    private func deleteRecord() {
        withAnimation {
            modelContext.delete(metric)
            do {
                try modelContext.save()
                HapticManager.shared.trigger(.notification(.success))
                dismiss()
            } catch {
                validationMessage = "削除中にエラーが発生しました: \(error.localizedDescription)"
                showingValidationError = true
            }
        }
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