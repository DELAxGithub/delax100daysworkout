import SwiftUI
import SwiftData

// MARK: - Workout History Edit Sheet

struct WorkoutHistoryEditSheet: View {
    let workout: WorkoutRecord
    let onSave: (WorkoutRecord) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var editedSummary: String = ""
    @State private var editedWorkoutType: WorkoutType = .cycling
    @State private var editedDate: Date = Date()
    @State private var editedIsCompleted: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("ワークアウト名", text: $editedSummary)
                    
                    Picker("種類", selection: $editedWorkoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    
                    DatePicker("日時", selection: $editedDate)
                    
                    Toggle("完了済み", isOn: $editedIsCompleted)
                }
                
                Section {
                    Text("※ 詳細編集は元のワークアウト編集画面をご利用ください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("ワークアウト編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let editedWorkout = WorkoutRecord(
                            date: editedDate,
                            workoutType: editedWorkoutType,
                            summary: editedSummary
                        )
                        editedWorkout.isCompleted = editedIsCompleted
                        onSave(editedWorkout)
                        dismiss()
                    }
                    .disabled(editedSummary.isEmpty)
                }
            }
        }
        .onAppear {
            editedSummary = workout.summary
            editedWorkoutType = workout.workoutType
            editedDate = workout.date
            editedIsCompleted = workout.isCompleted
        }
    }
}