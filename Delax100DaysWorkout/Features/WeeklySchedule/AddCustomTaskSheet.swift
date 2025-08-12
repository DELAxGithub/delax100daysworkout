import SwiftUI
import SwiftData

struct AddCustomTaskSheet: View {
    let selectedDay: Int
    let onSave: (DailyTask) -> Void
    let onCancel: () -> Void
    
    @State private var workoutType: WorkoutType = .cycling
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var isFlexible: Bool = false
    
    // サイクリング詳細
    @State private var duration: Int = 60
    @State private var intensity: CyclingIntensity = .endurance
    @State private var targetPower: Int = 200
    
    // 筋トレ詳細
    @State private var exercises: [String] = [""]
    @State private var targetSets: Int = 3
    @State private var targetReps: Int = 10
    
    // 柔軟性詳細
    @State private var targetDuration: Int = 20
    @State private var targetForwardBend: Double = 0
    @State private var targetSplitAngle: Double = 120
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let dayNames = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    HStack {
                        Text("曜日")
                        Spacer()
                        Text("\(dayNames[selectedDay])曜日")
                            .foregroundColor(.secondary)
                    }
                    
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
                    
                    TextField("タイトル", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("説明（任意）", text: $taskDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                    
                    Toggle("フレキシブルタスク", isOn: $isFlexible)
                        .help("パフォーマンスに応じて目標が自動調整されます")
                }
                
                // 種目別詳細セクション
                switch workoutType {
                case .cycling:
                    cyclingDetailsSection
                case .strength:
                    strengthDetailsSection
                case .flexibility:
                    flexibilityDetailsSection
                }
            }
            .navigationTitle("カスタムタスク追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("入力エラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            setDefaultValues()
        }
    }
    
    private var cyclingDetailsSection: some View {
        Section("サイクリング詳細") {
            HStack {
                Text("時間")
                Spacer()
                TextField("分", value: $duration, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Text("分")
                    .foregroundColor(.secondary)
            }
            
            Picker("強度", selection: $intensity) {
                ForEach(CyclingIntensity.allCases, id: \.self) { intensity in
                    Text(intensity.displayName).tag(intensity)
                }
            }
            
            HStack {
                Text("目標パワー")
                Spacer()
                TextField("W", value: $targetPower, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Text("W")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var strengthDetailsSection: some View {
        Section("筋トレ詳細") {
            ForEach(exercises.indices, id: \.self) { index in
                TextField("エクササイズ \(index + 1)", text: $exercises[index])
                    .textFieldStyle(.roundedBorder)
            }
            .onDelete(perform: deleteExercise)
            
            Button("エクササイズを追加") {
                exercises.append("")
            }
            .foregroundColor(.blue)
            
            HStack {
                Text("目標セット")
                Spacer()
                TextField("回", value: $targetSets, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Text("セット")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("目標レップ")
                Spacer()
                TextField("回", value: $targetReps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Text("回")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var flexibilityDetailsSection: some View {
        Section("柔軟性詳細") {
            HStack {
                Text("時間")
                Spacer()
                TextField("分", value: $targetDuration, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Text("分")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("目標前屈")
                Spacer()
                TextField("cm", value: $targetForwardBend, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Text("cm")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("目標開脚")
                Spacer()
                TextField("度", value: $targetSplitAngle, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Text("°")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func setDefaultValues() {
        switch workoutType {
        case .cycling:
            if title.isEmpty {
                title = getDefaultTitle(for: workoutType)
            }
        case .strength:
            if title.isEmpty {
                title = getDefaultTitle(for: workoutType)
            }
            if exercises.isEmpty || exercises == [""] {
                exercises = [""]
            }
        case .flexibility:
            if title.isEmpty {
                title = getDefaultTitle(for: workoutType)
            }
        }
    }
    
    private func getDefaultTitle(for type: WorkoutType) -> String {
        switch type {
        case .cycling:
            return "カスタムライド"
        case .strength:
            return "カスタム筋トレ"
        case .flexibility:
            return "カスタム柔軟"
        }
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        if exercises.isEmpty {
            exercises.append("")
        }
    }
    
    private func saveTask() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "タイトルを入力してください"
            showingAlert = true
            return
        }
        
        var targetDetails: TargetDetails?
        
        switch workoutType {
        case .cycling:
            if duration > 0 {
                targetDetails = TargetDetails(
                    duration: duration,
                    intensity: intensity,
                    targetPower: targetPower > 0 ? targetPower : nil
                )
            }
            
        case .strength:
            let validExercises = exercises.compactMap { exercise in
                let trimmed = exercise.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            
            if !validExercises.isEmpty {
                targetDetails = TargetDetails(
                    exercises: validExercises,
                    targetSets: targetSets > 0 ? targetSets : 3,
                    targetReps: targetReps > 0 ? targetReps : 10
                )
            }
            
        case .flexibility:
            if targetDuration > 0 {
                targetDetails = TargetDetails(
                    targetDuration: targetDuration,
                    targetForwardBend: targetForwardBend > 0 ? targetForwardBend : nil,
                    targetSplitAngle: targetSplitAngle > 0 ? targetSplitAngle : nil
                )
            }
        }
        
        let task = DailyTask(
            dayOfWeek: selectedDay,
            workoutType: workoutType,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            targetDetails: targetDetails,
            isFlexible: isFlexible
        )
        
        onSave(task)
    }
}

#Preview {
    AddCustomTaskSheet(
        selectedDay: 2,
        onSave: { _ in },
        onCancel: { }
    )
}