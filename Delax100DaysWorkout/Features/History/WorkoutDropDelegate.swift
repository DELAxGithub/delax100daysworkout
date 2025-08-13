import SwiftUI
import OSLog

// MARK: - Workout Drop Delegate

struct WorkoutDropDelegate: DropDelegate {
    let workout: WorkoutRecord
    let onMove: (WorkoutRecord, WorkoutRecord) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        
        itemProvider.loadObject(ofClass: NSString.self) { (data, error) in
            guard let draggedData = data as? String,
                  draggedData.hasPrefix("workout:") else {
                return
            }
            
            let draggedWorkoutIdString = String(draggedData.dropFirst(8))
            Logger.debug.debug("Dragged workout ID: \(draggedWorkoutIdString)")
            
            DispatchQueue.main.async {
                // Find the dragged workout by ID and call move callback
                // The actual implementation will be handled by the parent view
                // This is a placeholder that triggers the move action
                onMove(workout, workout) // Target workout
                HapticManager.shared.trigger(.impact(.light))
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        HapticManager.shared.trigger(.selection)
    }
}