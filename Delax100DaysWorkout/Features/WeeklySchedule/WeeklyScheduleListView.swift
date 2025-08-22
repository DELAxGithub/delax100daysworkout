import SwiftUI
import SwiftData

struct WeeklyScheduleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WeeklyTemplate> { $0.isActive }) private var activeTemplates: [WeeklyTemplate]
    
    let viewModel: WeeklyScheduleViewModel
    @State private var showingAddTaskSheet = false
    @State private var showingQuickRecordSheet = false
    @State private var selectedDay = 0
    
    private let dayNames = ["日", "月", "火", "水", "木", "金", "土"]
    private let dayColors: [Color] = [.red, .gray, .gray, .gray, .gray, .gray, .blue]
    
    var body: some View {
        List {
            ForEach(0..<7, id: \.self) { day in
                Section(header:
                    HStack {
                        Text(dayNames[day])
                            .font(.headline)
                            .foregroundColor(dayColors[day])
                        
                        if let template = activeTemplates.first {
                            let taskCount = template.tasksForDay(day).count
                            if taskCount > 0 {
                                Text("\(taskCount)件")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedDay = day
                            showingQuickRecordSheet = true
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                ) {
                    if let template = activeTemplates.first {
                        let tasks = template.tasksForDay(day)
                        
                        if tasks.isEmpty {
                            Button(action: {
                                selectedDay = day
                                showingQuickRecordSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "moon.zzz")
                                        .foregroundColor(.secondary)
                                    Text("休息日 - タップしてトレーニング追加")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(tasks) { task in
                                DraggableTaskRow(
                                    task: task,
                                    day: day,
                                    viewModel: viewModel,
                                    isToday: isToday(day)
                                )
                                .onDrop(of: [.text], delegate: TaskDropDelegate(
                                    task: task,
                                    day: day,
                                    viewModel: viewModel
                                ))
                            }
                            .onMove { source, destination in
                                viewModel.moveTasksInDay(day, from: source, to: destination)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        // AddCustomTaskSheet removed - now handled by QuickRecordView
        .alert("タスクを削除", isPresented: .constant(viewModel.showingDeleteConfirmation != nil)) {
            Button("削除", role: .destructive) {
                if let task = viewModel.showingDeleteConfirmation {
                    viewModel.deleteTask(task)
                    viewModel.showingDeleteConfirmation = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                viewModel.showingDeleteConfirmation = nil
            }
        } message: {
            if let task = viewModel.showingDeleteConfirmation {
                Text("「\(task.title)」を削除しますか？この操作は取り消せません。")
            }
        }
        .sheet(item: Binding<IdentifiableTask?>(
            get: { viewModel.showingMoveTask.map(IdentifiableTask.init) },
            set: { _ in viewModel.showingMoveTask = nil }
        )) { identifiableTask in
            TaskMoveSheet(task: identifiableTask.task, viewModel: viewModel)
        }
        .sheet(isPresented: $showingQuickRecordSheet) {
            let capturedDay = selectedDay  // selectedDayをキャプチャ
            if let template = activeTemplates.first {
                QuickRecordView(
                    selectedDay: capturedDay,
                    dayTasks: template.tasksForDay(capturedDay),
                    scheduleViewModel: viewModel
                )
            } else {
                QuickRecordView(
                    selectedDay: capturedDay,
                    scheduleViewModel: viewModel
                )
            }
        }
    }
    
    private func isToday(_ day: Int) -> Bool {
        return Calendar.current.component(.weekday, from: Date()) - 1 == day
    }
}

// MARK: - Draggable Task Row

struct DraggableTaskRow: View {
    let task: DailyTask
    let day: Int
    let viewModel: WeeklyScheduleViewModel
    let isToday: Bool
    
    @State private var isDragging = false
    
    var body: some View {
        DraggableContainer(
            onDragStart: {
                isDragging = true
                HapticManager.shared.trigger(.impact(.medium))
            },
            onDragEnd: {
                isDragging = false
            },
            dragData: {
                // Create drag data with task ID
                let taskData = "task:\(task.id)"
                return NSItemProvider(object: taskData as NSString)
            }
        ) {
            WeeklyTaskListRow(
                task: task,
                day: day,
                viewModel: viewModel,
                isToday: isToday
            )
        }
        .opacity(isDragging ? 0.6 : 1.0)
        .swipeActions(edge: .trailing) {
            Button("削除", role: .destructive) {
                viewModel.confirmDeleteTask(task)
            }
            .tint(SemanticColor.destructiveAction.color)
        }
        .swipeActions(edge: .leading) {
            Button("編集") {
                viewModel.startEditingTask(task)
            }
            .tint(SemanticColor.primaryAction.color)
        }
        .contextMenu {
            Button("編集", systemImage: "pencil") {
                viewModel.startEditingTask(task)
            }
            
            Button("複製", systemImage: "doc.on.doc") {
                viewModel.duplicateTask(task)
            }
            
            Button("移動", systemImage: "arrow.right") {
                viewModel.showMoveTaskSheet(task)
            }
            
            Divider()
            
            Button("削除", systemImage: "trash", role: .destructive) {
                viewModel.confirmDeleteTask(task)
            }
        }
    }
}

struct WeeklyTaskListRow: View {
    let task: DailyTask
    let day: Int
    let viewModel: WeeklyScheduleViewModel
    let isToday: Bool
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPressed = false
    
    private var isEditing: Bool {
        viewModel.isTaskEditing(task)
    }
    
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
    
    private var isCompleted: Bool {
        viewModel.isTaskCompleted(task)
    }
    
    private var animationValue: Animation? {
        reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7)
    }
    
    var body: some View {
        Group {
            if isEditing {
                EditableTaskCard(task: task, viewModel: viewModel)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } else {
                regularTaskRow
            }
        }
    }
    
    private var regularTaskRow: some View {
        HStack(spacing: Spacing.listItemSpacing.value) {
            // Apple Reminders-style checkbox
            RemindersStyleCheckbox(
                isCompleted: isCompleted,
                action: { viewModel.toggleTaskCompletion(task) },
                style: .workout
            )
            
            // ワークアウトアイコン
            Image(systemName: workoutIcon)
                .font(.title3)
                .foregroundColor(workoutColor)
                .frame(width: 28, height: 28)
                .background(workoutColor.opacity(0.1))
                .clipShape(Circle())
            
            // タスク情報
            VStack(alignment: .leading, spacing: 4) {
                Text(task.displayTitle)
                    .font(Typography.bodyMedium.font)
                    .fontWeight(.medium)
                    .strikethrough(isCompleted, pattern: .solid, color: SemanticColor.secondaryText.color)
                    .foregroundColor(isCompleted ? SemanticColor.secondaryText.color : SemanticColor.primaryText.color)
                    .animation(animationValue, value: isCompleted)
                
                if let subtitle = task.displaySubtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                        .lineLimit(2)
                }
                
                // 重要度の高い補助情報のみ表示
                if let details = task.targetDetails {
                    HStack(spacing: 6) {
                        switch task.workoutType {
                        case .cycling:
                            // パワーがサブタイトルに含まれていない場合のみ表示
                            if let power = details.targetPower, power > 0, !(task.displaySubtitle?.contains("\(power)W") ?? false) {
                                CompactDetailLabel(icon: "gauge", text: "\(power)W")
                            }
                            // 心拍数がサブタイトルに含まれていない場合のみ表示
                            if let heartRate = details.averageHeartRate, heartRate > 0, !(task.displaySubtitle?.contains("\(heartRate)bpm") ?? false) {
                                CompactDetailLabel(icon: "heart.fill", text: "\(heartRate)bpm")
                            }
                            // ワットパー心拍がサブタイトルに含まれていない場合のみ表示
                            if let wattsPerBpm = details.wattsPerBpm, !(task.displaySubtitle?.contains("W/bpm") ?? false) {
                                CompactDetailLabel(icon: "bolt.heart.fill", text: String(format: "%.2f W/bpm", wattsPerBpm))
                            }
                        case .strength:
                            // セット×レップがタイトルに含まれていない場合のみ表示
                            if let sets = details.targetSets, let reps = details.targetReps, !task.displayTitle.contains("\(sets)×\(reps)") {
                                CompactDetailLabel(icon: "repeat", text: "\(sets)×\(reps)")
                            }
                        case .flexibility, .pilates, .yoga:
                            // 時間がタイトルに含まれていない場合のみ表示
                            if let duration = details.targetDuration, !task.displayTitle.contains("\(duration)分") {
                                CompactDetailLabel(icon: "clock.fill", text: "\(duration)分")
                            }
                            // 測定値がサブタイトルに含まれていない場合のみ表示
                            if let forwardBend = details.targetForwardBend, forwardBend > 0, !(task.displaySubtitle?.contains("前屈") ?? false) {
                                CompactDetailLabel(icon: "arrow.down", text: "\(Int(forwardBend))cm")
                            }
                            if let splitAngle = details.targetSplitAngle, splitAngle > 0, !(task.displaySubtitle?.contains("開脚") ?? false) {
                                CompactDetailLabel(icon: "triangle", text: "\(Int(splitAngle))°")
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // ステータスインジケーター
            VStack {
                if isToday && !isCompleted {
                    Circle()
                        .fill(workoutColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                        .animation(animationValue, value: isPressed)
                } else if task.isFlexible {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundColor(SemanticColor.secondaryText.color)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, Spacing.sm.value)
        .background(SemanticColor.cardBackground.color.opacity(isPressed ? 0.5 : 0.0))
        .cornerRadius(CornerRadius.medium)
        .opacity(isCompleted ? 0.7 : 1.0)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(animationValue, value: isCompleted)
        .animation(animationValue, value: isPressed)
        .contentShape(Rectangle()) // Ensure entire row is tappable
        .onTapGesture {
            withAnimation(animationValue) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(animationValue) {
                    isPressed = false
                }
                viewModel.toggleTaskCompletion(task)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(taskAccessibilityLabel)
        .accessibilityValue(isCompleted ? "完了済み" : "未完了")
        .accessibilityActions {
            Button("完了切り替え") {
                viewModel.toggleTaskCompletion(task)
            }
            Button("編集") {
                viewModel.startEditingTask(task)
            }
            Button("削除") {
                viewModel.confirmDeleteTask(task)
            }
        }
    }
    
    private var taskAccessibilityLabel: String {
        var label = task.displayTitle
        if let subtitle = task.displaySubtitle, !subtitle.isEmpty {
            label += "、\(subtitle)"
        }
        return label
    }
}

struct CompactDetailLabel: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(SemanticColor.secondaryText.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(SemanticColor.surfaceBackground.color)
        .cornerRadius(CornerRadius.small)
    }
}

// MARK: - Helper Types

struct IdentifiableTask: Identifiable {
    let id = UUID()
    let task: DailyTask
    
    init(task: DailyTask) {
        self.task = task
    }
}

// MARK: - Task Move Sheet

struct TaskMoveSheet: View {
    let task: DailyTask
    let viewModel: WeeklyScheduleViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let dayNames = ["日", "月", "火", "水", "木", "金", "土"]
    private let dayColors: [Color] = [.red, .gray, .gray, .gray, .gray, .gray, .blue]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(0..<7, id: \.self) { day in
                        Button(action: {
                            viewModel.moveTask(task, toDay: day)
                            dismiss()
                        }) {
                            HStack {
                                Circle()
                                    .fill(dayColors[day])
                                    .frame(width: 12, height: 12)
                                
                                Text("\(dayNames[day])曜日")
                                    .font(Typography.bodyMedium.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                
                                Spacer()
                                
                                if day == task.dayOfWeek {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(SemanticColor.primaryAction.color)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(day == task.dayOfWeek)
                    }
                } header: {
                    Text("移動先を選択")
                }
            }
            .navigationTitle("タスクを移動")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Task Drop Delegate

struct TaskDropDelegate: DropDelegate {
    let task: DailyTask
    let day: Int
    let viewModel: WeeklyScheduleViewModel
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        
        itemProvider.loadObject(ofClass: NSString.self) { (data, error) in
            guard let draggedData = data as? String,
                  draggedData.hasPrefix("task:") else {
                return
            }
            
            let draggedTaskIdString = String(draggedData.dropFirst(5))
            
            DispatchQueue.main.async {
                viewModel.moveTaskToPosition(
                    draggedTaskId: draggedTaskIdString,
                    targetTask: task,
                    targetDay: day
                )
                HapticManager.shared.trigger(.impact(.light))
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        HapticManager.shared.trigger(.selection)
    }
}

// MARK: - Preview

#Preview {
    WeeklyScheduleListView(viewModel: WeeklyScheduleViewModel(modelContext: {
        do {
            return ModelContext(try ModelContainer(for: WeeklyTemplate.self))
        } catch {
            fatalError("Preview ModelContainer creation failed: \(error)")
        }
    }()))
        .modelContainer(for: [WeeklyTemplate.self], inMemory: true)
}