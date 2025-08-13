import SwiftUI
import SwiftData

// MARK: - Workout History Row

struct WorkoutHistoryRow: View {
    let workout: WorkoutRecord
    let isEditMode: Bool
    let isSelected: Bool
    let onEdit: (WorkoutRecord) -> Void
    let onDelete: (WorkoutRecord) -> Void
    let onSelect: (Bool) -> Void
    
    @State private var showingEditSheet = false
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                HStack {
                    // 編集モードでの選択チェックボックス
                    if isEditMode {
                        Button(action: {
                            onSelect(!isSelected)
                        }) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? SemanticColor.primaryAction : SemanticColor.secondaryText)
                                .font(Typography.headlineSmall.font)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Image(systemName: workout.workoutType.iconName)
                        .foregroundColor(workout.workoutType.iconColor)
                        .font(Typography.headlineSmall.font)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs.value) {
                        Text(workout.summary)
                            .font(Typography.headlineMedium.font)
                            .foregroundColor(SemanticColor.primaryText)
                            .lineLimit(2)
                        
                        Text(workout.workoutType.rawValue)
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: Spacing.xs.value) {
                        Text(workout.date, format: .dateTime.month().day().hour().minute())
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                        
                        if workout.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(SemanticColor.successAction)
                                .font(Typography.captionMedium.font)
                        }
                        
                        if workout.isQuickRecord {
                            Text("クイック記録")
                                .font(Typography.captionSmall.font)
                                .padding(.horizontal, Spacing.xs.value)
                                .padding(.vertical, Spacing.xs.value)
                                .background(SemanticColor.primaryAction.color.opacity(0.1))
                                .cornerRadius(CornerRadius.small.radius)
                                .foregroundColor(SemanticColor.primaryAction)
                        }
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xs.value)
        .contentShape(Rectangle())
        .onLongPressGesture {
            if !isEditMode {
                showingEditSheet = true
            }
        }
        .onTapGesture {
            if isEditMode {
                onSelect(!isSelected)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !isEditMode {
                Button("編集") {
                    showingEditSheet = true
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isEditMode {
                Button("削除", role: .destructive) {
                    onDelete(workout)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            WorkoutEditSheet(workoutRecord: workout)
        }
    }
}