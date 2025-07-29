import SwiftUI

struct LogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: LogEntryViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Log Type", selection: $viewModel.logType) {
                        ForEach(LogType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                }

                switch viewModel.logType {
                case .weight:
                    Section(header: Text("Weight Details")) {
                        HStack {
                            Text("Weight (kg)")
                            Spacer()
                            TextField("Weight", value: $viewModel.weightKg, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                case .cycling:
                    Section(header: Text("Summary")) {
                        TextField("Summary (e.g., 1hr Z2 ride)", text: $viewModel.workoutSummary)
                    }
                    CyclingInputView(
                        distance: $viewModel.cyclingDistance,
                        duration: $viewModel.cyclingDuration,
                        averagePower: $viewModel.cyclingAveragePower,
                        intensity: $viewModel.cyclingIntensity,
                        notes: $viewModel.cyclingNotes
                    )
                    
                case .strength:
                    Section(header: Text("Summary")) {
                        TextField("Summary (e.g., Upper Body Day)", text: $viewModel.workoutSummary)
                    }
                    StrengthInputView(strengthDetails: $viewModel.strengthDetails)
                    
                case .flexibility:
                    Section(header: Text("Summary")) {
                        TextField("Summary (e.g., Morning Stretch)", text: $viewModel.workoutSummary)
                    }
                    FlexibilityInputView(
                        forwardBendDistance: $viewModel.flexibilityForwardBend,
                        leftSplitAngle: $viewModel.flexibilityLeftSplit,
                        rightSplitAngle: $viewModel.flexibilityRightSplit,
                        duration: $viewModel.flexibilityDuration,
                        notes: $viewModel.flexibilityNotes
                    )
                }
            }
            .navigationTitle("New Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(viewModel.isSaveDisabled)
                }
            }
        }
    }
}