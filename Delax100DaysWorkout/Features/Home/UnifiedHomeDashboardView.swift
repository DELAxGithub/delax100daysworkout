import SwiftUI
import SwiftData
import Charts

struct UnifiedHomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sstViewModel = SSTDashboardViewModel()
    @State private var progressViewModel: ProgressChartViewModel? = nil
    @State private var dashboardViewModel: DashboardViewModel? = nil
    
    @State private var showingFTPEntry = false
    @State private var showingDemoDataAlert = false
    @State private var demoDataMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Summary Cards
                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "現在のFTP",
                            value: "\(sstViewModel.currentFTP ?? 0)W",
                            subtitle: sstViewModel.formattedFTPChange ?? "データなし",
                            color: .blue,
                            icon: "bolt.fill"
                        )
                        
                        SummaryCard(
                            title: "今週の進捗",
                            value: "\(progressViewModel?.thisWeekWorkouts ?? 0)",
                            subtitle: "ワークアウト完了",
                            color: .green,
                            icon: "checkmark.circle.fill"
                        )
                    }
                    
                    // FTP Section
                    SectionCard(title: "FTP進捗", icon: "bolt.fill", iconColor: .blue) {
                        VStack(spacing: 16) {
                            // Current FTP with 20-min target
                            if let currentFTP = sstViewModel.currentFTP,
                               let twentyMinTarget = sstViewModel.twentyMinutePowerTarget {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("現在")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(currentFTP)W")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("20分目標")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(twentyMinTarget)W")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // FTP Chart (Compact)
                            if !sstViewModel.ftpHistory.isEmpty {
                                Chart(sstViewModel.ftpHistory.reversed(), id: \.id) { record in
                                    LineMark(
                                        x: .value("日付", record.date),
                                        y: .value("FTP", record.ftpValue)
                                    )
                                    .foregroundStyle(.blue)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                    
                                    PointMark(
                                        x: .value("日付", record.date),
                                        y: .value("FTP", record.ftpValue)
                                    )
                                    .foregroundStyle(.blue)
                                    .symbol(.circle)
                                    .symbolSize(40)
                                }
                                .frame(height: 120)
                                .chartYScale(domain: .automatic)
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                                        AxisValueLabel(format: .dateTime.month().day())
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let intValue = value.as(Int.self) {
                                                Text("\(intValue)W")
                                            }
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "bolt.circle")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                    Text("FTPを記録して進捗を確認")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Button("FTP記録", action: { showingFTPEntry = true })
                                        .buttonStyle(.borderedProminent)
                                }
                                .frame(height: 120)
                            }
                        }
                    }
                    
                    // W/HR Efficiency Section
                    if !sstViewModel.whrData.isEmpty {
                        SectionCard(title: "W/HR効率", icon: "heart.fill", iconColor: .red) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text(sstViewModel.getWHRTrend().displayText)
                                        .font(.subheadline)
                                        .foregroundColor(sstViewModel.getWHRTrend().color)
                                    Spacer()
                                }
                                
                                Chart(sstViewModel.whrData, id: \.id) { dataPoint in
                                    LineMark(
                                        x: .value("日付", dataPoint.date),
                                        y: .value("W/HR", dataPoint.whrRatio)
                                    )
                                    .foregroundStyle(.red)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                    
                                    AreaMark(
                                        x: .value("日付", dataPoint.date),
                                        y: .value("W/HR", dataPoint.whrRatio)
                                    )
                                    .foregroundStyle(.red.opacity(0.1))
                                }
                                .frame(height: 100)
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                                        AxisValueLabel(format: .dateTime.month().day())
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let doubleValue = value.as(Double.self) {
                                                Text(String(format: "%.1f", doubleValue))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Overall Progress Section
                    SectionCard(title: "全体進捗", icon: "chart.bar.fill", iconColor: .green) {
                        VStack(spacing: 16) {
                            // Progress Stats
                            HStack(spacing: 20) {
                                StatView(
                                    title: "今月",
                                    value: "\(progressViewModel?.currentMonthWorkouts ?? 0)",
                                    unit: "回",
                                    color: .green
                                )
                                
                                StatView(
                                    title: "連続",
                                    value: "\(progressViewModel?.currentStreak ?? 0)",
                                    unit: "日",
                                    color: .orange
                                )
                                
                                StatView(
                                    title: "合計",
                                    value: "\(progressViewModel?.totalWorkouts ?? 0)",
                                    unit: "回",
                                    color: .blue
                                )
                            }
                            
                            // Recent Activity
                            if let progressViewModel = progressViewModel, !progressViewModel.recentWorkouts.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("最近のワークアウト")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    ForEach(Array(progressViewModel.recentWorkouts.prefix(3)), id: \.id) { workout in
                                        HStack {
                                            Image(systemName: workout.workoutType.iconName)
                                                .foregroundColor(workout.workoutType.iconColor)
                                                .frame(width: 20)
                                            
                                            Text(workout.workoutType.rawValue)
                                                .font(.caption)
                                            
                                            Spacer()
                                            
                                            Text(workout.date, format: .dateTime.month().day())
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Quick Actions
                    SectionCard(title: "クイックアクション", icon: "plus.circle.fill", iconColor: .blue) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            QuickActionButton(
                                title: "FTP記録",
                                icon: "bolt.fill",
                                color: .blue,
                                action: { showingFTPEntry = true }
                            )
                            
                            QuickActionButton(
                                title: "ワークアウト",
                                icon: "plus.circle.fill",
                                color: .green,
                                action: { /* Navigate to LogEntry */ }
                            )
                            
                            QuickActionButton(
                                title: "体重記録",
                                icon: "scalemass.fill",
                                color: .orange,
                                action: { /* Navigate to Weight Entry */ }
                            )
                            
                            QuickActionButton(
                                title: "進捗確認",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .purple,
                                action: { /* Show detailed progress */ }
                            )
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // Debug Demo Data Section
                    #if DEBUG
                    DemoDataSection(
                        modelContext: modelContext,
                        onDemoDataGenerated: {
                            sstViewModel.refreshData()
                            progressViewModel?.fetchData()
                        },
                        onShowMessage: { message in
                            demoDataMessage = message
                            showingDemoDataAlert = true
                        }
                    )
                    #endif
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("更新", systemImage: "arrow.clockwise") {
                        refreshAllData()
                    }
                }
            }
            .refreshable {
                refreshAllData()
            }
        }
        .sheet(isPresented: $showingFTPEntry) {
            NavigationStack {
                FTPEntryView()
                    .navigationTitle("FTP記録")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("キャンセル") {
                                showingFTPEntry = false
                            }
                        }
                    }
            }
        }
        .alert("デモデータ", isPresented: $showingDemoDataAlert) {
            Button("OK") { }
        } message: {
            Text(demoDataMessage)
        }
        .onAppear {
            setupViewModels()
            loadAllData()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModels() {
        sstViewModel.setModelContext(modelContext)
        progressViewModel = ProgressChartViewModel(modelContext: modelContext)
        dashboardViewModel = DashboardViewModel(modelContext: modelContext)
    }
    
    private func loadAllData() {
        sstViewModel.loadData()
        progressViewModel?.fetchData()
        dashboardViewModel?.refreshData()
    }
    
    private func refreshAllData() {
        sstViewModel.refreshData()
        progressViewModel?.fetchData()
        dashboardViewModel?.refreshData()
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StatView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extension for ViewModels

extension ProgressChartViewModel {
    var thisWeekWorkouts: Int {
        // Calculate this week's workouts
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return workoutRecords.filter { $0.date >= weekStart }.count
    }
    
    var currentMonthWorkouts: Int {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return workoutRecords.filter { $0.date >= monthStart }.count
    }
    
    var currentStreak: Int {
        // Calculate current workout streak
        guard !workoutRecords.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedWorkouts = workoutRecords.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = Date()
        
        for workout in sortedWorkouts {
            let workoutDay = calendar.startOfDay(for: workout.date)
            let checkDay = calendar.startOfDay(for: currentDate)
            
            if calendar.dateInterval(of: .day, for: workoutDay)?.contains(checkDay) == true {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    var totalWorkouts: Int {
        return workoutRecords.count
    }
    
    var recentWorkouts: [WorkoutRecord] {
        return Array(workoutRecords.sorted { $0.date > $1.date }.prefix(5))
    }
}

// MARK: - Preview

#Preview {
    UnifiedHomeDashboardView()
        .modelContainer(for: [FTPHistory.self, DailyMetric.self, WorkoutRecord.self])
}