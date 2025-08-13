import SwiftUI
import SwiftData

struct WorkoutEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workoutRecord: WorkoutRecord
    
    @State private var workoutType: WorkoutType
    @State private var summary: String
    @State private var selectedDate: Date
    @State private var isCompleted: Bool
    
    // サイクリング詳細
    @State private var distance: Int = 0
    @State private var duration: Int = 0
    @State private var averagePower: Double = 0
    @State private var intensity: CyclingIntensity = .endurance
    
    // 筋トレ詳細
    @State private var strengthDetails: [StrengthDetailEdit] = []
    
    // 柔軟性詳細
    @State private var forwardBendDistance: Double = 0
    @State private var leftSplitAngle: Double = 0
    @State private var rightSplitAngle: Double = 0
    @State private var frontSplitAngle: Double = 0
    @State private var backSplitAngle: Double = 0
    
    @State private var showingDeleteAlert = false
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    init(workoutRecord: WorkoutRecord) {
        self.workoutRecord = workoutRecord
        
        // 初期値を設定
        self._workoutType = State(initialValue: workoutRecord.workoutType)
        self._summary = State(initialValue: workoutRecord.summary)
        self._selectedDate = State(initialValue: workoutRecord.date)
        self._isCompleted = State(initialValue: workoutRecord.isCompleted)
        
        // 詳細データの初期化
        if let cyclingDetail = workoutRecord.cyclingDetail {
            self._distance = State(initialValue: Int(cyclingDetail.distance))
            self._duration = State(initialValue: cyclingDetail.duration)
            self._averagePower = State(initialValue: cyclingDetail.averagePower)
            self._intensity = State(initialValue: cyclingDetail.intensity)
        }
        
        if let strengthDetails = workoutRecord.strengthDetails {
            self._strengthDetails = State(initialValue: strengthDetails.map { detail in
                StrengthDetailEdit(
                    exerciseName: detail.exercise,
                    weight: detail.weight,
                    sets: detail.sets,
                    reps: detail.reps
                )
            })
        }
        
        if let flexDetail = workoutRecord.flexibilityDetail {
            self._forwardBendDistance = State(initialValue: flexDetail.forwardBendDistance)
            self._leftSplitAngle = State(initialValue: flexDetail.leftSplitAngle)
            self._rightSplitAngle = State(initialValue: flexDetail.rightSplitAngle)
            self._frontSplitAngle = State(initialValue: flexDetail.frontSplitAngle)
            self._backSplitAngle = State(initialValue: flexDetail.backSplitAngle)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg.value) {
                    // Basic Information Card
                    BaseCard(style: ElevatedCardStyle()) {
                        VStack(spacing: Spacing.md.value) {
                            // Summary Input
                            TextInputRow(
                                label: "ワークアウト概要",
                                text: $summary,
                                placeholder: "例: 朝のライド、筋トレ、ヨガ"
                            )
                            
                            Divider()
                            
                            // Date Picker
                            HStack {
                                Text("記録日時")
                                    .font(Typography.bodyLarge.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                
                                Spacer()
                                
                                DatePicker(
                                    "",
                                    selection: $selectedDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .labelsHidden()
                                .font(Typography.bodyMedium.font)
                                .foregroundColor(SemanticColor.primaryText.color)
                            }
                            .frame(minHeight: 44)
                            
                            Divider()
                            
                            // Workout Type Picker
                            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                                Text("ワークアウト種目")
                                    .font(Typography.bodyLarge.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                
                                Picker("種目", selection: $workoutType) {
                                    ForEach(WorkoutType.allCases, id: \.self) { type in
                                        HStack {
                                            Image(systemName: type.iconName)
                                                .foregroundColor(type.iconColor)
                                            Text(type.rawValue)
                                        }
                                        .tag(type)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(minHeight: 44)
                            }
                            
                            Divider()
                            
                            // Completion Toggle
                            HStack {
                                Text("完了状態")
                                    .font(Typography.bodyLarge.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isCompleted)
                                    .labelsHidden()
                            }
                            .frame(minHeight: 44)
                        }
                        .padding(Spacing.md.value)
                    }
                    
                    // Workout Type Details Card
                    workoutDetailsCard
                    
                    // Delete Button Card
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
            .navigationTitle("ワークアウト編集")
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
            loadRecordData()
        }
        .alert("ワークアウト記録を削除", isPresented: $showingDeleteAlert) {
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
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var workoutDetailsCard: some View {
        switch workoutType {
        case .cycling:
            cyclingDetailsCard
        case .strength:
            strengthDetailsCard
        case .flexibility:
            flexibilityDetailsCard
        case .pilates, .yoga:
            generalWorkoutDetailsCard
        }
    }
    
    private var isValidInput: Bool {
        return !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedDate <= Date()
    }
    
    // MARK: - Detail Cards
    
    private var cyclingDetailsCard: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                Text("サイクリング詳細")
                    .font(Typography.headlineSmall.font)
                    .foregroundColor(SemanticColor.primaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                NumericInputRow(
                    label: "距離",
                    value: $distance,
                    unit: "km",
                    placeholder: "0"
                )
                
                Divider()
                
                NumericInputRow(
                    label: "時間",
                    value: $duration,
                    unit: "分",
                    placeholder: "0"
                )
                
                Divider()
                
                DecimalInputRow(
                    label: "平均パワー",
                    value: $averagePower,
                    unit: "W",
                    placeholder: "0"
                )
                
                Divider()
                
                // Intensity Picker
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    Text("強度")
                        .font(Typography.bodyLarge.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Picker("強度", selection: $intensity) {
                        ForEach(CyclingIntensity.allCases, id: \.self) { intensity in
                            Text(intensity.description).tag(intensity)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(minHeight: 44)
                }
            }
            .padding(Spacing.md.value)
        }
    }
    
    private var flexibilityDetailsCard: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                Text("柔軟性詳細")
                    .font(Typography.headlineSmall.font)
                    .foregroundColor(SemanticColor.primaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                DecimalInputRow(
                    label: "前屈",
                    value: $forwardBendDistance,
                    unit: "cm",
                    placeholder: "0.0"
                )
                
                Divider()
                
                DecimalInputRow(
                    label: "左開脚",
                    value: $leftSplitAngle,
                    unit: "°",
                    placeholder: "0.0"
                )
                
                Divider()
                
                DecimalInputRow(
                    label: "右開脚",
                    value: $rightSplitAngle,
                    unit: "°",
                    placeholder: "0.0"
                )
                
                Divider()
                
                DecimalInputRow(
                    label: "前後開脚（前）",
                    value: $frontSplitAngle,
                    unit: "°",
                    placeholder: "0.0"
                )
                
                Divider()
                
                DecimalInputRow(
                    label: "前後開脚（後）",
                    value: $backSplitAngle,
                    unit: "°",
                    placeholder: "0.0"
                )
            }
            .padding(Spacing.md.value)
        }
    }
    
    private var generalWorkoutDetailsCard: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                Text("\(workoutType.rawValue)詳細")
                    .font(Typography.headlineSmall.font)
                    .foregroundColor(SemanticColor.primaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("詳細設定機能は近日対応予定です")
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.lg.value)
            }
            .padding(Spacing.md.value)
        }
    }
    
    private var strengthDetailsCard: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                HStack {
                    Text("筋トレ詳細")
                        .font(Typography.headlineSmall.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                    
                    Button(action: {
                        strengthDetails.append(StrengthDetailEdit())
                        HapticManager.shared.trigger(.selection)
                    }) {
                        HStack(spacing: Spacing.xs.value) {
                            Image(systemName: "plus.circle.fill")
                            Text("追加")
                                .font(Typography.captionMedium.font)
                        }
                        .foregroundColor(SemanticColor.primaryAction.color)
                    }
                }
                
                if strengthDetails.isEmpty {
                    Text("エクササイズを追加して筋トレ詳細を記録しましょう")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Spacing.lg.value)
                } else {
                    ForEach(strengthDetails.indices, id: \.self) { index in
                        VStack(spacing: Spacing.sm.value) {
                            if index > 0 {
                                Divider()
                            }
                            
                            TextInputRow(
                                label: "エクササイズ名",
                                text: $strengthDetails[index].exerciseName,
                                placeholder: "例: ベンチプレス, スクワット"
                            )
                            
                            HStack(spacing: Spacing.md.value) {
                                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                                    Text("重量")
                                        .font(Typography.captionMedium.font)
                                        .foregroundColor(SemanticColor.secondaryText.color)
                                    
                                    HStack {
                                        TextField("0", value: $strengthDetails[index].weight, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .font(Typography.bodyMedium.font)
                                            .padding(.horizontal, Spacing.sm.value)
                                            .padding(.vertical, Spacing.xs.value)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(SemanticColor.surfaceBackground.color)
                                                    .stroke(SemanticColor.primaryBorder.color, lineWidth: 1)
                                            )
                                        
                                        Text("kg")
                                            .font(Typography.captionMedium.font)
                                            .foregroundColor(SemanticColor.secondaryText.color)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                                    Text("セット")
                                        .font(Typography.captionMedium.font)
                                        .foregroundColor(SemanticColor.secondaryText.color)
                                    
                                    TextField("0", value: $strengthDetails[index].sets, format: .number)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(Typography.bodyMedium.font)
                                        .padding(.horizontal, Spacing.sm.value)
                                        .padding(.vertical, Spacing.xs.value)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(SemanticColor.surfaceBackground.color)
                                                .stroke(SemanticColor.primaryBorder.color, lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                                    Text("レップ")
                                        .font(Typography.captionMedium.font)
                                        .foregroundColor(SemanticColor.secondaryText.color)
                                    
                                    TextField("0", value: $strengthDetails[index].reps, format: .number)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(Typography.bodyMedium.font)
                                        .padding(.horizontal, Spacing.sm.value)
                                        .padding(.vertical, Spacing.xs.value)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(SemanticColor.surfaceBackground.color)
                                                .stroke(SemanticColor.primaryBorder.color, lineWidth: 1)
                                        )
                                }
                                
                                Button(action: {
                                    strengthDetails.remove(at: index)
                                    HapticManager.shared.trigger(.selection)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(SemanticColor.destructiveAction.color)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Spacing.md.value)
        }
    }
    
    
    // MARK: - Methods
    
    private func loadRecordData() {
        // Data is already loaded in init, but this can be used for refresh if needed
    }
    
    private func saveChanges() {
        guard isValidInput else {
            validationMessage = "概要を入力し、記録日時は今日以前を選択してください。"
            showingValidationError = true
            return
        }
        
        // Update the record directly
        workoutRecord.summary = summary
        workoutRecord.workoutType = workoutType
        workoutRecord.date = selectedDate
        workoutRecord.isCompleted = isCompleted
        
        // Update detail data based on workout type
        updateWorkoutDetails()
        
        do {
            try modelContext.save()
            
            // Trigger TaskCounter update if completed
            if isCompleted {
                Task { @MainActor in
                    TaskCounterService.shared.incrementCounter(for: workoutRecord, in: modelContext)
                }
            }
            
            HapticManager.shared.trigger(.notification(.success))
            dismiss()
        } catch {
            validationMessage = "保存中にエラーが発生しました: \(error.localizedDescription)"
            showingValidationError = true
        }
    }
    
    private func updateWorkoutDetails() {
        switch workoutType {
        case .cycling:
            if distance > 0 || duration > 0 || averagePower > 0 {
                workoutRecord.cyclingDetail = CyclingDetail(
                    distance: Double(distance),
                    duration: duration,
                    averagePower: averagePower,
                    intensity: intensity
                )
            } else {
                workoutRecord.cyclingDetail = nil
            }
            
        case .strength:
            if !strengthDetails.isEmpty {
                workoutRecord.strengthDetails = strengthDetails
                    .filter { !$0.exerciseName.isEmpty }
                    .map { detail in
                        StrengthDetail(
                            exercise: detail.exerciseName,
                            sets: detail.sets,
                            reps: detail.reps,
                            weight: detail.weight
                        )
                    }
            } else {
                workoutRecord.strengthDetails = nil
            }
            
        case .flexibility:
            if forwardBendDistance > 0 || leftSplitAngle > 0 || rightSplitAngle > 0 || frontSplitAngle > 0 || backSplitAngle > 0 {
                workoutRecord.flexibilityDetail = FlexibilityDetail(
                    forwardBendDistance: forwardBendDistance,
                    leftSplitAngle: leftSplitAngle,
                    rightSplitAngle: rightSplitAngle,
                    frontSplitAngle: frontSplitAngle,
                    backSplitAngle: backSplitAngle
                )
            } else {
                workoutRecord.flexibilityDetail = nil
            }
            
        case .pilates, .yoga:
            // Details will be implemented later
            break
        }
    }
    
    private func deleteRecord() {
        withAnimation {
            modelContext.delete(workoutRecord)
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

// 編集用の筋トレ詳細データ構造
struct StrengthDetailEdit {
    var exerciseName: String = ""
    var weight: Double = 0
    var sets: Int = 0
    var reps: Int = 0
}

#Preview {
    NavigationStack {
        WorkoutEditSheet(workoutRecord: {
            let workout = WorkoutRecord(
                date: Date(),
                workoutType: .cycling,
                summary: "朝のライド"
            )
            workout.cyclingDetail = CyclingDetail(
                distance: 30,
                duration: 60,
                averagePower: 200,
                intensity: .endurance
            )
            return workout
        }())
    }
    .modelContainer(for: [WorkoutRecord.self])
}