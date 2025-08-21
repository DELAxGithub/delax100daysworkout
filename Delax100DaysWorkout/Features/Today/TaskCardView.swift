import SwiftUI
import SwiftData

struct TaskCardView: View {
    let task: DailyTask
    let onQuickComplete: () -> Void
    let onDetailTap: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var isCompleted = false
    @State private var showCheckmark = false
    @State private var counterInfo: TaskCompletionCounter?
    
    var body: some View {
        BaseCard(
            onTap: onDetailTap,
            onLongPress: onQuickComplete
        ) {
            VStack(alignment: .leading, spacing: Spacing.cardSpacing.value) {
            // ヘッダー
            HStack {
                Image(systemName: task.icon)
                    .font(Typography.headlineMedium.font)
                    .foregroundColor(SemanticColor.primaryAction.color)
                
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    Text(task.title)
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    if let counter = counterInfo {
                        Text(counter.displayText)
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                    }
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.successAction)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCheckmark)
                }
            }
            
            // 説明
            if let description = task.taskDescription {
                Text(description)
                    .font(Typography.bodySmall.font)
                    .foregroundColor(SemanticColor.secondaryText)
            }
            
            // 目標進捗表示
            if let counter = counterInfo {
                HStack {
                    Text(counter.progressText)
                        .font(Typography.captionMedium.font)
                        .foregroundColor(counter.isTargetAchieved ? SemanticColor.successAction : SemanticColor.secondaryText)
                    
                    Spacer()
                    
                    // 目標達成時の「おかわり」ボタン
                    if counter.isTargetAchieved && !isCompleted {
                        Button("おかわり +50") {
                            // TaskCounterService removed
                            loadCounterInfo()
                        }
                        .font(Typography.captionMedium.font)
                        .padding(.horizontal, Spacing.sm.value)
                        .padding(.vertical, 2)
                        .background(SemanticColor.successAction.color.opacity(0.2))
                        .foregroundColor(SemanticColor.successAction.color)
                        .cornerRadius(CornerRadius.small.radius)
                    }
                }
                
                // プログレスバー
                if !counter.isTargetAchieved {
                    ProgressView(value: counter.progressRate)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                        .accentColor(SemanticColor.primaryAction.color)
                }
            }
            
            // 目標値
            if let targetDetails = task.targetDetails {
                HStack(spacing: Spacing.md.value) {
                    if task.workoutType == .cycling {
                        if let duration = targetDetails.duration {
                            Label("\(duration)分", systemImage: "clock")
                                .font(Typography.captionMedium.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                        if let power = targetDetails.targetPower {
                            Label("\(power)W", systemImage: "bolt")
                                .font(Typography.captionMedium.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    } else if task.workoutType == .strength {
                        if let sets = targetDetails.targetSets,
                           let reps = targetDetails.targetReps {
                            Label("\(sets)セット×\(reps)レップ", systemImage: "number")
                                .font(Typography.captionMedium.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    } else if task.workoutType == .flexibility {
                        if let duration = targetDetails.targetDuration {
                            Label("\(duration)分", systemImage: "clock")
                                .font(Typography.captionMedium.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                }
            }
            
            // アクションボタン
            HStack(spacing: Spacing.listItemSpacing.value) {
                Button(action: {
                    // バグ報告のトラッキング
                    BugReportManager.shared.trackButtonTap("やった", in: "TaskCardView")
                    
                    // カウンターを更新
                    TaskCounterService.shared.incrementCounter(for: task, in: modelContext)
                    
                    withAnimation {
                        isCompleted = true
                        showCheckmark = true
                    }
                    
                    // カウンター情報を更新
                    loadCounterInfo()
                    
                    // 少し遅延してからコールバック実行
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onQuickComplete()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("やった")
                    }
                    .font(Typography.labelMedium.font)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.md.value)
                    .padding(.vertical, Spacing.sm.value)
                    .background(isCompleted ? SemanticColor.successAction.color : SemanticColor.primaryAction.color)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.large.radius)
                }
                .disabled(isCompleted)
                
                Button(action: {
                    BugReportManager.shared.trackButtonTap("詳細入力", in: "TaskCardView")
                    onDetailTap()
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("詳細入力")
                    }
                    .font(Typography.labelMedium.font)
                    .padding(.horizontal, Spacing.md.value)
                    .padding(.vertical, Spacing.sm.value)
                    .background(SemanticColor.secondaryAction.color.opacity(0.2))
                    .foregroundColor(SemanticColor.primaryText)
                    .cornerRadius(CornerRadius.large.radius)
                }
                .disabled(isCompleted)
                
                Spacer()
            }
            }
        }
        .onAppear {
            loadCounterInfo()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCounterInfo() {
        Task {
            await MainActor.run {
                counterInfo = TaskCounterService.shared.getCounterInfo(for: task, in: modelContext)
            }
        }
    }
}