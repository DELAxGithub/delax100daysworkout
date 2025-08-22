import SwiftUI
import SwiftData


struct WeeklyScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WeeklyTemplate> { $0.isActive }) private var activeTemplates: [WeeklyTemplate]
    
    @State private var viewModel: WeeklyScheduleViewModel?
    
    
    var body: some View {
        NavigationStack {
            // 週表示
            weekView
                .navigationTitle("スケジュール")
                .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            ensureActiveTemplate()
            if viewModel == nil {
                viewModel = WeeklyScheduleViewModel(modelContext: modelContext)
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showingQuickRecord ?? false },
            set: { _ in viewModel?.showingQuickRecord = false }
        )) {
            if let task = viewModel?.quickRecordTask, let record = viewModel?.quickRecordWorkout {
                QuickRecordSheet(task: task, workoutRecord: record)
            }
        }
        // AddCustomTaskSheet removed - using QuickRecordView instead
    }
    
    
    private func ensureActiveTemplate() {
        if activeTemplates.isEmpty {
            let defaultTemplate = WeeklyTemplate.createDefaultTemplate()
            defaultTemplate.activate()
            modelContext.insert(defaultTemplate)
        }
    }
    
    private var weekView: some View {
        Group {
            if let viewModel = viewModel {
                WeeklyScheduleListView(viewModel: viewModel)
            } else {
                ProgressView("読み込み中...")
            }
        }
    }
}


struct WeeklyTaskCard: View {
    let task: DailyTask
    let selectedDay: Int
    let viewModel: WeeklyScheduleViewModel?
    
    private var workoutIcon: String {
        switch task.workoutType {
        case .cycling:
            return "bicycle"
        case .strength:
            return "figure.strengthtraining.traditional"
        case .flexibility:
            return "figure.flexibility"
        case .pilates:
            return "figure.pilates"
        case .yoga:
            return "figure.yoga"
        }
    }
    
    private var workoutColor: Color {
        switch task.workoutType {
        case .cycling:
            return .blue
        case .strength:
            return .orange
        case .flexibility:
            return .green
        case .pilates:
            return .purple
        case .yoga:
            return .mint
        }
    }
    
    private var isToday: Bool {
        Calendar.current.component(.weekday, from: Date()) - 1 == selectedDay
    }
    
    private var isCompleted: Bool {
        viewModel?.isTaskCompleted(task) ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Image(systemName: workoutIcon)
                    .font(.title2)
                    .foregroundColor(workoutColor)
                    .frame(width: 40, height: 40)
                    .background(workoutColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.displayTitle)
                        .font(.headline)
                    
                    if let subtitle = task.displaySubtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 今日のタスクの場合、完了ボタンまたは完了チェックマークを表示
                if isToday {
                    Button(action: {
                        if isCompleted {
                            // 完了済みの場合、未完了に戻す
                            viewModel?.markTaskAsIncomplete(task)
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        } else {
                            // 未完了の場合、完了にする
                            if let record = viewModel?.quickCompleteTask(task) {
                                viewModel?.quickRecordTask = task
                                viewModel?.quickRecordWorkout = record
                                viewModel?.showingQuickRecord = true
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isCompleted ? .green : workoutColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if task.isFlexible {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            
            // 詳細情報
            if let details = task.targetDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    switch task.workoutType {
                    case .cycling:
                        CyclingDetailsView(details: details)
                    case .strength:
                        StrengthDetailsView(details: details)
                    case .flexibility:
                        FlexibilityDetailsView(details: details)
                    case .pilates:
                        Text("ピラティス詳細は後で実装")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    case .yoga:
                        Text("ヨガ詳細は後で実装")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(isCompleted ? 0.6 : 1.0)
    }
}

struct CyclingDetailsView: View {
    let details: TargetDetails
    @Environment(\.modelContext) private var modelContext
    @Query private var workoutRecords: [WorkoutRecord]
    
    private var cyclingZone: CyclingZone {
        if let intensity = details.intensity {
            return intensity
        }
        return .z2 // デフォルト
    }
    
    private var periodCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        return WorkoutRecord.countCyclingZoneInPeriod(
            records: workoutRecords,
            zone: cyclingZone,
            startDate: startOfWeek
        )
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 第1行: 時間と強度
            HStack(spacing: 20) {
                if let duration = details.duration {
                    DetailItem(
                        icon: "clock",
                        label: "時間",
                        value: "\(duration)分"
                    )
                }
                
                if let intensity = details.intensity {
                    DetailItem(
                        icon: "bolt",
                        label: "ゾーン",
                        value: intensity.shortDisplayName
                    )
                }
                
                if periodCount > 0 {
                    DetailItem(
                        icon: "calendar.badge.clock",
                        label: "今週",
                        value: "\(periodCount)回目"
                    )
                }
            }
            
            // 第2行: パワーと心拍数
            HStack(spacing: 20) {
                if let power = details.targetPower, power > 0 {
                    DetailItem(
                        icon: "speedometer",
                        label: "パワー",
                        value: "\(power)W"
                    )
                }
                
                if let heartRate = details.averageHeartRate, heartRate > 0 {
                    DetailItem(
                        icon: "heart",
                        label: "平均心拍",
                        value: "\(heartRate)bpm"
                    )
                }
            }
            
            // 第3行: ワットパー心拍（計算値がある場合のみ）
            if let wattsPerBpm = details.wattsPerBpm {
                HStack {
                    Spacer()
                    DetailItem(
                        icon: "bolt.heart",
                        label: "W/bpm",
                        value: String(format: "%.2f", wattsPerBpm)
                    )
                    Spacer()
                }
            }
        }
    }
}

struct StrengthDetailsView: View {
    let details: TargetDetails
    @Environment(\.modelContext) private var modelContext
    @Query private var workoutRecords: [WorkoutRecord]
    
    private var periodCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        // 主要な筋肉部位を特定
        if let muscleGroup = details.targetMuscleGroup {
            return WorkoutRecord.countStrengthInPeriod(
                records: workoutRecords,
                muscleGroup: muscleGroup,
                startDate: startOfWeek
            )
        }
        return 0
    }
    
    private func determineMuscleGroup(from exercise: String) -> WorkoutMuscleGroup {
        let lowerExercise = exercise.lowercased()
        
        // 胸筋群
        if lowerExercise.contains("胸") || lowerExercise.contains("プッシュアップ") || lowerExercise.contains("ベンチプレス") || lowerExercise.contains("chest") {
            return .chest
        }
        // 脚筋群
        else if lowerExercise.contains("脚") || lowerExercise.contains("足") || lowerExercise.contains("スクワット") || lowerExercise.contains("ランジ") || lowerExercise.contains("leg") || lowerExercise.contains("太もも") || lowerExercise.contains("ふくらはぎ") {
            return .legs
        }
        // 背筋群
        else if lowerExercise.contains("背中") || lowerExercise.contains("背筋") || lowerExercise.contains("プルアップ") || lowerExercise.contains("ロー") || lowerExercise.contains("back") || lowerExercise.contains("懸垂") {
            return .back
        }
        // 肩筋群
        else if lowerExercise.contains("肩") || lowerExercise.contains("ショルダー") || lowerExercise.contains("shoulder") || lowerExercise.contains("三角筋") {
            return .shoulders
        }
        // 腕筋群
        else if lowerExercise.contains("腕") || lowerExercise.contains("アーム") || lowerExercise.contains("カール") || lowerExercise.contains("arm") || lowerExercise.contains("上腕") || lowerExercise.contains("前腕") {
            return .arms
        }
        // 体幹・腹筋群
        else if lowerExercise.contains("腹筋") || lowerExercise.contains("プランク") || lowerExercise.contains("コア") || lowerExercise.contains("core") || lowerExercise.contains("体幹") {
            return .core
        }
        
        return .custom
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let muscleGroup = details.targetMuscleGroup {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.secondary)
                    Text(muscleGroup.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            // 第1行: セット数とレップ数
            HStack(spacing: 20) {
                if let sets = details.targetSets {
                    DetailItem(
                        icon: "repeat",
                        label: "セット",
                        value: "\(sets)"
                    )
                }
                
                if let reps = details.targetReps {
                    DetailItem(
                        icon: "number",
                        label: "レップ",
                        value: "\(reps)"
                    )
                }
            }
            
            // 第2行: 重量と今週の回数
            HStack(spacing: 20) {
                if let weight = details.targetWeight, weight > 0 {
                    DetailItem(
                        icon: "scalemass",
                        label: "重量",
                        value: "\(Int(weight))kg"
                    )
                }
                
                if periodCount > 0 {
                    DetailItem(
                        icon: "calendar.badge.clock",
                        label: "今週",
                        value: "\(periodCount)回目"
                    )
                }
            }
        }
    }
}

struct FlexibilityDetailsView: View {
    let details: TargetDetails
    @Environment(\.modelContext) private var modelContext
    @Query private var workoutRecords: [WorkoutRecord]
    
    private var flexibilityType: FlexibilityType {
        if details.targetForwardBend != nil {
            return .forwardBend
        } else if details.targetSplitAngle != nil {
            return .split
        }
        return .general
    }
    
    private var periodCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        return WorkoutRecord.countFlexibilityTypeInPeriod(
            records: workoutRecords,
            type: flexibilityType,
            startDate: startOfWeek
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 第1行: 時間とタイプ
            HStack(spacing: 20) {
                if let duration = details.targetDuration {
                    DetailItem(
                        icon: "clock",
                        label: "時間",
                        value: "\(duration)分"
                    )
                }
                
                DetailItem(
                    icon: "figure.flexibility",
                    label: "種類",
                    value: flexibilityType.displayName
                )
            }
            
            // 第2行: 測定値と今週の回数
            HStack(spacing: 20) {
                if let forwardBend = details.targetForwardBend {
                    DetailItem(
                        icon: "arrow.down",
                        label: "前屈",
                        value: "\(forwardBend)cm"
                    )
                }
                
                if let splitAngle = details.targetSplitAngle {
                    DetailItem(
                        icon: "angle",
                        label: "開脚",
                        value: "\(splitAngle)°"
                    )
                }
                
                if periodCount > 0 {
                    DetailItem(
                        icon: "calendar.badge.clock",
                        label: "今週",
                        value: "\(periodCount)回目"
                    )
                }
            }
        }
    }
}

struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 12)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// プレビュー用の拡張 - CyclingIntensity removed

#Preview {
    WeeklyScheduleView()
        .modelContainer(for: [WeeklyTemplate.self], inMemory: true)
}