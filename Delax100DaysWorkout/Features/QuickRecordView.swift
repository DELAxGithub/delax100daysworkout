import SwiftUI
import SwiftData
import OSLog

struct QuickRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Optional parameters for task association
    var selectedDay: Int?
    var dayTasks: [DailyTask]
    var scheduleViewModel: WeeklyScheduleViewModel?
    
    @State private var selectedType: WorkoutType = .cycling
    @State private var showSuccessAnimation = false
    
    init(selectedDay: Int? = nil, dayTasks: [DailyTask] = [], scheduleViewModel: WeeklyScheduleViewModel? = nil) {
        self.selectedDay = selectedDay
        self.dayTasks = dayTasks
        self.scheduleViewModel = scheduleViewModel
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("トレーニング記録")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("種目を選んで詳細を入力してください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Type selector - simplified
                Picker("種目", selection: $selectedType) {
                    Text("サイクリング").tag(WorkoutType.cycling)
                    Text("筋トレ").tag(WorkoutType.strength)
                    Text("柔軟性").tag(WorkoutType.flexibility)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Type-specific input form
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedType {
                        case .cycling:
                            SimpleCyclingInputView { data in
                                saveRecord(with: data)
                            }
                        case .strength:
                            SimpleStrengthInputView { data in
                                saveRecord(with: data)
                            }
                        case .flexibility, .pilates, .yoga:
                            SimpleFlexibilityInputView { data in
                                saveRecord(with: data)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showSuccessAnimation {
                    successOverlay
                }
            }
        }
    }
    
    private var successOverlay: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .transition(.scale.combined(with: .opacity))
            
            Text("記録完了！")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 8)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func saveRecord(with data: Any) {
        // WeeklyScheduleViewModelがあり、selectedDayが指定されている場合は、そちらを使用
        if let viewModel = scheduleViewModel, let day = selectedDay {
            let result = viewModel.createQuickRecordWithTask(
                workoutType: selectedType,
                selectedDay: day,
                recordData: data
            )
            
            if result.task != nil && result.record != nil {
                showSuccessAnimation = true
                
                // スケジュールビューの状態を更新
                viewModel.refreshAfterQuickRecord()
                
                // Dismiss after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            } else {
                Logger.error.error("Error creating quick record with task")
            }
        } else {
            // 従来の方法でレコードを作成（後方互換性のため）
            saveLegacyRecord(with: data)
        }
    }
    
    /// 従来の方法でレコードを保存（後方互換性のため）
    private func saveLegacyRecord(with data: Any) {
        let record = WorkoutRecord(
            date: Date(),
            workoutType: selectedType,
            summary: "\(selectedType.rawValue) - Quick Record",
            isQuickRecord: true
        )
        
        // Set appropriate data based on type
        switch selectedType {
        case .cycling:
            if let cyclingData = data as? SimpleCyclingData {
                record.cyclingData = cyclingData
            }
        case .strength:
            if let strengthData = data as? SimpleStrengthData {
                record.strengthData = strengthData
            }
        case .flexibility, .pilates, .yoga:
            if let flexibilityData = data as? SimpleFlexibilityData {
                record.flexibilityData = flexibilityData
            }
        }
        
        // Associate with template task if available
        if let matchingTask = findMatchingTask(for: selectedType) {
            record.templateTask = matchingTask
        }
        
        // Mark as completed since it's a quick record entry
        record.markAsCompleted()
        
        modelContext.insert(record)
        
        do {
            try modelContext.save()
            showSuccessAnimation = true
            
            // Dismiss after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
            
        } catch {
            Logger.error.error("Error saving record: \(error.localizedDescription)")
        }
    }
    
    private func findMatchingTask(for workoutType: WorkoutType) -> DailyTask? {
        // Find a matching task in the day's tasks that matches the workout type
        return dayTasks.first { task in
            task.workoutType == workoutType
        }
    }
}

// MARK: - Input Views

struct SimpleCyclingInputView: View {
    @State private var selectedZone: CyclingZone = .z2
    @State private var duration: Int = 90  // Z2のdefaultDurationと一致させる
    @State private var power: Int = 0
    @State private var averageHeartRate: Int = 0
    
    // プリセット管理とピッカー範囲
    private let presetManager = CyclingPresetManager.shared
    @State private var powerPickerRange: [Int] = []
    @State private var heartRatePickerRange: [Int] = []
    
    let onSave: (SimpleCyclingData) -> Void
    
    // ワットパー心拍の計算
    private var wattsPerBpm: Double? {
        guard power > 0 && averageHeartRate > 0 else { return nil }
        return Double(power) / Double(averageHeartRate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("サイクリング詳細", systemImage: "bicycle")
                .font(.headline)
                .foregroundStyle(.blue)
            
            VStack(spacing: 16) {
                // Zone picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("ゾーン")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("ゾーン", selection: $selectedZone) {
                        ForEach(CyclingZone.allCases, id: \.self) { zone in
                            Text(zone.displayName).tag(zone)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("時間")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Slider(value: Binding(
                            get: { Double(duration) },
                            set: { duration = Int($0) }
                        ), in: 15...180, step: 15)
                        
                        Text("\(duration)分")
                            .font(.subheadline)
                            .frame(width: 50)
                    }
                }
                
                // Power - ドラム式ピッカー（前回値±10W）
                VStack(alignment: .leading, spacing: 8) {
                    Text("パワー")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Picker("パワー", selection: $power) {
                                ForEach(powerPickerRange, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            
                            Text("W")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("前回: \(presetManager.getPowerPreset(for: selectedZone))W")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("0-300W全範囲")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Heart Rate - ドラム式ピッカー（前回値±10bpm）
                VStack(alignment: .leading, spacing: 8) {
                    Text("平均心拍数")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Picker("心拍数", selection: $averageHeartRate) {
                                ForEach(heartRatePickerRange, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            
                            Text("bpm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("前回: \(presetManager.getHeartRatePreset(for: selectedZone))bpm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("100-200bpm全範囲")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Watts per BPM display
                if let wattsPerBpm = wattsPerBpm {
                    HStack {
                        Image(systemName: "bolt.heart")
                            .foregroundColor(.orange)
                        Text("ワットパー心拍: \(String(format: "%.2f", wattsPerBpm)) W/bpm")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {
                // プリセット値を更新
                presetManager.savePresets(
                    zone: selectedZone,
                    power: power > 0 ? power : nil,
                    heartRate: averageHeartRate > 0 ? averageHeartRate : nil
                )
                
                let data = SimpleCyclingData(
                    zone: selectedZone,
                    duration: duration,
                    power: power > 0 ? power : nil,
                    averageHeartRate: averageHeartRate > 0 ? averageHeartRate : nil
                )
                onSave(data)
            }) {
                Text("記録する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .cornerRadius(12)
            }
        }
        .onAppear {
            loadPresetForZone(selectedZone)
        }
        .onChange(of: selectedZone) { _, newZone in
            loadPresetForZone(newZone)
        }
    }
    
    /// ゾーンのプリセット値を読み込む
    private func loadPresetForZone(_ zone: CyclingZone) {
        duration = zone.defaultDuration
        
        // プリセット値を読み込み
        power = presetManager.getPowerPreset(for: zone)
        averageHeartRate = presetManager.getHeartRatePreset(for: zone)
        
        // ピッカー範囲を更新
        powerPickerRange = presetManager.getPowerPickerRange(for: zone)
        heartRatePickerRange = presetManager.getHeartRatePickerRange(for: zone)
    }
}

struct SimpleStrengthInputView: View {
    @State private var selectedMuscleGroup: WorkoutMuscleGroup = .chest
    @State private var customName: String = ""
    @State private var weight: Int = 20  // 整数のみ、初期値20kg
    @State private var reps: Int = 10
    @State private var sets: Int = 3
    
    private let presetManager = StrengthPresetManager.shared
    
    let onSave: (SimpleStrengthData) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("筋トレ詳細", systemImage: "dumbbell")
                .font(.headline)
                .foregroundStyle(.orange)
            
            VStack(spacing: 16) {
                // Muscle group picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("部位")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("部位", selection: $selectedMuscleGroup) {
                        ForEach(WorkoutMuscleGroup.allCases, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                
                // Custom name for "その他"
                if selectedMuscleGroup == .custom {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("種目名")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("例：ベンチプレス", text: $customName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Weight, sets, reps - ドラム式ピッカー
                HStack(spacing: 8) {
                    // 重量ピッカー
                    VStack(spacing: 4) {
                        Text("重量")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(spacing: 2) {
                            Picker("重量", selection: $weight) {
                                ForEach(0...200, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            
                            Text("kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(presetManager.getPresetDisplayString(for: selectedMuscleGroup))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // セットピッカー
                    VStack(spacing: 4) {
                        Text("セット")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(spacing: 2) {
                            Picker("セット", selection: $sets) {
                                ForEach(1...10, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            
                            Text("回")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // レップピッカー
                    VStack(spacing: 4) {
                        Text("レップ")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(spacing: 2) {
                            Picker("レップ", selection: $reps) {
                                ForEach(1...50, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            
                            Text("回")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {
                // プリセット値を更新
                presetManager.savePresets(
                    muscleGroup: selectedMuscleGroup,
                    weight: Double(weight),
                    sets: sets,
                    reps: reps
                )
                
                let data = SimpleStrengthData(
                    muscleGroup: selectedMuscleGroup,
                    customName: selectedMuscleGroup == .custom ? customName : nil,
                    weight: Double(weight),
                    reps: reps,
                    sets: sets
                )
                onSave(data)
            }) {
                Text("記録する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(weight > 0 && sets > 0 && reps > 0 ? .orange : .gray)
                    .cornerRadius(12)
            }
            .disabled(weight <= 0 || sets <= 0 || reps <= 0)
        }
        .onAppear {
            loadPresetForMuscleGroup(selectedMuscleGroup)
        }
        .onChange(of: selectedMuscleGroup) { _, newGroup in
            loadPresetForMuscleGroup(newGroup)
        }
    }
    
    /// 部位のプリセット値を読み込む
    private func loadPresetForMuscleGroup(_ muscleGroup: WorkoutMuscleGroup) {
        // プリセット値を読み込み
        weight = Int(presetManager.getWeightPreset(for: muscleGroup))
        sets = presetManager.getSetsPreset(for: muscleGroup)
        reps = presetManager.getRepsPreset(for: muscleGroup)
    }
}

struct SimpleFlexibilityInputView: View {
    @State private var selectedType: FlexibilityType = .general
    @State private var duration: Int = 30
    @State private var measurement: Double = 0
    
    private let presetManager = FlexibilityPresetManager.shared
    
    let onSave: (SimpleFlexibilityData) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("柔軟性詳細", systemImage: "figure.flexibility")
                .font(.headline)
                .foregroundStyle(.green)
            
            VStack(spacing: 16) {
                // Type picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("種類")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("種類", selection: $selectedType) {
                        ForEach(FlexibilityType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("時間")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Slider(value: Binding(
                                get: { Double(duration) },
                                set: { duration = Int($0) }
                            ), in: 5...60, step: 5)
                            
                            Text("\(duration)分")
                                .font(.subheadline)
                                .frame(width: 50)
                        }
                        
                        HStack {
                            Text(presetManager.getPresetDisplayString(for: selectedType))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                
                // Measurement (for forward bend and split)
                if selectedType.hasMeasurement {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedType == .forwardBend ? "測定値" : "角度")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(spacing: 8) {
                            HStack {
                                TextField("0", value: $measurement, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                Text(selectedType == .forwardBend ? "cm" : "°")
                            }
                            
                            if selectedType.hasMeasurement {
                                HStack {
                                    Text("前回: \(Int(presetManager.getMeasurementPreset(for: selectedType)))\(selectedType == .forwardBend ? "cm" : "°")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {
                // プリセット値を更新
                presetManager.savePresets(
                    type: selectedType,
                    duration: duration,
                    measurement: selectedType.hasMeasurement ? measurement : nil
                )
                
                let data = SimpleFlexibilityData(
                    type: selectedType,
                    duration: duration,
                    measurement: selectedType.hasMeasurement ? measurement : nil
                )
                onSave(data)
            }) {
                Text("記録する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .cornerRadius(12)
            }
        }
        .onAppear {
            loadPresetForType(selectedType)
        }
        .onChange(of: selectedType) { _, newType in
            loadPresetForType(newType)
        }
    }
    
    /// 種類のプリセット値を読み込む
    private func loadPresetForType(_ type: FlexibilityType) {
        // プリセット値を読み込み
        duration = presetManager.getDurationPreset(for: type)
        measurement = presetManager.getMeasurementPreset(for: type)
    }
}

#Preview {
    QuickRecordView()
        .modelContainer(for: WorkoutRecord.self, inMemory: true)
}