import SwiftUI
import SwiftData

// MARK: - Generic CRUD Model View Wrapper

struct GenericCRUDModelView: View {
    let editableModel: EditableModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            switch editableModel {
            case .workoutRecords:
                GenericCRUDView(
                    modelType: WorkoutRecord.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .ftpHistory:
                GenericCRUDView(
                    modelType: FTPHistory.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .dailyMetrics:
                GenericCRUDView(
                    modelType: DailyMetric.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .dailyTasks:
                GenericCRUDView(
                    modelType: DailyTask.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .weeklyTemplates:
                GenericCRUDView(
                    modelType: WeeklyTemplate.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .userProfiles:
                GenericCRUDView(
                    modelType: UserProfile.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
    }
}