import SwiftUI

struct TaskCardView: View {
    let task: DailyTask
    let onQuickComplete: () -> Void
    let onDetailTap: () -> Void
    
    @State private var isCompleted = false
    @State private var showCheckmark = false
    
    var body: some View {
        BaseCard.task(
            isCompleted: isCompleted,
            onTap: onDetailTap,
            onLongPress: onQuickComplete
        ) {
            VStack(alignment: .leading, spacing: Spacing.cardSpacing.value) {
            // ヘッダー
            HStack {
                Image(systemName: task.icon)
                    .font(Typography.headlineMedium.font)
                    .foregroundColor(SemanticColor.primaryAction)
                
                Text(task.title)
                    .font(Typography.headlineMedium.font)
                    .foregroundColor(SemanticColor.primaryText)
                
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
                    
                    withAnimation {
                        isCompleted = true
                        showCheckmark = true
                    }
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
                    .background(isCompleted ? SemanticColor.successAction : SemanticColor.primaryAction)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.large)
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
                    .cornerRadius(CornerRadius.large)
                }
                .disabled(isCompleted)
                
                Spacer()
            }
            }
        }
    }
}