import SwiftUI
import SwiftData

struct FTPEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var ftpValue: String = ""
    @State private var selectedMethod: FTPMeasurementMethod = .manual
    @State private var notes: String = ""
    @State private var selectedDate = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("FTP記録") {
                    HStack {
                        Text("FTP値")
                        Spacer()
                        TextField("例: 250", text: $ftpValue)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("W")
                    }
                    
                    DatePicker("記録日", selection: $selectedDate, displayedComponents: .date)
                    
                    Picker("測定方法", selection: $selectedMethod) {
                        ForEach(FTPMeasurementMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    
                    TextField("メモ（任意）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("測定方法について") {
                    Text(selectedMethod.description)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .navigationTitle("FTP記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveFTPRecord()
                    }
                    .disabled(!isValidInput)
                }
            }
            .alert("入力エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isValidInput: Bool {
        guard let ftp = Int(ftpValue) else { return false }
        return FTPHistory.isValidFTP(ftp)
    }
    
    private func saveFTPRecord() {
        guard let ftp = Int(ftpValue) else {
            alertMessage = "FTP値は数値で入力してください"
            showingAlert = true
            return
        }
        
        guard FTPHistory.isValidFTP(ftp) else {
            alertMessage = "FTP値は50W〜500Wの範囲で入力してください"
            showingAlert = true
            return
        }
        
        let newRecord = FTPHistory(
            date: selectedDate,
            ftpValue: ftp,
            measurementMethod: selectedMethod,
            notes: notes.isEmpty ? nil : notes,
            isAutoCalculated: selectedMethod == .autoCalculated
        )
        
        modelContext.insert(newRecord)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "保存に失敗しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    FTPEntryView()
        .modelContainer(for: [FTPHistory.self])
}