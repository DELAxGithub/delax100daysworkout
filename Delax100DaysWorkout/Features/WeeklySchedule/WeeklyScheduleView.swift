import SwiftUI
import SwiftData

enum ScheduleViewMode: String, CaseIterable {
    case day = "日表示"
    case week = "週表示"
    
    var systemImage: String {
        switch self {
        case .day: return "calendar.day.timeline.left"
        case .week: return "list.bullet"
        }
    }
}

struct WeeklyScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WeeklyTemplate> { $0.isActive }) private var activeTemplates: [WeeklyTemplate]
    
    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date()) - 1
    @State private var viewModel: WeeklyScheduleViewModel?
    @State private var showingAddTaskSheet = false
    @State private var viewMode: ScheduleViewMode = .day
    
    private let dayNames = ["日", "月", "火", "水", "木", "金", "土"]
    private let dayColors: [Color] = [.red, .gray, .gray, .gray, .gray, .gray, .blue]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ビューモード切り替え
                Picker("表示モード", selection: $viewMode) {
                    ForEach(ScheduleViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // 表示内容をビューモードに応じて切り替え
                if viewMode == .day {
                    dayView
                } else {
                    weekView
                }
            }
            .navigationTitle("スケジュール")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showingAddTaskSheet = true
                        } label: {
                            Label("追加", systemImage: "plus")
                        }
                        
                        Button {
                            jumpToToday()
                        } label: {
                            Label("今日へ", systemImage: "calendar.day.timeline.left")
                        }
                    }
                }
            }
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
        .sheet(isPresented: $showingAddTaskSheet) {
            AddCustomTaskSheet(
                selectedDay: selectedDay,
                onSave: { task in
                    if let activeTemplate = activeTemplates.first {
                        viewModel?.addCustomTask(task, to: activeTemplate)
                    }
                    showingAddTaskSheet = false
                },
                onCancel: {
                    showingAddTaskSheet = false
                }
            )
        }
    }
    
    private func jumpToToday() {
        withAnimation(.spring(response: 0.3)) {
            selectedDay = Calendar.current.component(.weekday, from: Date()) - 1
        }
    }
    
    private func ensureActiveTemplate() {
        if activeTemplates.isEmpty {
            let defaultTemplate = WeeklyTemplate.createDefaultTemplate()
            defaultTemplate.activate()
            modelContext.insert(defaultTemplate)
        }
    }
    
    // MARK: - View Components
    
    private var dayView: some View {
        VStack(spacing: 0) {
            // 曜日セレクター
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<7) { day in
                        DayButton(
                            day: day,
                            dayName: dayNames[day],
                            isSelected: selectedDay == day,
                            color: dayColors[day]
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDay = day
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.systemBackground))
            
            Divider()
            
            // タスクリスト - スクロール可能エリア
            if let template = activeTemplates.first {
                let tasks = template.tasksForDay(selectedDay)
                
                if tasks.isEmpty {
                    Spacer()
                    Button(action: {
                        showingAddTaskSheet = true
                    }) {
                        ContentUnavailableView(
                            "休息日",
                            systemImage: "moon.zzz",
                            description: Text("\(dayNames[selectedDay])曜日はトレーニングがありません\nタップしてトレーニングを追加")
                        )
                    }
                    .buttonStyle(.plain)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(tasks) { task in
                                WeeklyTaskCard(
                                    task: task,
                                    selectedDay: selectedDay,
                                    viewModel: viewModel
                                )
                            }
                        }
                        .padding()
                    }
                }
            } else {
                Spacer()
                ContentUnavailableView(
                    "テンプレートがありません",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("アクティブなテンプレートを作成してください")
                )
                Spacer()
            }
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

struct DayButton: View {
    let day: Int
    let dayName: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : color)
                
                if isToday() {
                    Circle()
                        .fill(isSelected ? Color.white : color)
                        .frame(width: 6, height: 6)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : Color(.systemGray6))
            )
        }
    }
    
    private func isToday() -> Bool {
        Calendar.current.component(.weekday, from: Date()) - 1 == day
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
                    Text(task.title)
                        .font(.headline)
                    
                    if let description = task.taskDescription, !description.isEmpty {
                        Text(description)
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
    
    var body: some View {
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
                    label: "強度",
                    value: intensity.displayName
                )
            }
            
            if let power = details.targetPower {
                DetailItem(
                    icon: "speedometer",
                    label: "パワー",
                    value: "\(power)W"
                )
            }
        }
    }
}

struct StrengthDetailsView: View {
    let details: TargetDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let exercises = details.exercises, !exercises.isEmpty {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.secondary)
                    Text(exercises.joined(separator: ", "))
                        .font(.caption)
                }
            }
            
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
        }
    }
}

struct FlexibilityDetailsView: View {
    let details: TargetDetails
    
    var body: some View {
        HStack(spacing: 20) {
            if let duration = details.targetDuration {
                DetailItem(
                    icon: "clock",
                    label: "時間",
                    value: "\(duration)分"
                )
            }
            
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
}

// プレビュー用の拡張
extension CyclingIntensity {
    var displayName: String {
        switch self {
        case .endurance: return "Endurance"
        case .sst: return "SST"
        case .vo2max: return "VO2max"
        case .recovery: return "Recovery"
        case .z2: return "Zone 2"
        case .tempo: return "Tempo"
        case .anaerobic: return "Anaerobic"
        case .sprint: return "Sprint"
        }
    }
}

#Preview {
    WeeklyScheduleView()
        .modelContainer(for: [WeeklyTemplate.self], inMemory: true)
}