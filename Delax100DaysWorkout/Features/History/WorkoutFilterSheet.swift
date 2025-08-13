import SwiftUI

// MARK: - Filter Sheet

struct WorkoutFilterSheet: View {
    @Binding var selectedWorkoutType: WorkoutType?
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("ワークアウト種類") {
                    Picker("種類フィルター", selection: $selectedWorkoutType) {
                        Text("全て").tag(WorkoutType?.none)
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(WorkoutType?.some(type))
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("期間") {
                    DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                    DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                }
                
                Section {
                    Button("フィルターをリセット") {
                        selectedWorkoutType = nil
                        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                        endDate = Date()
                    }
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}