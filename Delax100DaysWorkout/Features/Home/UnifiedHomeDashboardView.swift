import SwiftUI
import SwiftData
import OSLog

struct UnifiedHomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var dataStore: HomeDataStore?
    @State private var showingFTPEntry = false
    @State private var showingDemoDataAlert = false
    @State private var demoDataMessage = ""
    @State private var showingProgressDetails = false
    @State private var showingMetricsHistory = false
    @State private var showingHistoryManagement = false
    @State private var showingWorkoutEntry = false
    
    var body: some View {
        NavigationStack {
            if let dataStore = dataStore {
                ScrollView {
                    LazyVStack(spacing: Spacing.lg.value) {
                        // Error Banner (if any)
                        if dataStore.hasErrors {
                            ErrorBanner(errors: dataStore.errors)
                        }
                        
                        // Main Content or Empty State
                        if dataStore.hasData || dataStore.isLoading {
                            // 1. Today's Progress Summary
                            ImprovedTodayProgressCard(dataStore: dataStore)
                            
                            // 2. Cards Grid
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.md.value) {
                                // FTP Card (only if data exists)
                                if let ftpValue = dataStore.currentFTP {
                                    ImprovedFTPCard(value: ftpValue)
                                        .onTapGesture {
                                            showingFTPEntry = true
                                        }
                                }
                                
                                // Monthly Progress Card (always show)
                                ImprovedMonthlyProgressCard(workouts: dataStore.monthlyWorkouts)
                                    .onTapGesture {
                                        showingProgressDetails = true
                                    }
                            }
                            
                            // 3. Quick Actions
                            QuickActionsSection(
                                showingFTPEntry: $showingFTPEntry,
                                showingWorkoutEntry: $showingWorkoutEntry,
                                showingMetricsHistory: $showingMetricsHistory,
                                showingProgressDetails: $showingProgressDetails,
                                showingHistoryManagement: $showingHistoryManagement
                            )
                            
                            // 4. Demo Data (Debug only)
                            #if DEBUG
                            DemoDataSection(
                                modelContext: modelContext,
                                onDemoDataGenerated: {
                                    Task {
                                        await dataStore.refreshData()
                                    }
                                },
                                onShowMessage: { message in
                                    demoDataMessage = message
                                    showingDemoDataAlert = true
                                }
                            )
                            #endif
                        } else {
                            // Empty State
                            EmptyStateView(
                                title: "ワークアウトを始めましょう",
                                message: "まずはワークアウトテンプレートを設定して、今日のタスクを確認しましょう。",
                                icon: "figure.strengthtraining.traditional",
                                actionTitle: "ワークアウト追加",
                                action: { showingWorkoutEntry = true }
                            )
                        }
                    }
                    .padding()
                }
                .navigationTitle("ホーム")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task {
                                await dataStore.refreshData()
                            }
                        }) {
                            if dataStore.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(dataStore.isLoading)
                    }
                }
                .refreshable {
                    Task {
                        await dataStore.refreshData()
                    }
                }
            } else {
                // Loading state
                VStack {
                    ProgressView("データを読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("ホーム")
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
            VStack(spacing: Spacing.md.value) {
                Text("進捗詳細機能は開発中です")
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.primaryText.color)
                
                Text("月次進捗: \(dataStore?.monthlyWorkoutCount ?? 0)回")
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SemanticColor.surfaceBackground.color)
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
            setupDataStore()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupDataStore() {
        if dataStore == nil {
            dataStore = HomeDataStore(modelContext: modelContext)
            
            Task {
                await dataStore?.loadAllData()
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