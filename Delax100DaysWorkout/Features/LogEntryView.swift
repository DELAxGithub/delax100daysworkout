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
                Section(header: Text("Weight Details")) {
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("Weight", value: $viewModel.weightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
            default:
                // Temporarily disabled to prevent crashes
                // TODO: Implement proper workout entry in dedicated screens
                Section(header: Text("Coming Soon")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("This feature is being redesigned", systemImage: "hammer.fill")
                            .foregroundColor(.orange)
                        Text("Workout entry will be integrated into the history screens for better context and usability.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("For now, please use the weight entry feature above.")
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
                            Text("Saving...")
                        }
                        .animation(.easeInOut(duration: 0.2), value: isSaving)
                    } else {
                        Text("Save")
                    }
                }
                .disabled(viewModel.isSaveDisabled || isSaving)
            }
        }
        .alert("Discard changes?", isPresented: $showingCancelAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep editing", role: .cancel) { }
        } message: {
            Text("Your changes will be lost.")
        }
        .alert("Saved!", isPresented: $showingSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your data has been saved successfully.")
        }
        .alert("Save Error", isPresented: $showingErrorAlert) {
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