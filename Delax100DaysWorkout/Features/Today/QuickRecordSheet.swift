import SwiftUI
import OSLog
import SwiftData

struct QuickRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let task: DailyTask
    let workoutRecord: WorkoutRecord
    @State private var notes: String = ""
    @State private var showSuccessAnimation = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Simplified inputs
    @State private var selectedZone: CyclingZone = .z2
    @State private var duration: Int = 60
    @State private var power: Int = 0
    @State private var selectedMuscleGroup: WorkoutMuscleGroup = .chest
    @State private var customName: String = ""
    @State private var weight: Double = 0
    @State private var reps: Int = 10
    @State private var sets: Int = 3
    @State private var selectedFlexType: FlexibilityType = .general
    @State private var flexDuration: Int = 30
    @State private var measurement: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Success animation
                    if showSuccessAnimation {
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
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Task info
                            VStack(alignment: .leading, spacing: 8) {
                                Text(task.title)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                if let description = task.taskDescription {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            Divider()
                            
                            // Type-specific input
                            Group {
                                switch task.workoutType {
                                case .cycling:
                                    cyclingInputSection
                                case .strength:
                                    strengthInputSection
                                case .flexibility, .pilates, .yoga:
                                    flexibilityInputSection
                                }
                            }
                            .padding(.horizontal)
                            
                            // Notes section
                            VStack(alignment: .leading, spacing: 8) {
                                Label("メモ", systemImage: "note.text")
                                    .font(.headline)
                                
                                TextEditor(text: $notes)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            
                            // Quick phrases
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(quickPhrases, id: \.self) { phrase in
                                        Button(action: {
                                            if !notes.isEmpty {
                                                notes += "\n"
                                            }
                                            notes += phrase
                                        }) {
                                            Text(phrase)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(15)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
                
                // Toast notification
                if showToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(toastMessage)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(25)
                        .shadow(radius: 4)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(), value: showToast)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("詳細を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("スキップ") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveDetails()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    // MARK: - Input Sections
    
    private var cyclingInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("サイクリング詳細", systemImage: "bicycle")
                .font(.headline)
                .foregroundStyle(.blue)
            
            VStack(spacing: 12) {
                // Zone selection (simplified)
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
                
                // Power (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("パワー（オプション）")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        TextField("0", value: $power, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        Text("W")
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var strengthInputSection: some View {
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
                    .frame(height: 100)
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
                
                // Weight, sets, reps
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("重量")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        HStack {
                            TextField("0", value: $weight, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            Text("kg")
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("セット")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("3", value: $sets, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("レップ")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("10", value: $reps, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var flexibilityInputSection: some View {
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
                    
                    Picker("種類", selection: $selectedFlexType) {
                        ForEach(FlexibilityType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("時間")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Slider(value: Binding(
                            get: { Double(flexDuration) },
                            set: { flexDuration = Int($0) }
                        ), in: 5...60, step: 5)
                        
                        Text("\(flexDuration)分")
                            .font(.subheadline)
                            .frame(width: 50)
                    }
                }
                
                // Measurement (for forward bend and split)
                if selectedFlexType.hasMeasurement {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedFlexType == .forwardBend ? "測定値" : "角度")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            TextField("0", value: $measurement, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            Text(selectedFlexType == .forwardBend ? "cm" : "°")
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    
    // MARK: - Helper Methods
    
    private var quickPhrases: [String] {
        switch task.workoutType {
        case .cycling:
            return ["調子良かった", "向かい風が強かった", "疲れていた", "ペース配分を意識した"]
        case .strength:
            return ["フォームを意識した", "限界まで追い込んだ", "軽めに調整した", "新記録！"]
        case .flexibility, .pilates, .yoga:
            return ["体が硬かった", "少し改善した", "痛みがあった", "調子良かった"]
        }
    }
    
    private func setupInitialValues() {
        switch task.workoutType {
        case .cycling:
            if let existingData = workoutRecord.cyclingData {
                selectedZone = existingData.zone
                duration = existingData.duration
                power = existingData.power ?? 0
            } else {
                duration = selectedZone.defaultDuration
            }
            
        case .strength:
            if let existingData = workoutRecord.strengthData {
                selectedMuscleGroup = existingData.muscleGroup
                customName = existingData.customName ?? ""
                weight = existingData.weight
                sets = existingData.sets
                reps = existingData.reps
            } else if let target = task.targetDetails {
                sets = target.targetSets ?? 3
                reps = target.targetReps ?? 10
            }
            
        case .flexibility, .pilates, .yoga:
            if let existingData = workoutRecord.flexibilityData {
                selectedFlexType = existingData.type
                flexDuration = existingData.duration
                measurement = existingData.measurement ?? 0
            } else {
                flexDuration = 30
            }
        }
    }
    
    private func saveDetails() {
        let noteText = notes.isEmpty ? nil : notes
        
        // Create simple data based on workout type
        switch task.workoutType {
        case .cycling:
            let cyclingData = SimpleCyclingData(
                zone: selectedZone,
                duration: duration,
                power: power > 0 ? power : nil
            )
            workoutRecord.cyclingData = cyclingData
            
        case .strength:
            let strengthData = SimpleStrengthData(
                muscleGroup: selectedMuscleGroup,
                customName: selectedMuscleGroup == .custom ? customName : nil,
                weight: weight,
                reps: reps,
                sets: sets
            )
            workoutRecord.strengthData = strengthData
            
        case .flexibility, .pilates, .yoga:
            let flexibilityData = SimpleFlexibilityData(
                type: selectedFlexType,
                duration: flexDuration,
                measurement: selectedFlexType.hasMeasurement ? measurement : nil
            )
            workoutRecord.flexibilityData = flexibilityData
        }
        
        // Add notes to summary if provided
        if let note = noteText {
            workoutRecord.summary = "\(workoutRecord.summary)\n\(note)"
        }
        
        do {
            try modelContext.save()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Show success animation
            withAnimation(.spring()) {
                showSuccessAnimation = true
                toastMessage = "保存しました！"
                showToast = true
            }
            
            // Hide toast after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showToast = false
                }
            }
            
            // Dismiss sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
            
        } catch {
            Logger.error.error("Error saving details: \(error.localizedDescription)")
            
            // Error feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            
            withAnimation {
                toastMessage = "保存に失敗しました"
                showToast = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showToast = false
                }
            }
        }
    }
}

// Helper struct for strength exercise input
private struct StrengthExerciseInput {
    var name: String
    var weight: Double
    var sets: Int
    var reps: Int
}