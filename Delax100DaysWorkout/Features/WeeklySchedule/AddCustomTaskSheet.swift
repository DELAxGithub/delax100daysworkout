import SwiftUI
import SwiftData
import OSLog

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
    
    // ピラティス詳細
    @State private var pilatesExerciseType: String = ""
    @State private var pilatesRepetitions: Int = 12
    @State private var pilatesHoldTime: Int = 30
    @State private var pilatesDifficulty: PilatesDifficulty = .beginner
    @State private var coreEngagement: Double = 5.0
    @State private var posturalAlignment: Double = 5.0
    @State private var breathControl: Double = 5.0
    
    // ヨガ詳細
    @State private var yogaStyle: YogaStyle = .hatha
    @State private var poses: [String] = [""]
    @State private var breathingTechnique: String = ""
    @State private var flexibility: Double = 5.0
    @State private var balance: Double = 5.0
    @State private var mindfulness: Double = 5.0
    @State private var meditation: Bool = false
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let dayNames = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg.value) {
                // Header
                UnifiedHeaderComponent(
                    configuration: .detail(
                        title: "カスタムタスク追加",
                        subtitle: "\(dayNames[selectedDay])曜日",
                        onBack: {
                            HapticManager.shared.trigger(.impact(.light))
                            onCancel()
                        },
                        onAction: {
                            HapticManager.shared.trigger(.impact(.medium))
                            saveTask()
                        },
                        actionIcon: "checkmark.circle.fill"
                    )
                )
                .padding(.horizontal)
                
                // Basic Information
                basicInformationSection
                
                // Workout Type Picker
                UnifiedWorkoutTypePicker(
                    selectedType: $workoutType,
                    onSelectionChanged: { newType in
                        setDefaultValues(for: newType)
                    }
                )
                .padding(.horizontal)
                
                // Workout Details
                workoutDetailsSection
            }
            .padding(.bottom, Spacing.xl.value)
        }
        .background(SemanticColor.primaryBackground.color)
        .alert("入力エラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            setDefaultValues(for: workoutType)
        }
    }
    // MARK: - View Components
    
    private var basicInformationSection: some View {
        BaseCard(style: OutlinedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                HStack {
                    Text("基本情報")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                }
                .padding(.bottom, Spacing.sm.value)
                
                TextInputRow(
                    label: "タイトル",
                    text: $title,
                    placeholder: "タイトルを入力"
                )
                
                Divider()
                
                TextInputRow(
                    label: "説明（任意）",
                    text: $taskDescription,
                    placeholder: "詳細を入力"
                )
                
                Divider()
                
                HStack {
                    Text("フレキシブルタスク")
                        .font(Typography.bodyLarge.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isFlexible)
                        .toggleStyle(SwitchToggleStyle())
                        .accessibilityLabel("フレキシブルタスク")
                        .accessibilityHint("パフォーマンスに応じて目標が自動調整されます")
                }
                .frame(minHeight: 44)
            }
            .padding(Spacing.md.value)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var workoutDetailsSection: some View {
        switch workoutType {
        case .cycling:
            CyclingDetailComponent(
                duration: $duration,
                intensity: $intensity,
                targetPower: $targetPower
            )
            .padding(.horizontal)
            
        case .strength:
            StrengthDetailComponent(
                exercises: $exercises,
                targetSets: $targetSets,
                targetReps: $targetReps
            )
            .padding(.horizontal)
            
        case .flexibility:
            FlexibilityDetailComponent(
                targetDuration: $targetDuration,
                targetForwardBend: $targetForwardBend,
                targetSplitAngle: $targetSplitAngle
            )
            .padding(.horizontal)
            
        case .pilates:
            PilatesDetailComponent(
                duration: $targetDuration,
                exerciseType: $pilatesExerciseType,
                repetitions: $pilatesRepetitions,
                holdTime: $pilatesHoldTime,
                difficulty: $pilatesDifficulty,
                coreEngagement: $coreEngagement,
                posturalAlignment: $posturalAlignment,
                breathControl: $breathControl
            )
            .padding(.horizontal)
            
        case .yoga:
            YogaDetailComponent(
                duration: $targetDuration,
                yogaStyle: $yogaStyle,
                poses: $poses,
                breathingTechnique: $breathingTechnique,
                flexibility: $flexibility,
                balance: $balance,
                mindfulness: $mindfulness,
                meditation: $meditation
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setDefaultValues(for type: WorkoutType) {
        if title.isEmpty {
            title = getDefaultTitle(for: type)
        }
        
        switch type {
        case .cycling:
            duration = 60
            intensity = .endurance
            targetPower = 200
            
        case .strength:
            if exercises.isEmpty || exercises == [""] {
                exercises = [""]
            }
            targetSets = 3
            targetReps = 10
            
        case .flexibility:
            targetDuration = 20
            targetForwardBend = 0
            targetSplitAngle = 120
            
        case .pilates:
            targetDuration = 45
            pilatesExerciseType = ""
            pilatesRepetitions = 12
            pilatesHoldTime = 30
            pilatesDifficulty = .beginner
            coreEngagement = 5.0
            posturalAlignment = 5.0
            breathControl = 5.0
            
        case .yoga:
            targetDuration = 60
            yogaStyle = .hatha
            if poses.isEmpty || poses == [""] {
                poses = [""]
            }
            breathingTechnique = ""
            flexibility = 5.0
            balance = 5.0
            mindfulness = 5.0
            meditation = false
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
        case .pilates:
            return "カスタムピラティス"
        case .yoga:
            return "カスタムヨガ"
        }
    }
    
    
    private func saveTask() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "タイトルを入力してください"
            showingAlert = true
            HapticManager.shared.trigger(.notification(.error))
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
            
        case .pilates:
            if targetDuration > 0 {
                // Create enhanced pilates target details with all new properties
                targetDetails = TargetDetails(
                    targetDuration: targetDuration,
                    exerciseType: pilatesExerciseType.isEmpty ? nil : pilatesExerciseType,
                    repetitions: pilatesRepetitions > 0 ? pilatesRepetitions : nil,
                    holdTime: pilatesHoldTime > 0 ? pilatesHoldTime : nil,
                    difficulty: pilatesDifficulty,
                    coreEngagement: coreEngagement,
                    posturalAlignment: posturalAlignment,
                    breathControl: breathControl
                )
            }
            
        case .yoga:
            if targetDuration > 0 {
                let validPoses = poses.compactMap { pose in
                    let trimmed = pose.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                }
                
                // Create enhanced yoga target details with all new properties
                targetDetails = TargetDetails(
                    targetDuration: targetDuration,
                    yogaStyle: yogaStyle,
                    poses: validPoses.isEmpty ? nil : validPoses,
                    breathingTechnique: breathingTechnique.isEmpty ? nil : breathingTechnique,
                    flexibility: flexibility,
                    balance: balance,
                    mindfulness: mindfulness,
                    meditation: meditation
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
        
        HapticManager.shared.trigger(.notification(.success))
        onSave(task)
    }
}

// MARK: - Preview

#Preview("AddCustomTaskSheet") {
    AddCustomTaskSheet(
        selectedDay: 2,
        onSave: { task in
            Logger.ui.info("Saved task: \(task.title) for \(task.workoutType.rawValue)")
        },
        onCancel: {
            Logger.ui.info("Task creation cancelled")
        }
    )
    .preferredColorScheme(.light)
}