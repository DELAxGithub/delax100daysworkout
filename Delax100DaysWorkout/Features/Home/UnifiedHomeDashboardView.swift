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
    @State private var showingWorkoutEntry = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 1. 最重要: Today's Tasks Widget (最上部に配置)
                    if let scheduleViewModel = scheduleViewModel {
                        TodayTasksWidget(scheduleViewModel: scheduleViewModel)
                    }
                    
                    // 2. 重要: 今日の進捗サマリー
                    TodayProgressSummaryCard(
                        completedTasks: scheduleViewModel?.getTodaysTasks().filter { scheduleViewModel?.isTaskCompleted($0) ?? false }.count ?? 0,
                        totalTasks: scheduleViewModel?.getTodaysTasks().count ?? 0,
                        todaySteps: Int(todaySteps),
                        currentWeight: latestWeight
                    )
                    
                    // 3. 中程度: 簡潔なサマリーカード
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        // FTP要約カード
                        if let currentFTP = sstViewModel.currentFTP {
                            InteractiveSummaryCard(
                                configuration: .basic(
                                    title: "現在のFTP",
                                    value: "\(currentFTP)W",
                                    subtitle: "タップで詳細",
                                    color: .blue,
                                    icon: "bolt.fill"
                                ),
                                onTap: { handleCardTap(.basic(title: "FTP", value: "", subtitle: "", color: .blue, icon: "bolt.fill")) }
                            )
                        }
                        
                        // 進捗要約カード
                        InteractiveSummaryCard(
                            configuration: .basic(
                                title: "今月の進捗",
                                value: "\(progressViewModel?.currentMonthWorkouts ?? 0)回",
                                subtitle: "タップで詳細",
                                color: .green,
                                icon: "checkmark.circle.fill"
                            ),
                            onTap: { handleCardTap(.basic(title: "進捗", value: "", subtitle: "", color: .green, icon: "checkmark.circle.fill")) }
                        )
                    }
                    
                    // 4. クイックアクション (優先度を上げて配置)
                    QuickActionsSection(
                        showingFTPEntry: $showingFTPEntry,
                        showingWorkoutEntry: $showingWorkoutEntry,
                        showingMetricsHistory: $showingMetricsHistory,
                        showingProgressDetails: $showingProgressDetails,
                        showingHistoryManagement: $showingHistoryManagement
                    )
                    
                    // 5. 詳細情報 (展開可能)
                    ExpandableDetailsSections(
                        sstViewModel: sstViewModel,
                        userProfile: userProfile,
                        latestWeight: latestWeight,
                        progressViewModel: progressViewModel
                    )
                    
                    // Debug Demo Data Section (開発時のみ)
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
        // Modal presentations remain the same...
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
        .modalNavigation(
            isPresented: $showingWorkoutEntry,
            title: "ワークアウト記録"
        ) {
            QuickRecordView()
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
        // sstViewModelのみをセットアップ（他は必要に応じて遅延初期化）
        sstViewModel.setModelContext(modelContext)
        
        // 必須のViewModelのみを初期化
        if progressViewModel == nil {
            progressViewModel = ProgressChartViewModel(modelContext: modelContext)
        }
        
        if scheduleViewModel == nil {
            scheduleViewModel = WeeklyScheduleViewModel(modelContext: modelContext)
        }
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
        // 並列でデータを読み込み
        Task {
            async let sstData: Void = sstViewModel.loadData()
            async let progressData: Void = progressViewModel?.fetchData() ?? ()
            async let userProfileData: Void = loadUserProfile()
            
            await sstData
            await progressData
            await userProfileData
        }
    }
    
    private func refreshAllData() {
        // バッチでデータを更新
        Task {
            // 同期的な更新（UI関連）
            await MainActor.run {
                loadUserProfile()
                scheduleViewModel?.refreshCompletedTasks()
            }
            
            // 非同期的な更新（データ取得）
            async let sstRefresh: Void = sstViewModel.refreshData()
            async let progressRefresh: Void = progressViewModel?.fetchData() ?? ()
            async let healthKitSync: Void = syncHealthKitData()
            async let stepsLoad: Void = loadTodaySteps()
            
            await sstRefresh
            await progressRefresh
            await healthKitSync
            await stepsLoad
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

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    @Binding var showingFTPEntry: Bool
    @Binding var showingWorkoutEntry: Bool
    @Binding var showingMetricsHistory: Bool
    @Binding var showingProgressDetails: Bool
    @Binding var showingHistoryManagement: Bool
    
    var body: some View {
        SectionCard(title: "クイックアクション", icon: "plus.circle.fill", iconColor: .blue) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "ワークアウト",
                    icon: "plus.circle.fill",
                    color: .green,
                    action: { showingWorkoutEntry = true }
                )
                
                QuickActionButton(
                    title: "FTP記録",
                    icon: "bolt.fill",
                    color: .blue,
                    action: { showingFTPEntry = true }
                )
                
                QuickActionButton(
                    title: "体重記録",
                    icon: "scalemass.fill",
                    color: .orange,
                    action: { showingMetricsHistory = true }
                )
                
                QuickActionButton(
                    title: "進捗詳細",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple,
                    action: { showingProgressDetails = true }
                )
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Expandable Details Sections

struct ExpandableDetailsSections: View {
    let sstViewModel: SSTDashboardViewModel
    let userProfile: UserProfile?
    let latestWeight: Double?
    let progressViewModel: ProgressChartViewModel?
    
    @State private var showingDetailedMetrics = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Toggle button for detailed metrics
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showingDetailedMetrics.toggle()
                }
                HapticManager.shared.trigger(.impact(.light))
            }) {
                HStack {
                    Text(showingDetailedMetrics ? "詳細を隠す" : "詳細を表示")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.primaryAction)
                    
                    Spacer()
                    
                    Image(systemName: showingDetailedMetrics ? "chevron.up" : "chevron.down")
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.primaryAction)
                }
                .padding()
                .background(SemanticColor.primaryAction.color.opacity(0.1))
                .cornerRadius(CornerRadius.medium.radius)
            }
            .buttonStyle(.plain)
            
            if showingDetailedMetrics {
                VStack(spacing: 16) {
                    // FTP Progress Detail
                    CompactFTPSection(
                        sstViewModel: sstViewModel,
                        userProfile: userProfile
                    )
                    
                    // Health Metrics Detail
                    CompactHealthSection(
                        latestWeight: latestWeight,
                        userProfile: userProfile
                    )
                    
                    // Overall Progress Detail
                    CompactOverallProgressSection(
                        progressViewModel: progressViewModel,
                        userProfile: userProfile
                    )
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
    }
}

// MARK: - Compact Detail Components

struct CompactFTPSection: View {
    let sstViewModel: SSTDashboardViewModel
    let userProfile: UserProfile?
    
    var body: some View {
        SectionCard(title: "FTP詳細", icon: "bolt.fill", iconColor: .blue) {
            HStack {
                if let currentFTP = sstViewModel.currentFTP {
                    StatView(
                        title: "現在",
                        value: "\(currentFTP)",
                        unit: "W",
                        color: .blue
                    )
                    
                    if let goalFTP = userProfile?.goalFtp, goalFTP > 0,
                       let startFTP = userProfile?.startFtp {
                        let progress = Double(currentFTP - startFTP) / Double(goalFTP - startFTP) * 100
                        StatView(
                            title: "進捗",
                            value: "\(Int(max(0, min(100, progress))))",
                            unit: "%",
                            color: progress >= 100 ? .green : .orange
                        )
                    }
                } else {
                    Text("FTPデータがありません")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

struct CompactHealthSection: View {
    let latestWeight: Double?
    let userProfile: UserProfile?
    
    var body: some View {
        SectionCard(title: "健康データ詳細", icon: "heart.fill", iconColor: .red) {
            HStack {
                if let weight = latestWeight {
                    StatView(
                        title: "体重",
                        value: String(format: "%.1f", weight),
                        unit: "kg",
                        color: .orange
                    )
                    
                    if let goalWeight = userProfile?.goalWeightKg, goalWeight > 0,
                       let startWeight = userProfile?.startWeightKg {
                        let progress = (startWeight - weight) / (startWeight - goalWeight) * 100
                        StatView(
                            title: "減量進捗",
                            value: "\(Int(max(0, min(100, progress))))",
                            unit: "%",
                            color: progress >= 100 ? .green : .orange
                        )
                    }
                } else {
                    Text("体重データがありません")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

struct CompactOverallProgressSection: View {
    let progressViewModel: ProgressChartViewModel?
    let userProfile: UserProfile?
    
    var body: some View {
        SectionCard(title: "全体進捗詳細", icon: "chart.bar.fill", iconColor: .green) {
            if let progressViewModel = progressViewModel {
                HStack {
                    StatView(
                        title: "今月",
                        value: "\(progressViewModel.currentMonthWorkouts)",
                        unit: "回",
                        color: .green
                    )
                    
                    StatView(
                        title: "連続",
                        value: "\(progressViewModel.currentStreak)",
                        unit: "日",
                        color: .orange
                    )
                    
                    StatView(
                        title: "合計",
                        value: "\(progressViewModel.totalWorkouts)",
                        unit: "回",
                        color: .blue
                    )
                }
            } else {
                Text("進捗データを読み込み中...")
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - Today Progress Summary Card

struct TodayProgressSummaryCard: View {
    let completedTasks: Int
    let totalTasks: Int
    let todaySteps: Int
    let currentWeight: Double?
    
    var taskProgress: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var body: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryAction)
                    
                    Text("今日の進捗")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Spacer()
                    
                    Text("\(Int(taskProgress * 100))%")
                        .font(Typography.headlineSmall.font)
                        .foregroundColor(taskProgress == 1.0 ? SemanticColor.successAction : SemanticColor.primaryAction)
                }
                
                // Progress Bar
                ProgressView(value: taskProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: taskProgress == 1.0 ? .green : .blue))
                    .scaleEffect(y: 2, anchor: .center)
                
                // Stats Grid
                HStack(spacing: Spacing.lg.value) {
                    StatView(
                        title: "タスク",
                        value: "\(completedTasks)",
                        unit: "/\(totalTasks)",
                        color: taskProgress == 1.0 ? .green : .blue
                    )
                    
                    StatView(
                        title: "歩数",
                        value: "\(todaySteps)",
                        unit: "歩",
                        color: .orange
                    )
                    
                    if let weight = currentWeight {
                        StatView(
                            title: "体重",
                            value: String(format: "%.1f", weight),
                            unit: "kg",
                            color: .purple
                        )
                    } else {
                        StatView(
                            title: "体重",
                            value: "未測定",
                            unit: "",
                            color: .gray
                        )
                    }
                }
            }
        }
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