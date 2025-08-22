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
    @Environment(\.modelContext) private var modelContext
    @Query private var workoutRecords: [WorkoutRecord]
    
    private var workoutDetailText: String? {
        switch workout.workoutType {
        case .strength:
            if let strengthData = workout.strengthData {
                let periodCount = WorkoutRecord.countStrengthInPeriod(
                    records: workoutRecords,
                    muscleGroup: strengthData.muscleGroup,
                    startDate: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                )
                return "\(strengthData.muscleGroup.displayName) \(Int(strengthData.weight))kg×\(strengthData.reps)×\(strengthData.sets)セット (今週\(periodCount)回目)"
            }
            
        case .cycling:
            if let cyclingData = workout.cyclingData {
                let periodCount = WorkoutRecord.countCyclingZoneInPeriod(
                    records: workoutRecords,
                    zone: cyclingData.zone,
                    startDate: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                )
                var details = "\(cyclingData.zone.shortDisplayName) \(cyclingData.duration)分"
                if let power = cyclingData.power {
                    details += " \(power)W"
                }
                details += " (今週\(periodCount)回目)"
                return details
            }
            
        case .flexibility:
            if let flexibilityData = workout.flexibilityData {
                let periodCount = WorkoutRecord.countFlexibilityTypeInPeriod(
                    records: workoutRecords,
                    type: flexibilityData.type,
                    startDate: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                )
                var details = "\(flexibilityData.type.displayName) \(flexibilityData.duration)分"
                if let measurement = flexibilityData.measurement {
                    details += " \(Int(measurement))cm"
                }
                details += " (今週\(periodCount)回目)"
                return details
            }
            
        case .pilates, .yoga:
            // これらは現在flexibilityに移行されている
            break
        }
        
        return nil
    }
    
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
                        
                        // 詳細情報の表示
                        if let detailText = workoutDetailText {
                            Text(detailText)
                                .font(Typography.captionSmall.font)
                                .foregroundColor(SemanticColor.secondaryText)
                                .lineLimit(1)
                        } else {
                            Text(workout.workoutType.rawValue)
                                .font(Typography.captionMedium.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
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
            WorkoutHistoryEditSheet(
                workout: workout,
                onSave: { _ in
                    showingEditSheet = false
                }
            )
        }
    }
}