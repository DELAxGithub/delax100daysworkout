import SwiftUI
import SwiftData
import OSLog

// MARK: - Draggable Workout History Row

struct DraggableWorkoutHistoryRow: View {
    let workout: WorkoutRecord
    let isEditMode: Bool
    let isSelected: Bool
    let onEdit: (WorkoutRecord) -> Void
    let onDelete: (WorkoutRecord) -> Void
    let onSelect: (Bool) -> Void
    let onMove: ((WorkoutRecord, WorkoutRecord) -> Void)?
    
    @State private var isDragging = false
    
    var body: some View {
        if isEditMode {
            // No drag in edit mode for safety
            WorkoutHistoryRow(
                workout: workout,
                isEditMode: isEditMode,
                isSelected: isSelected,
                onEdit: onEdit,
                onDelete: onDelete,
                onSelect: onSelect
            )
        } else {
            DraggableContainer(
                onDragStart: {
                    isDragging = true
                    HapticManager.shared.trigger(.impact(.medium))
                },
                onDragEnd: {
                    isDragging = false
                },
                dragData: {
                    // Create drag data with workout ID
                    let workoutData = "workout:\(workout.id)"
                    return NSItemProvider(object: workoutData as NSString)
                }
            ) {
                WorkoutHistoryRow(
                    workout: workout,
                    isEditMode: isEditMode,
                    isSelected: isSelected,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onSelect: onSelect
                )
            }
            .opacity(isDragging ? 0.6 : 1.0)
            .onDrop(of: [.text], delegate: WorkoutDropDelegate(
                workout: workout,
                onMove: onMove ?? { _, _ in }
            ))
        }
    }
}