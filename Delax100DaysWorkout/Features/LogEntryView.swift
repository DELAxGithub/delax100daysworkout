import SwiftUI
import UIKit
import OSLog

struct LogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: LogEntryViewModel
    @State private var showingCancelAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

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
                .onChange(of: viewModel.logType) { _, _ in
                    // Reload defaults when switching type and reset baseline
                    viewModel.preloadFromLastEntries()
                    viewModel.captureBaseline()
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
            .onAppear {
                // Autofill from previous data on first load and set baseline
                viewModel.preloadFromLastEntries()
                viewModel.captureBaseline()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.hasChanges {
                            showingCancelAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(viewModel.isSaveDisabled || viewModel.isSaving)
                }
            }
        }
        .alert("変更を破棄しますか？", isPresented: $showingCancelAlert) {
            Button("破棄", role: .destructive) {
                dismiss()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("入力した内容が失われます。")
        }
        .alert("保存エラー", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSave() {
        Task {
            await viewModel.save()
            
            if case .success = viewModel.saveState {
                // ハプティックフィードバック
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
                
                // 少し遅延してから画面を閉じる
                try? await Task.sleep(nanoseconds: 300_000_000)
                dismiss()
            } else if case .error(let message) = viewModel.saveState {
                errorMessage = message
                showingErrorAlert = true
            }
        }
    }
}
