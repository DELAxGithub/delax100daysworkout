import SwiftUI
import SwiftData

struct SettingsView: View {
    @State var viewModel: SettingsViewModel
    @Binding var selectedTab: Int
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isMigratingCounters = false
    @State private var hasInitializationError = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("チャレンジ期間")) {
                    DatePicker("目標日", selection: $viewModel.goalDate, displayedComponents: .date)
                }

                Section(header: Text("体重目標")) {
                    HStack {
                        Text("開始体重")
                        Spacer()
                        TextField("体重", value: $viewModel.startWeightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("目標体重")
                        Spacer()
                        TextField("体重", value: $viewModel.goalWeightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        selectedTab = 0
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func migrateCounters() async {
        isMigratingCounters = true
        
        TaskCounterService.shared.migrateFromHistory(
            startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 1)) ?? Date(),
            in: modelContext
        )
        
        isMigratingCounters = false
    }
    
    private func getAllCounterStats() -> [(taskType: String, counter: TaskCompletionCounter)] {
        return TaskCounterService.shared.getAllCounterStats(in: modelContext)
    }
}