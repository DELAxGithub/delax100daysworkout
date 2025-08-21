import SwiftUI
import SwiftData
import Charts
import OSLog

struct UnifiedHomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sstViewModel = SSTDashboardViewModel()
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var todaySteps: Double = 0
    @State private var progressViewModel: ProgressChartViewModel? = nil
    @State private var dashboardViewModel: DashboardViewModel? = nil
    @State private var homeDashboardViewModel: HomeDashboardViewModel? = nil
    @State private var scheduleViewModel: WeeklyScheduleViewModel? = nil
    @State private var latestWeight: Double? = nil
    @State private var isHealthKitSyncing = false
    @State private var userProfile: UserProfile? = nil
    
    @State private var showingFTPEntry = false
    @State private var showingDemoDataAlert = false
    @State private var demoDataMessage = ""
    @State private var showingProgressDetails = false
    @State private var showingMetricsHistory = false
    @State private var showingHistoryManagement = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Progress Integration View (Issue #56: Training Manager)
                    ProgressIntegrationView()
                    
                    // Premium Dashboard Cards
                    if let homeDashboardViewModel = homeDashboardViewModel {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(Array(homeDashboardViewModel.summaryCards.prefix(4)), id: \.title) { config in
                                InteractiveSummaryCard(
                                    configuration: config,
                                    onTap: { handleCardTap(config) }
                                )
                            }
                        }
                        
                        // Today's Tasks Widget
                        if let scheduleViewModel = scheduleViewModel {
                            TodayTasksWidget(scheduleViewModel: scheduleViewModel)
                        }
                    }
                    
                    // FTP Section
                    SectionCard(title: "FTP進捗", icon: "bolt.fill", iconColor: .blue) {
                        VStack(spacing: 16) {
                            // Current FTP with goals and progress
                            HStack(spacing: 20) {
                                // Current FTP
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("現在")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let currentFTP = sstViewModel.currentFTP {
                                        Text("\(currentFTP)W")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    } else {
                                        Text("--")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Goal FTP
                                VStack(alignment: .center, spacing: 4) {
                                    Text("目標")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let goalFTP = userProfile?.goalFtp, goalFTP > 0 {
                                        Text("\(goalFTP)W")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    } else {
                                        Text("未設定")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Progress percentage
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("進捗")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let currentFTP = sstViewModel.currentFTP,
                                       let startFTP = userProfile?.startFtp,
                                       let goalFTP = userProfile?.goalFtp,
                                       goalFTP > startFTP {
                                        let progress = Double(currentFTP - startFTP) / Double(goalFTP - startFTP) * 100
                                        Text("\(Int(max(0, min(100, progress))))%")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(progress >= 100 ? .green : .orange)
                                    } else {
                                        Text("--")
                                            .font(.title3)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
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
                    
                    // Health Summary Section
                    SectionCard(title: "健康データ", icon: "heart.fill", iconColor: .red) {
                        VStack(spacing: 16) {
                            // Weight section with goals
                            HStack(spacing: 20) {
                                // Current Weight
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("体重")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let weight = latestWeight {
                                        Text("\(weight, specifier: "%.1f")kg")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orange)
                                    } else {
                                        Text("データなし")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Goal Weight
                                VStack(alignment: .center, spacing: 4) {
                                    Text("目標")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let goalWeight = userProfile?.goalWeightKg, goalWeight > 0 {
                                        Text("\(goalWeight, specifier: "%.1f")kg")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    } else {
                                        Text("未設定")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Weight Progress
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("進捗")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let currentWeight = latestWeight,
                                       let startWeight = userProfile?.startWeightKg,
                                       let goalWeight = userProfile?.goalWeightKg,
                                       startWeight != goalWeight {
                                        let progress = (startWeight - currentWeight) / (startWeight - goalWeight) * 100
                                        Text("\(Int(max(0, min(100, progress))))%")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(progress >= 100 ? .green : .orange)
                                    } else {
                                        Text("--")
                                            .font(.title3)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // Steps Display
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("今日の歩数")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(todaySteps)) 歩")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                // Goal date countdown
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("目標まで")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let goalDate = userProfile?.goalDate {
                                        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: goalDate).day ?? 0
                                        if daysLeft > 0 {
                                            Text("\(daysLeft)日")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        } else {
                                            Text("期限終了")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    } else {
                                        Text("未設定")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // HealthKit Authorization Status
                        if !healthKitManager.isAuthorized {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Apple Health連携が必要です")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("設定") {
                                    Task {
                                        do {
                                            try await healthKitManager.requestPermissions()
                                            await loadTodaySteps()
                                        } catch {
                                            print("HealthKit authorization failed: \(error)")
                                        }
                                    }
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    
                    // Overall Progress Section
                    SectionCard(title: "全体進捗", icon: "chart.bar.fill", iconColor: .green) {
                        VStack(spacing: 16) {
                            // Progress Stats with Goal Comparison
                            VStack(spacing: 12) {
                                // Main stats
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
                                
                                // Goal timeline progress
                                if let goalDate = userProfile?.goalDate {
                                    let totalDays = Calendar.current.dateComponents([.day], from: Date().addingTimeInterval(-100*24*60*60), to: goalDate).day ?? 100
                                    let elapsedDays = Calendar.current.dateComponents([.day], from: Date().addingTimeInterval(-100*24*60*60), to: Date()).day ?? 0
                                    let timeProgress = Double(elapsedDays) / Double(totalDays) * 100
                                    
                                    HStack {
                                        Text("目標期間進捗")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(max(0, min(100, timeProgress))))% (経過\(elapsedDays)/\(totalDays)日)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(timeProgress > 100 ? .red : .blue)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
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
                                color: .gray,
                                action: { 
                                    // Disabled - use history screens for workout entry
                                }
                            )
                            
                            QuickActionButton(
                                title: "体重記録",
                                icon: "scalemass.fill",
                                color: .orange,
                                action: { 
                                    showingMetricsHistory = true
                                }
                            )
                            
                            QuickActionButton(
                                title: "進捗確認",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .purple,
                                action: { showingProgressDetails = true }
                            )
                            
                            QuickActionButton(
                                title: "履歴管理",
                                icon: "clock.arrow.circlepath",
                                color: .indigo,
                                action: { showingHistoryManagement = true }
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
                    .disabled(isHealthKitSyncing)
                }
            }
            .refreshable {
                refreshAllData()
            }
        }
        .modalNavigation(
            isPresented: $showingFTPEntry,
            title: "FTP記録"
        ) {
            FTPEntryView()
        }
        .modalNavigation(
            isPresented: $showingMetricsHistory,
            title: "メトリクス履歴"
        ) {
            MetricsHistoryView()
        }
        .modalNavigation(
            isPresented: $showingProgressDetails,
            title: "進捗詳細"
        ) {
            if let progressViewModel = progressViewModel {
                ProgressChartView(viewModel: progressViewModel)
            } else {
                VStack(spacing: Spacing.md.value) {
                    ProgressView("進捗データを読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Text("ワークアウト履歴を解析しています...")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SemanticColor.surfaceBackground.color)
            }
        }
        .modalNavigation(
            isPresented: $showingHistoryManagement,
            title: "履歴管理"
        ) {
            HistoryManagementView()
        }
        .alert("デモデータ", isPresented: $showingDemoDataAlert) {
            Button("OK") { }
        } message: {
            Text(demoDataMessage)
        }
        .onAppear {
            setupViewModels()
            loadUserProfile()
            loadAllData()
            Task {
                await initializeHealthKit()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileUpdated)) { _ in
            loadUserProfile()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModels() {
        sstViewModel.setModelContext(modelContext)
        progressViewModel = ProgressChartViewModel(modelContext: modelContext)
        dashboardViewModel = DashboardViewModel(modelContext: modelContext)
        homeDashboardViewModel = HomeDashboardViewModel(modelContext: modelContext)
        scheduleViewModel = WeeklyScheduleViewModel(modelContext: modelContext)
    }
    
    private func loadUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            userProfile = try modelContext.fetch(descriptor).first
        } catch {
            Logger.error.error("Failed to fetch UserProfile: \(error.localizedDescription)")
        }
    }
    
    private func loadAllData() {
        sstViewModel.loadData()
        progressViewModel?.fetchData()
        dashboardViewModel?.refreshData()
    }
    
    private func refreshAllData() {
        loadUserProfile() // UserProfile更新
        sstViewModel.refreshData()
        progressViewModel?.fetchData()
        dashboardViewModel?.refreshData()
        homeDashboardViewModel?.refreshAllData()
        scheduleViewModel?.refreshCompletedTasks()
        
        // HealthKitデータも更新
        Task {
            await syncHealthKitData()
            await loadTodaySteps()
        }
    }
    
    private func handleCardTap(_ config: SummaryCardConfiguration) {
        HapticManager.shared.trigger(.impact(.medium))
        // Handle card tap based on configuration
    }
    
    // MARK: - HealthKit Methods
    
    private func initializeHealthKit() async {
        // HealthKit認証を確認・要求
        if !healthKitManager.isAuthorized {
            do {
                try await healthKitManager.requestPermissions()
            } catch {
                Logger.error.error("HealthKit認証エラー: \(error.localizedDescription)")
                return
            }
        }
        
        // 認証成功後、データを同期
        await syncHealthKitData()
        await loadTodaySteps()
    }
    
    private func syncHealthKitData() async {
        guard healthKitManager.isAuthorized else { 
            await loadLatestWeight()
            return 
        }
        
        await MainActor.run {
            isHealthKitSyncing = true
        }
        
        do {
            // 過去7日間のデータを同期
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let _ = try await healthKitManager.syncWeightData(from: startDate, modelContext: modelContext)
            
            // 最新体重を取得して表示
            await loadLatestWeight()
            
        } catch {
            Logger.error.error("HealthKitデータ同期エラー: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            isHealthKitSyncing = false
        }
    }
    
    @MainActor
    private func loadLatestWeight() async {
        // 最新のDailyMetricから体重データを取得
        let descriptor = FetchDescriptor<DailyMetric>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let metrics = try modelContext.fetch(descriptor)
            latestWeight = metrics.first?.weightKg
        } catch {
            Logger.error.error("体重データ取得エラー: \(error.localizedDescription)")
        }
    }
    
    // 今日の歩数を取得
    private func loadTodaySteps() async {
        guard healthKitManager.isAuthorized else {
            await MainActor.run {
                todaySteps = 0
            }
            return
        }
        
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            let steps = try await healthKitManager.getStepCount(from: startOfDay, to: endOfDay)
            
            await MainActor.run {
                todaySteps = steps
            }
        } catch {
            Logger.error.error("歩数データ取得エラー: \(error.localizedDescription)")
            await MainActor.run {
                todaySteps = 0
            }
        }
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
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(Typography.headlineMedium.font)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(Typography.displaySmall.font)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColor.primaryText)
                
                Text(title)
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.secondaryText)
                
                Text(subtitle)
                    .font(Typography.captionSmall.font)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                HStack {
                    Image(systemName: icon)
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(iconColor)
                    
                    Text(title)
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Spacer()
                }
                
                content
            }
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs.value) {
            Text(value)
                .font(Typography.displaySmall.font)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(Typography.captionSmall.font)
                .foregroundColor(SemanticColor.secondaryText)
            
            Text(title)
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.secondaryText)
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
            VStack(spacing: Spacing.sm.value) {
                Image(systemName: icon)
                    .font(Typography.headlineMedium.font)
                    .foregroundColor(color)
                
                Text(title)
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.listItemSpacing.value)
            .background(color.opacity(0.1))
            .cornerRadius(CornerRadius.large.radius)
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

// MARK: - Notifications

extension Notification.Name {
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
}

#Preview {
    UnifiedHomeDashboardView()
        .modelContainer(for: [FTPHistory.self, DailyMetric.self, WorkoutRecord.self])
}