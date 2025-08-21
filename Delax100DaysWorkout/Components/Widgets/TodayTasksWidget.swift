import SwiftUI

// MARK: - Today Tasks Widget

struct TodayTasksWidget: View {
    let scheduleViewModel: WeeklyScheduleViewModel
    let maxDisplayCount: Int = 3
    
    var body: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                WidgetHeader()
                TasksList()
                QuickActions()
            }
        }
    }
    
    @ViewBuilder
    private func WidgetHeader() -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.headlineMedium.font)
                .foregroundColor(SemanticColor.successAction)
            
            Text("今日のタスク")
                .font(Typography.headlineMedium.font)
                .foregroundColor(SemanticColor.primaryText)
            
            Spacer()
            
            Text("\(completedTasksCount)/\(todaysTasks.count)")
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.secondaryText)
        }
    }
    
    @ViewBuilder 
    private func TasksList() -> some View {
        ForEach(Array(todaysTasks.prefix(maxDisplayCount)), id: \.id) { task in
            TaskRow(
                task: task,
                isCompleted: scheduleViewModel.isTaskCompleted(task),
                onToggle: { scheduleViewModel.toggleTaskCompletion(task) }
            )
        }
        
        if todaysTasks.count > maxDisplayCount {
            Button("他 \(todaysTasks.count - maxDisplayCount) 個のタスク") {
                // Navigate to full task list
            }
            .font(Typography.captionMedium.font)
            .foregroundColor(SemanticColor.linkText)
        }
    }
    
    @ViewBuilder
    private func QuickActions() -> some View {
        if !todaysTasks.isEmpty {
            HStack(spacing: Spacing.sm.value) {
                WidgetQuickActionButton(
                    title: "すべて完了",
                    icon: "checkmark.circle",
                    action: completeAllTasks
                )
                .disabled(allTasksCompleted)
                
                Spacer()
                
                WidgetQuickActionButton(
                    title: "詳細表示",
                    icon: "arrow.right.circle",
                    action: showFullTaskList
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var todaysTasks: [DailyTask] {
        return scheduleViewModel.getTodaysTasks()
    }
    
    private var completedTasksCount: Int {
        return todaysTasks.filter { scheduleViewModel.isTaskCompleted($0) }.count
    }
    
    private var allTasksCompleted: Bool {
        return !todaysTasks.isEmpty && completedTasksCount == todaysTasks.count
    }
    
    // MARK: - Actions
    
    private func completeAllTasks() {
        HapticManager.shared.trigger(.notification(.success))
        todaysTasks.forEach { task in
            if !scheduleViewModel.isTaskCompleted(task) {
                scheduleViewModel.toggleTaskCompletion(task)
            }
        }
    }
    
    private func showFullTaskList() {
        HapticManager.shared.trigger(.impact(.medium))
        // Navigate to full task view
    }
}

// MARK: - Task Row Component

struct TaskRow: View {
    let task: DailyTask
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.sm.value) {
            RemindersStyleCheckbox(
                isCompleted: isCompleted,
                action: onToggle,
                size: .standard,
                style: .task
            )
            
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                Text(task.title)
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(isCompleted ? SemanticColor.secondaryText : SemanticColor.primaryText)
                    .strikethrough(isCompleted)
                
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.tertiaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: task.workoutType.iconName)
                .foregroundColor(task.workoutType.iconColor)
                .font(Typography.captionMedium.font)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

// Quick Action Button for Widget
private struct WidgetQuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs.value) {
                Image(systemName: icon)
                    .font(Typography.captionMedium.font)
                Text(title)
                    .font(Typography.captionMedium.font)
            }
            .foregroundColor(SemanticColor.primaryAction)
        }
        .buttonStyle(.plain)
    }
}