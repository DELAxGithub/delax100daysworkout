import SwiftUI
import SwiftData

struct WeeklyScheduleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WeeklyTemplate> { $0.isActive }) private var activeTemplates: [WeeklyTemplate]
    
    let viewModel: WeeklyScheduleViewModel
    @State private var showingAddTaskSheet = false
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
                            showingAddTaskSheet = true
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
                                showingAddTaskSheet = true
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
                                WeeklyTaskListRow(
                                    task: task,
                                    day: day,
                                    viewModel: viewModel,
                                    isToday: isToday(day)
                                )
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingAddTaskSheet) {
            AddCustomTaskSheet(
                selectedDay: selectedDay,
                onSave: { task in
                    if let activeTemplate = activeTemplates.first {
                        viewModel.addCustomTask(task, to: activeTemplate)
                    }
                    showingAddTaskSheet = false
                },
                onCancel: {
                    showingAddTaskSheet = false
                }
            )
        }
    }
    
    private func isToday(_ day: Int) -> Bool {
        return Calendar.current.component(.weekday, from: Date()) - 1 == day
    }
}

struct WeeklyTaskListRow: View {
    let task: DailyTask
    let day: Int
    let viewModel: WeeklyScheduleViewModel
    let isToday: Bool
    
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
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            Image(systemName: workoutIcon)
                .font(.title3)
                .foregroundColor(workoutColor)
                .frame(width: 30, height: 30)
                .background(workoutColor.opacity(0.1))
                .clipShape(Circle())
            
            // タスク情報
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(isCompleted, color: .secondary)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // 詳細情報
                if let details = task.targetDetails {
                    HStack(spacing: 8) {
                        switch task.workoutType {
                        case .cycling:
                            if let duration = details.duration {
                                Label("\(duration)分", systemImage: "clock")
                            }
                            if let intensity = details.intensity {
                                Label(intensity.displayName, systemImage: "bolt")
                            }
                        case .strength:
                            if let sets = details.targetSets, let reps = details.targetReps {
                                Label("\(sets)セット×\(reps)回", systemImage: "repeat")
                            }
                        case .flexibility:
                            if let duration = details.targetDuration {
                                Label("\(duration)分", systemImage: "clock")
                            }
                        case .pilates:
                            if let duration = details.targetDuration {
                                Label("\(duration)分", systemImage: "clock")
                            }
                        case .yoga:
                            if let duration = details.targetDuration {
                                Label("\(duration)分", systemImage: "clock")
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 完了ボタン（今日のタスクのみ）
            if isToday {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        let _ = viewModel.quickCompleteTask(task)
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundColor(workoutColor)
                    }
                }
            } else if task.isFlexible {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(isCompleted ? 0.6 : 1.0)
    }
}

#Preview {
    WeeklyScheduleListView(viewModel: WeeklyScheduleViewModel(modelContext: ModelContext(try! ModelContainer(for: WeeklyTemplate.self))))
        .modelContainer(for: [WeeklyTemplate.self], inMemory: true)
}