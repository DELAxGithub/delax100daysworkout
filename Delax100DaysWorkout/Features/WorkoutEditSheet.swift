import SwiftUI
import SwiftData

struct WorkoutEditSheet: View {
    let workout: WorkoutRecord
    let onSave: (WorkoutRecord) -> Void
    let onCancel: () -> Void
    
    @State private var workoutType: WorkoutType
    @State private var summary: String
    @State private var date: Date
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
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(workout: WorkoutRecord, onSave: @escaping (WorkoutRecord) -> Void, onCancel: @escaping () -> Void) {
        self.workout = workout
        self.onSave = onSave
        self.onCancel = onCancel
        
        // 初期値を設定
        self._workoutType = State(initialValue: workout.workoutType)
        self._summary = State(initialValue: workout.summary)
        self._date = State(initialValue: workout.date)
        self._isCompleted = State(initialValue: workout.isCompleted)
        
        // 詳細データの初期化
        if let cyclingDetail = workout.cyclingDetail {
            self._distance = State(initialValue: Int(cyclingDetail.distance))
            self._duration = State(initialValue: cyclingDetail.duration)
            self._averagePower = State(initialValue: cyclingDetail.averagePower)
            self._intensity = State(initialValue: cyclingDetail.intensity)
        }
        
        if let strengthDetails = workout.strengthDetails {
            self._strengthDetails = State(initialValue: strengthDetails.map { detail in
                StrengthDetailEdit(
                    exerciseName: detail.exercise,
                    weight: detail.weight,
                    sets: detail.sets,
                    reps: detail.reps
                )
            })
        }
        
        if let flexDetail = workout.flexibilityDetail {
            self._forwardBendDistance = State(initialValue: flexDetail.forwardBendDistance)
            self._leftSplitAngle = State(initialValue: flexDetail.leftSplitAngle)
            self._rightSplitAngle = State(initialValue: flexDetail.rightSplitAngle)
            self._frontSplitAngle = State(initialValue: flexDetail.frontSplitAngle)
            self._backSplitAngle = State(initialValue: flexDetail.backSplitAngle)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
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
                    
                    TextField("サマリー", text: $summary)
                    
                    DatePicker("日時", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("完了済み", isOn: $isCompleted)
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
            .navigationTitle("ワークアウト編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWorkout()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("入力エラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var cyclingDetailsSection: some View {
        Section("サイクリング詳細") {
            HStack {
                Text("距離")
                Spacer()
                TextField("km", value: $distance, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("km")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("時間")
                Spacer()
                TextField("分", value: $duration, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("分")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("平均パワー")
                Spacer()
                TextField("W", value: $averagePower, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("W")
                    .foregroundColor(.secondary)
            }
            
            Picker("強度", selection: $intensity) {
                ForEach(CyclingIntensity.allCases, id: \.self) { intensity in
                    Text(intensity.displayName).tag(intensity)
                }
            }
        }
    }
    
    private var strengthDetailsSection: some View {
        Section("筋トレ詳細") {
            ForEach(strengthDetails.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 8) {
                    TextField("エクササイズ名", text: $strengthDetails[index].exerciseName)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("重量")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("kg", value: $strengthDetails[index].weight, format: .number)
                                .keyboardType(.decimalPad)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("セット")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("回", value: $strengthDetails[index].sets, format: .number)
                                .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("レップ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("回", value: $strengthDetails[index].reps, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteStrengthDetail)
            
            Button("エクササイズを追加") {
                strengthDetails.append(StrengthDetailEdit())
            }
            .foregroundColor(.blue)
        }
    }
    
    private var flexibilityDetailsSection: some View {
        Section("柔軟性詳細") {
            HStack {
                Text("前屈")
                Spacer()
                TextField("cm", value: $forwardBendDistance, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("cm")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("左開脚")
                Spacer()
                TextField("度", value: $leftSplitAngle, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("°")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("右開脚")
                Spacer()
                TextField("度", value: $rightSplitAngle, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("°")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("前後開脚（前）")
                Spacer()
                TextField("度", value: $frontSplitAngle, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("°")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("前後開脚（後）")
                Spacer()
                TextField("度", value: $backSplitAngle, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("°")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func deleteStrengthDetail(at offsets: IndexSet) {
        strengthDetails.remove(atOffsets: offsets)
    }
    
    private func saveWorkout() {
        // バリデーション
        guard !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "サマリーを入力してください"
            showingAlert = true
            return
        }
        
        // ワークアウトの更新
        let editedWorkout = WorkoutRecord(
            date: date,
            workoutType: workoutType,
            summary: summary
        )
        editedWorkout.isCompleted = isCompleted
        
        // 詳細データの設定
        switch workoutType {
        case .cycling:
            if distance > 0 || duration > 0 || averagePower > 0 {
                editedWorkout.cyclingDetail = CyclingDetail(
                    distance: Double(distance),
                    duration: duration,
                    averagePower: averagePower,
                    intensity: intensity
                )
            }
            
        case .strength:
            if !strengthDetails.isEmpty {
                editedWorkout.strengthDetails = strengthDetails.filter { !$0.exerciseName.isEmpty }.map { detail in
                    StrengthDetail(
                        exercise: detail.exerciseName,
                        sets: detail.sets,
                        reps: detail.reps,
                        weight: detail.weight
                    )
                }
            }
            
        case .flexibility:
            if forwardBendDistance > 0 || leftSplitAngle > 0 || rightSplitAngle > 0 || frontSplitAngle > 0 || backSplitAngle > 0 {
                editedWorkout.flexibilityDetail = FlexibilityDetail(
                    forwardBendDistance: forwardBendDistance,
                    leftSplitAngle: leftSplitAngle,
                    rightSplitAngle: rightSplitAngle,
                    frontSplitAngle: frontSplitAngle,
                    backSplitAngle: backSplitAngle
                )
            }
        }
        
        onSave(editedWorkout)
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
    WorkoutEditSheet(
        workout: {
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
        }(),
        onSave: { _ in },
        onCancel: { }
    )
}