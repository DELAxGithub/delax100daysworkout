import SwiftUI
import SwiftData

struct DailyMetricEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var weightText: String = ""
    @State private var restingHRText: String = ""
    @State private var maxHRText: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("日付") {
                    DatePicker("記録日", selection: $selectedDate, displayedComponents: .date)
                }
                
                Section("体重") {
                    HStack {
                        TextField("例: 70.5", text: $weightText)
                            .keyboardType(.decimalPad)
                        Text("kg")
                    }
                }
                
                Section("心拍数") {
                    HStack {
                        Text("安静時")
                        Spacer()
                        TextField("例: 60", text: $restingHRText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("bpm")
                    }
                    
                    HStack {
                        Text("最大")
                        Spacer()
                        TextField("例: 180", text: $maxHRText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("bpm")
                    }
                }
                
                Section(footer: Text("全ての項目の入力は任意です。必要な項目のみ入力してください。")) {
                    // Empty section for footer text
                }
            }
            .navigationTitle("日次記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMetricRecord()
                    }
                    .disabled(!hasAnyData)
                }
            }
            .alert("入力エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var hasAnyData: Bool {
        !weightText.isEmpty || !restingHRText.isEmpty || !maxHRText.isEmpty
    }
    
    private func saveMetricRecord() {
        var weight: Double? = nil
        var restingHR: Int? = nil
        var maxHR: Int? = nil
        
        // Validate weight
        if !weightText.isEmpty {
            guard let w = Double(weightText), DailyMetric.isValidWeight(w) else {
                alertMessage = "体重は30〜200kgの範囲で入力してください"
                showingAlert = true
                return
            }
            weight = w
        }
        
        // Validate resting heart rate
        if !restingHRText.isEmpty {
            guard let rhr = Int(restingHRText), DailyMetric.isValidRestingHeartRate(rhr) else {
                alertMessage = "安静時心拍数は40〜100bpmの範囲で入力してください"
                showingAlert = true
                return
            }
            restingHR = rhr
        }
        
        // Validate max heart rate
        if !maxHRText.isEmpty {
            guard let mhr = Int(maxHRText), DailyMetric.isValidMaxHeartRate(mhr) else {
                alertMessage = "最大心拍数は120〜220bpmの範囲で入力してください"
                showingAlert = true
                return
            }
            maxHR = mhr
        }
        
        // Check that max HR > resting HR if both are provided
        if let rhr = restingHR, let mhr = maxHR, mhr <= rhr {
            alertMessage = "最大心拍数は安静時心拍数より大きい値を入力してください"
            showingAlert = true
            return
        }
        
        // Check if we already have a record for this date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        
        let existingMetrics = try? modelContext.fetch(
            FetchDescriptor<DailyMetric>(predicate: DailyMetric.sameDayPredicate(for: selectedDate))
        )
        
        if let existingMetric = existingMetrics?.first {
            // Update existing record
            if let weight = weight {
                existingMetric.weightKg = weight
            }
            if let restingHR = restingHR {
                existingMetric.restingHeartRate = restingHR
            }
            if let maxHR = maxHR {
                existingMetric.maxHeartRate = maxHR
            }
            existingMetric.dataSource = .manual
            existingMetric.updatedAt = Date()
        } else {
            // Create new record
            let newRecord = DailyMetric(
                date: startOfDay,
                weightKg: weight,
                restingHeartRate: restingHR,
                maxHeartRate: maxHR,
                dataSource: .manual
            )
            modelContext.insert(newRecord)
        }
        
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
    DailyMetricEntryView()
        .modelContainer(for: [DailyMetric.self])
}