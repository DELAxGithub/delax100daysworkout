import SwiftUI
import UIKit

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
                        if viewModel.hasChanges {
                            showingCancelAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        Task {
                            print("📱 Saveボタンが押されました")
                            await viewModel.save()
                            
                            print("📱 保存処理完了。状態: \(viewModel.saveState)")
                            
                            // 保存成功時の処理
                            if case .success = viewModel.saveState {
                                print("🎉 保存成功 - ハプティックフィードバック実行")
                                // ハプティックフィードバック
                                await MainActor.run {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.prepare()
                                    impactFeedback.impactOccurred()
                                }
                                
                                // 少し遅延してから画面を閉じる
                                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                                print("📱 画面を閉じます")
                                dismiss()
                            } else if case .error(let message) = viewModel.saveState {
                                print("❌ 保存エラーが発生: \(message)")
                                errorMessage = message
                                showingErrorAlert = true
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if viewModel.isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(viewModel.isSaving ? "保存中..." : "Save")
                        }
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isSaving)
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
}