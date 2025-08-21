import SwiftUI
import SwiftData
import OSLog

struct WPRTargetSettingsSheet: View {
    let system: WPRTrackingSystem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTargetWPR: Double
    @State private var selectedDays: Int
    @State private var isCustomTarget: Bool
    @State private var customTargetDate: Date
    
    private let quickTargetOptions: [Double] = [4.0, 4.2, 4.5, 5.0, 5.5]
    private let quickDayOptions: [Int] = [30, 60, 90, 100, 150, 200]
    
    init(system: WPRTrackingSystem) {
        self.system = system
        _selectedTargetWPR = State(initialValue: system.targetWPR)
        _selectedDays = State(initialValue: system.daysToTarget ?? 100)
        _isCustomTarget = State(initialValue: system.isCustomTargetSet)
        _customTargetDate = State(initialValue: system.targetDate ?? Calendar.current.date(byAdding: .day, value: 100, to: Date())!)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 現在の状態
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "gauge")
                                .foregroundColor(.blue)
                            Text("現在の状況")
                                .font(.headline)
                            Spacer()
                        }
                        
                        HStack {
                            Text("現在WPR")
                            Spacer()
                            Text(String(format: "%.2f", system.calculatedWPR))
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("目標達成率")
                            Spacer()
                            Text("\(Int(system.targetProgressRatio * 100))%")
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // 目標WPR設定
                    WPRTargetSelectionCard(
                        selectedTargetWPR: $selectedTargetWPR,
                        targetOptions: quickTargetOptions,
                        currentWPR: system.calculatedWPR
                    )
                    
                    // 期間設定
                    WPRPeriodSelectionCard(
                        selectedDays: $selectedDays,
                        dayOptions: quickDayOptions,
                        isCustomTarget: $isCustomTarget,
                        customTargetDate: $customTargetDate
                    )
                    
                    // 予測結果
                    WPRPredictionResultCard(
                        currentWPR: system.calculatedWPR,
                        targetWPR: selectedTargetWPR,
                        days: selectedDays,
                        isCustomTarget: isCustomTarget
                    )
                }
                .padding()
            }
            .navigationTitle("目標設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                        dismiss()
                    }
                    .disabled(selectedTargetWPR <= system.calculatedWPR)
                }
            }
        }
    }
    
    private func saveSettings() {
        system.targetWPR = selectedTargetWPR
        system.daysToTarget = selectedDays
        system.isCustomTargetSet = isCustomTarget
        system.targetDate = isCustomTarget ? customTargetDate : Calendar.current.date(byAdding: .day, value: selectedDays, to: Date())
        
        do {
            try modelContext.save()
        } catch {
            Logger.error.error("Failed to save goal settings: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Cards

struct WPRTargetSelectionCard: View {
    @Binding var selectedTargetWPR: Double
    let targetOptions: [Double]
    let currentWPR: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                Text("目標WPR")
                    .font(.headline)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(targetOptions, id: \.self) { wpr in
                    TargetOptionCard(
                        wpr: wpr,
                        isSelected: selectedTargetWPR == wpr,
                        isRealistic: wpr <= currentWPR + 1.0
                    )
                    .onTapGesture {
                        selectedTargetWPR = wpr
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct WPRPeriodSelectionCard: View {
    @Binding var selectedDays: Int
    let dayOptions: [Int]
    @Binding var isCustomTarget: Bool
    @Binding var customTargetDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.green)
                Text("達成期間")
                    .font(.headline)
                
                Spacer()
            }
            
            Toggle("カスタム期間", isOn: $isCustomTarget)
            
            if isCustomTarget {
                DatePicker("目標日", selection: $customTargetDate, in: Date()..., displayedComponents: .date)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(dayOptions, id: \.self) { days in
                        DayOptionCard(
                            days: days,
                            isSelected: selectedDays == days
                        )
                        .onTapGesture {
                            selectedDays = days
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct WPRPredictionResultCard: View {
    let currentWPR: Double
    let targetWPR: Double
    let days: Int
    let isCustomTarget: Bool
    
    private var requiredWeeklyGain: Double {
        let totalGain = targetWPR - currentWPR
        let weeks = Double(days) / 7.0
        return totalGain / weeks
    }
    
    private var difficultyLevel: String {
        switch requiredWeeklyGain {
        case 0..<0.02: return "簡単"
        case 0.02..<0.04: return "実現可能"
        case 0.04..<0.06: return "挑戦的"
        case 0.06..<0.08: return "困難"
        default: return "非現実的"
        }
    }
    
    private var difficultyColor: Color {
        switch requiredWeeklyGain {
        case 0..<0.02: return .green
        case 0.02..<0.04: return .blue
        case 0.04..<0.06: return .orange
        case 0.06..<0.08: return .red
        default: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.purple)
                Text("予測結果")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("現在WPR")
                    Spacer()
                    Text(String(format: "%.2f", currentWPR))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("目標WPR")
                    Spacer()
                    Text(String(format: "%.2f", targetWPR))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("必要な週間改善")
                    Spacer()
                    Text("+\(String(format: "%.3f", requiredWeeklyGain))")
                        .fontWeight(.medium)
                        .foregroundColor(difficultyColor)
                }
                
                HStack {
                    Text("難易度")
                    Spacer()
                    Text(difficultyLevel)
                        .fontWeight(.medium)
                        .foregroundColor(difficultyColor)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TargetOptionCard: View {
    let wpr: Double
    let isSelected: Bool
    let isRealistic: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", wpr))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : .primary)
            
            if !isRealistic {
                Text("挑戦的")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .orange)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.blue : Color(.tertiarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct DayOptionCard: View {
    let days: Int
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(days)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : .primary)
            
            Text("日間")
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.green : Color(.tertiarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}