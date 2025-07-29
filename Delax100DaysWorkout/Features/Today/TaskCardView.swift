import SwiftUI

struct TaskCardView: View {
    let task: DailyTask
    let onQuickComplete: () -> Void
    let onDetailTap: () -> Void
    
    @State private var isCompleted = false
    @State private var showCheckmark = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Image(systemName: task.icon)
                    .font(.title2)
                    .foregroundColor(task.workoutType.iconColor)
                
                Text(task.title)
                    .font(.headline)
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCheckmark)
                }
            }
            
            // 説明
            if let description = task.taskDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 目標値
            if let targetDetails = task.targetDetails {
                HStack(spacing: 16) {
                    if task.workoutType == .cycling {
                        if let duration = targetDetails.duration {
                            Label("\(duration)分", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let power = targetDetails.targetPower {
                            Label("\(power)W", systemImage: "bolt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if task.workoutType == .strength {
                        if let sets = targetDetails.targetSets,
                           let reps = targetDetails.targetReps {
                            Label("\(sets)セット×\(reps)レップ", systemImage: "number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if task.workoutType == .flexibility {
                        if let duration = targetDetails.targetDuration {
                            Label("\(duration)分", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // アクションボタン
            HStack(spacing: 12) {
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isCompleted ? Color.green : task.workoutType.iconColor)
                    .foregroundColor(.white)
                    .cornerRadius(20)
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
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(20)
                }
                .disabled(isCompleted)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}