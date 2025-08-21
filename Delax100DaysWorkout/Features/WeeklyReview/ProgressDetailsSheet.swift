import SwiftUI
import SwiftData
import Charts

struct ProgressDetailsSheet: View {
    let records: [WorkoutRecord]
    let template: WeeklyTemplate
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTimeframe: TimeFrame = .fourWeeks
    @State private var selectedWorkoutType: WorkoutType? = nil
    
    enum TimeFrame: String, CaseIterable {
        case oneWeek = "1週間"
        case twoWeeks = "2週間"
        case fourWeeks = "4週間"
        
        var days: Int {
            switch self {
            case .oneWeek: return 7
            case .twoWeeks: return 14
            case .fourWeeks: return 28
            }
        }
    }
    
    var filteredRecords: [WorkoutRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeframe.days, to: Date()) ?? Date()
        var filtered = records.filter { $0.date >= cutoffDate }
        
        if let selectedType = selectedWorkoutType {
            filtered = filtered.filter { $0.workoutType == selectedType }
        }
        
        return filtered.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    controlsSection
                    
                    overviewSection
                    
                    chartsSection
                    
                    achievementsSection
                    
                    detailedStatsSection
                }
                .padding()
            }
            .navigationTitle("詳細進捗")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            // 期間選択
            Picker("期間", selection: $selectedTimeframe) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
            
            // ワークアウトタイプフィルター
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "すべて",
                        isSelected: selectedWorkoutType == nil
                    ) {
                        selectedWorkoutType = nil
                    }
                    
                    FilterChip(
                        title: "サイクリング",
                        isSelected: selectedWorkoutType == .cycling
                    ) {
                        selectedWorkoutType = .cycling
                    }
                    
                    FilterChip(
                        title: "筋トレ",
                        isSelected: selectedWorkoutType == .strength
                    ) {
                        selectedWorkoutType = .strength
                    }
                    
                    FilterChip(
                        title: "柔軟性",
                        isSelected: selectedWorkoutType == .flexibility
                    ) {
                        selectedWorkoutType = .flexibility
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var overviewSection: some View {
        let analyzer = ProgressAnalyzer(modelContext: modelContext)
        let progress = analyzer.analyzeProgress(records: filteredRecords)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("概要")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "総ワークアウト",
                    value: "\(filteredRecords.count)",
                    subtitle: "回",
                    color: .blue
                )
                
                MetricCard(
                    title: "完了率",
                    value: "\(Int(Double(filteredRecords.filter { $0.isCompleted }.count) / Double(max(filteredRecords.count, 1)) * 100))",
                    subtitle: "%",
                    color: .green
                )
                
                MetricCard(
                    title: "現在のストリーク",
                    value: "\(progress.currentStreak)",
                    subtitle: "日",
                    color: .orange
                )
                
                MetricCard(
                    title: "最長ストリーク",
                    value: "\(progress.longestStreak)",
                    subtitle: "日",
                    color: .purple
                )
            }
        }
    }
    
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("トレンド")
                .font(.headline)
            
            if !filteredRecords.isEmpty {
                workoutFrequencyChart
                
                if selectedWorkoutType == .cycling || selectedWorkoutType == nil {
                    cyclingProgressChart
                }
                
                if selectedWorkoutType == .strength || selectedWorkoutType == nil {
                    strengthProgressChart
                }
                
                if selectedWorkoutType == .flexibility || selectedWorkoutType == nil {
                    flexibilityProgressChart
                }
            } else {
                Text("選択した期間にデータがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private var workoutFrequencyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ワークアウト頻度")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Chart {
                ForEach(dailyWorkoutCounts, id: \.date) { item in
                    BarMark(
                        x: .value("日付", item.date),
                        y: .value("回数", item.count)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 150)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var cyclingProgressChart: some View {
        let cyclingRecords = filteredRecords.filter { $0.workoutType == .cycling }
        let powerData = cyclingRecords.compactMap { record -> (Date, Double)? in
            guard let power = record.cyclingData?.power else { return nil }
            return (record.date, Double(power))
        }
        
        guard !powerData.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("平均パワー推移")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Chart {
                    ForEach(Array(powerData.enumerated()), id: \.0) { (index, item) in
                        LineMark(
                            x: .value("日付", item.0),
                            y: .value("パワー", item.1)
                        )
                        .foregroundStyle(.green)
                        .symbol(.circle)
                    }
                }
                .frame(height: 150)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        )
    }
    
    private var strengthProgressChart: some View {
        let strengthRecords = filteredRecords.filter { $0.workoutType == .strength }
        let volumeData = strengthRecords.compactMap { record -> (Date, Double)? in
            guard let data = record.strengthData else { return nil }
            let totalVolume = data.weight * Double(data.sets * data.reps)
            return (record.date, totalVolume)
        }
        
        guard !volumeData.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("総負荷量推移")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Chart {
                    ForEach(Array(volumeData.enumerated()), id: \.0) { (index, item) in
                        LineMark(
                            x: .value("日付", item.0),
                            y: .value("負荷量", item.1)
                        )
                        .foregroundStyle(.red)
                        .symbol(.square)
                    }
                }
                .frame(height: 150)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        )
    }
    
    private var flexibilityProgressChart: some View {
        let flexRecords = filteredRecords.filter { $0.workoutType == .flexibility }
        let angleData = flexRecords.compactMap { record -> (Date, Double)? in
            guard let angle = record.flexibilityData?.measurement else { return nil }
            return (record.date, angle)
        }
        
        guard !angleData.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("柔軟性推移（開脚角度）")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Chart {
                    ForEach(Array(angleData.enumerated()), id: \.0) { (index, item) in
                        LineMark(
                            x: .value("日付", item.0),
                            y: .value("角度", item.1)
                        )
                        .foregroundStyle(.blue)
                        .symbol(.diamond)
                    }
                }
                .frame(height: 150)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        )
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近の成果")
                .font(.headline)
            
            let analyzer = ProgressAnalyzer(modelContext: modelContext)
            let progress = analyzer.analyzeProgress(records: filteredRecords)
            
            if progress.recentAchievements.isEmpty {
                Text("まだ成果がありません。継続してトレーニングを行いましょう！")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(progress.recentAchievements.prefix(5), id: \.id) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
            }
        }
    }
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("詳細統計")
                .font(.headline)
            
            let analyzer = ProgressAnalyzer(modelContext: modelContext)
            let detailedReport = analyzer.generateDetailedWeeklyReport(records: filteredRecords, template: template)
            
            VStack(spacing: 12) {
                StatRow(title: "サイクリング一貫性", value: String(format: "%.1f%%", detailedReport.cyclingAnalysis.consistencyScore * 100))
                StatRow(title: "筋トレ一貫性", value: String(format: "%.1f%%", detailedReport.strengthAnalysis.consistencyScore * 100))
                StatRow(title: "柔軟性一貫性", value: String(format: "%.1f%%", detailedReport.flexibilityAnalysis.consistencyScore * 100))
            }
        }
    }
    
    private var dailyWorkoutCounts: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        
        for record in filteredRecords {
            let day = calendar.startOfDay(for: record.date)
            counts[day, default: 0] += 1
        }
        
        return counts.map { (date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack {
            Image(systemName: achievementIcon)
                .foregroundColor(achievementColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(achievement.achievementDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(DateFormatter.shortDate.string(from: achievement.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var achievementIcon: String {
        switch achievement.type {
        case .personalRecord:
            return "trophy.fill"
        case .milestone:
            return "target"
        case .improvement:
            return "chart.line.uptrend.xyaxis"
        case .streak:
            return "flame.fill"
        }
    }
    
    private var achievementColor: Color {
        switch achievement.type {
        case .personalRecord:
            return .yellow
        case .milestone:
            return .blue
        case .improvement:
            return .green
        case .streak:
            return .orange
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.horizontal)
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

#Preview {
    ProgressDetailsSheet(
        records: [],
        template: WeeklyTemplate.createDefaultTemplate()
    )
}