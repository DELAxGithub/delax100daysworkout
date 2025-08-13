import SwiftUI
import SwiftData

struct FTPEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let ftpRecord: FTPHistory
    
    @State private var ftpValue: Int = 0
    @State private var selectedMethod: FTPMeasurementMethod = .manual
    @State private var notes: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showingDeleteAlert = false
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg.value) {
                    // Edit Form
                    BaseCard(style: ElevatedCardStyle()) {
                        VStack(spacing: Spacing.md.value) {
                            // FTP Value Input
                            NumericInputRow(
                                label: "FTP値",
                                value: $ftpValue,
                                unit: "W",
                                placeholder: "250"
                            )
                            
                            Divider()
                            
                            // Date Picker
                            DatePicker(
                                "記録日",
                                selection: $selectedDate,
                                displayedComponents: .date
                            )
                            .font(Typography.bodyLarge.font)
                            .foregroundColor(SemanticColor.primaryText.color)
                            .frame(minHeight: 44)
                            
                            Divider()
                            
                            // Measurement Method Picker
                            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                                Text("測定方法")
                                    .font(Typography.bodyLarge.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                
                                Picker("測定方法", selection: $selectedMethod) {
                                    ForEach(FTPMeasurementMethod.allCases, id: \.self) { method in
                                        Text(method.displayName)
                                            .tag(method)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(minHeight: 44)
                            }
                            
                            Divider()
                            
                            // Notes Input
                            TextInputRow(
                                label: "メモ",
                                text: $notes,
                                placeholder: "例: 体調良好、パワーメーター校正済み"
                            )
                        }
                        .padding(Spacing.md.value)
                    }
                    
                    // Delete Button
                    BaseCard(style: OutlinedCardStyle()) {
                        Button(action: {
                            showingDeleteAlert = true
                            HapticManager.shared.trigger(.notification(.warning))
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(SemanticColor.destructiveAction.color)
                                Text("この記録を削除")
                                    .font(Typography.labelMedium.font)
                                    .foregroundColor(SemanticColor.destructiveAction.color)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md.value)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(SemanticColor.primaryBackground.color)
            .navigationTitle("FTP記録編集")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                        HapticManager.shared.trigger(.selection)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                }
            }
        }
        .onAppear {
            loadRecordData()
        }
        .alert("FTP記録を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteRecord()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この記録を削除してもよろしいですか？この操作は取り消せません。")
        }
        .alert("入力エラー", isPresented: $showingValidationError) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
    }
    
    private var isValidInput: Bool {
        return FTPHistory.isValidFTP(ftpValue) && selectedDate <= Date()
    }
    
    private func loadRecordData() {
        ftpValue = ftpRecord.ftpValue
        selectedMethod = ftpRecord.measurementMethod
        notes = ftpRecord.notes ?? ""
        selectedDate = ftpRecord.date
    }
    
    private func saveChanges() {
        guard isValidInput else {
            validationMessage = "FTP値は50〜500Wの範囲で入力し、記録日は今日以前を選択してください。"
            showingValidationError = true
            return
        }
        
        // Update the record
        ftpRecord.ftpValue = ftpValue
        ftpRecord.measurementMethod = selectedMethod
        ftpRecord.notes = notes.isEmpty ? nil : notes
        ftpRecord.date = selectedDate
        
        do {
            try modelContext.save()
            
            // Trigger WPR update if this is the most recent FTP
            Task { @MainActor in
                ftpRecord.triggerWPRFTPUpdate(context: modelContext)
            }
            
            HapticManager.shared.trigger(.notification(.success))
            dismiss()
        } catch {
            validationMessage = "保存中にエラーが発生しました: \(error.localizedDescription)"
            showingValidationError = true
        }
    }
    
    private func deleteRecord() {
        withAnimation {
            modelContext.delete(ftpRecord)
            do {
                try modelContext.save()
                HapticManager.shared.trigger(.notification(.success))
                dismiss()
            } catch {
                validationMessage = "削除中にエラーが発生しました: \(error.localizedDescription)"
                showingValidationError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        FTPEditSheet(ftpRecord: FTPHistory.sample)
    }
    .modelContainer(for: [FTPHistory.self])
}