import SwiftUI
import SwiftData
import UIKit
import OSLog

struct LogEntryView: View {
    @State private var viewModel: LogEntryViewModel
    @Environment(\.dismiss) private var dismiss
    
    // State management
    @State private var isSaving = false
    @State private var showingSaveSuccess = false
    @State private var showingCancelAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    init(viewModel: LogEntryViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            // Type and Date Selection
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

            // Content based on selected log type
            // NOTE: Only weight is currently supported. Other types cause crashes.
            switch viewModel.logType {
            case .weight:
                Section(header: Text("体重詳細")) {
                    HStack {
                        Text("体重 (kg)")
                        Spacer()
                        TextField("Weight", value: $viewModel.weightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
            default:
                // Temporarily disabled to prevent crashes
                // TODO: Implement proper workout entry in dedicated screens
                Section(header: Text("近日公開")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("この機能は再設計中です", systemImage: "hammer.fill")
                            .foregroundColor(.orange)
                        Text("ワークアウト入力は履歴画面に統合され、より良いコンテキストと使いやすさを提供します。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("現在は上記の体重入力機能をご利用ください。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("New Log Entry")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Autofill from previous data on first load and set baseline
            viewModel.preloadFromLastEntries()
            viewModel.captureBaseline()
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            hideKeyboard()
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
                .disabled(isSaving)
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(action: handleSave) {
                    if isSaving {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            Text("保存中...")
                        }
                        .animation(.easeInOut(duration: 0.2), value: isSaving)
                    } else {
                        Text("保存")
                    }
                }
                .disabled(viewModel.isSaveDisabled || isSaving)
            }
        }
        .alert("変更を破棄しますか？", isPresented: $showingCancelAlert) {
            Button("破棄", role: .destructive) {
                dismiss()
            }
            Button("編集続行", role: .cancel) { }
        } message: {
            Text("変更内容が失われます。")
        }
        .alert("保存完了！", isPresented: $showingSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("データが正常に保存されました。")
        }
        .alert("保存エラー", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func handleSave() {
        guard !viewModel.isSaveDisabled else { return }
        
        isSaving = true
        
        Task {
            await viewModel.save()
            
            await MainActor.run {
                isSaving = false
                
                if case .success = viewModel.saveState {
                    Logger.database.info("✅ Save successful")
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                    
                    showingSaveSuccess = true
                    
                } else if case .error(let message) = viewModel.saveState {
                    Logger.error.error("❌ Save error: \(message)")
                    errorMessage = message
                    showingErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var previewModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutRecord.self,
            DailyMetric.self,
            DailyLog.self,
            CyclingDetail.self,
            StrengthDetail.self,
            FlexibilityDetail.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Preview ModelContainer creation failed: \(error)")
        }
    }()
    
    NavigationStack {
        LogEntryView(viewModel: LogEntryViewModel(modelContext: previewModelContainer.mainContext))
    }
}