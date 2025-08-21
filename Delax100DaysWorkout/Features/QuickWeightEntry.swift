import SwiftUI
import SwiftData
import UIKit

struct QuickWeightEntry: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var weightInput: String = ""
    @State private var isSaving = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var weightValue: Double {
        Double(weightInput) ?? 0.0
    }
    
    private var isValidWeight: Bool {
        weightValue > 0 && weightValue < 500 // 現実的な体重範囲
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                TextField("体重を入力", text: $weightInput)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                
                Text("kg")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Button(action: handleSave) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                .disabled(!isValidWeight || isSaving)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .onAppear {
            loadLastWeight()
        }
        .alert("保存完了！", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text("体重を記録しました: \(String(format: "%.1f", weightValue))kg")
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadLastWeight() {
        // Load the most recent weight for convenience
        let descriptor = FetchDescriptor<DailyMetric>(
            sortBy: [SortDescriptor(\DailyMetric.date, order: .reverse)]
        )
        
        if let lastMetric = try? modelContext.fetch(descriptor).first,
           let lastWeight = lastMetric.weightKg {
            weightInput = String(format: "%.1f", lastWeight)
        }
    }
    
    private func handleSave() {
        guard isValidWeight else { return }
        
        isSaving = true
        
        Task {
            do {
                let roundedWeight = round(weightValue * 10) / 10
                let today = Calendar.current.startOfDay(for: Date())
                
                // Check for existing entry today
                let predicate = DailyMetric.sameDayPredicate(for: today)
                let descriptor = FetchDescriptor<DailyMetric>(predicate: predicate)
                
                let existingMetrics = try modelContext.fetch(descriptor)
                
                if let existingMetric = existingMetrics.first {
                    // Update existing metric
                    existingMetric.weightKg = roundedWeight
                    existingMetric.dataSource = .manual
                    existingMetric.updatedAt = Date()
                } else {
                    // Create new metric
                    let newMetric = DailyMetric(
                        date: today,
                        weightKg: roundedWeight,
                        dataSource: .manual
                    )
                    modelContext.insert(newMetric)
                }
                
                try modelContext.save()
                
                await MainActor.run {
                    isSaving = false
                    showingSuccess = true
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                    
                    // Clear input for next entry
                    weightInput = ""
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    QuickWeightEntry()
        .modelContainer(for: [DailyMetric.self])
        .padding()
}