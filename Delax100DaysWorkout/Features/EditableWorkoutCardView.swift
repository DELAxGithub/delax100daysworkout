import SwiftUI

struct EditableWorkoutCardView: View {
    let workout: WorkoutRecord
    let onEdit: (WorkoutRecord) -> Void
    let onDelete: (WorkoutRecord) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var showingDeleteButton = false
    @State private var showingEditSheet = false
    
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // 削除ボタン（背景）
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingDeleteButton = false
                        dragOffset = .zero
                    }
                    onDelete(workout)
                }) {
                    VStack {
                        Image(systemName: "trash")
                            .font(.title2)
                        Text("削除")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
            }
            
            // メインカード
            HStack(spacing: 16) {
                Image(systemName: workout.workoutType.iconName)
                    .font(.title)
                    .foregroundColor(workout.workoutType.iconColor)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.workoutType.rawValue)
                        .font(.headline)
                    
                    Text(workout.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(formatTime(workout.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if workout.isCompleted {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                // 編集インジケーター
                if showingDeleteButton {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .offset(x: dragOffset.width)
            .scaleEffect(showingDeleteButton ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: showingDeleteButton)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.width
                    
                    // 左スワイプのみ許可
                    if translation < 0 {
                        dragOffset.width = max(translation, -deleteButtonWidth)
                        showingDeleteButton = dragOffset.width < -30
                    }
                }
                .onEnded { value in
                    let translation = value.translation.width
                    let velocity = value.velocity.width
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        if translation < -40 || velocity < -500 {
                            // 削除ボタンを表示
                            dragOffset.width = -deleteButtonWidth
                            showingDeleteButton = true
                        } else {
                            // 元の位置に戻す
                            dragOffset.width = 0
                            showingDeleteButton = false
                        }
                    }
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    // 長押しで編集画面を表示
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    showingEditSheet = true
                }
        )
        .onTapGesture {
            // タップで削除ボタンを隠す
            if showingDeleteButton {
                withAnimation(.easeOut(duration: 0.3)) {
                    dragOffset.width = 0
                    showingDeleteButton = false
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            WorkoutEditSheet(
                workout: workout,
                onSave: { editedWorkout in
                    onEdit(editedWorkout)
                    showingEditSheet = false
                },
                onCancel: {
                    showingEditSheet = false
                }
            )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        EditableWorkoutCardView(
            workout: WorkoutRecord(
                date: Date(),
                workoutType: .cycling,
                summary: "45分 SST ライド"
            ),
            onEdit: { _ in },
            onDelete: { _ in }
        )
        
        EditableWorkoutCardView(
            workout: {
                let record = WorkoutRecord(
                    date: Date().addingTimeInterval(-3600),
                    workoutType: .strength,
                    summary: "Push筋トレ 3セット"
                )
                record.markAsCompleted()
                return record
            }(),
            onEdit: { _ in },
            onDelete: { _ in }
        )
        
        EditableWorkoutCardView(
            workout: WorkoutRecord(
                date: Date().addingTimeInterval(-7200),
                workoutType: .flexibility,
                summary: "朝の柔軟 20分"
            ),
            onEdit: { _ in },
            onDelete: { _ in }
        )
    }
    .padding()
}