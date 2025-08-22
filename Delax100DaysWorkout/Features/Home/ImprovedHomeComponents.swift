import SwiftUI

// MARK: - Improved Today Progress Card

struct ImprovedTodayProgressCard: View {
    @Bindable var dataStore: HomeDataStore
    
    var body: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                // Header
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryAction)
                    
                    Text("今日の進捗")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Spacer()
                    
                    if dataStore.todayTotalTasks > 0 {
                        Text("\(Int(dataStore.taskProgress * 100))%")
                            .font(Typography.headlineSmall.font)
                            .foregroundColor(dataStore.taskProgress == 1.0 ? SemanticColor.successAction : SemanticColor.primaryAction)
                    }
                }
                
                // Progress Bar (only if tasks exist)
                if dataStore.todayTotalTasks > 0 {
                    ProgressView(value: dataStore.taskProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: dataStore.taskProgress == 1.0 ? .green : .blue))
                        .scaleEffect(y: 2, anchor: .center)
                }
                
                // Stats Grid
                HStack(spacing: Spacing.lg.value) {
                    // Tasks Progress Item
                    ProgressItem(
                        icon: "checkmark.circle",
                        title: "タスク",
                        value: dataStore.todayTotalTasks > 0 
                            ? "\(dataStore.todayCompletedTasks)"
                            : "未設定",
                        unit: dataStore.todayTotalTasks > 0 
                            ? "/\(dataStore.todayTotalTasks)"
                            : "",
                        color: dataStore.todayTotalTasks > 0 ? .blue : .gray,
                        isEmpty: dataStore.todayTotalTasks == 0
                    )
                    
                    // Steps Progress Item
                    ProgressItem(
                        icon: "figure.walk",
                        title: "歩数",
                        value: dataStore.hasHealthKitPermission
                            ? "\(dataStore.todaySteps.formatted())"
                            : "権限必要",
                        unit: dataStore.hasHealthKitPermission ? "歩" : "",
                        color: dataStore.hasHealthKitPermission ? .green : .orange,
                        isEmpty: !dataStore.hasHealthKitPermission || dataStore.todaySteps == 0
                    )
                    
                    // Weight Progress Item
                    ProgressItem(
                        icon: "scalemass",
                        title: "体重",
                        value: dataStore.currentWeight != nil
                            ? String(format: "%.1f", dataStore.currentWeight!)
                            : "未測定",
                        unit: dataStore.currentWeight != nil ? "kg" : "",
                        color: dataStore.currentWeight != nil ? .purple : .gray,
                        isEmpty: dataStore.currentWeight == nil
                    )
                }
            }
        }
    }
}

// MARK: - Progress Item

struct ProgressItem: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let isEmpty: Bool
    
    var body: some View {
        VStack(spacing: Spacing.xs.value) {
            Image(systemName: icon)
                .font(Typography.headlineMedium.font)
                .foregroundColor(isEmpty ? SemanticColor.tertiaryText.color : color)
            
            Text(title)
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.secondaryText)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(Typography.bodyMedium.font)
                    .fontWeight(isEmpty ? .regular : .semibold)
                    .foregroundColor(isEmpty ? SemanticColor.secondaryText : SemanticColor.primaryText)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(Typography.captionSmall.font)
                        .foregroundColor(SemanticColor.tertiaryText)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Improved FTP Card

struct ImprovedFTPCard: View {
    let value: Int
    
    var body: some View {
        BaseCard(style: ElevatedCardStyle()) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(Typography.headlineMedium.font)
                            .foregroundColor(.blue)
                        
                        Text("FTP")
                            .font(Typography.headlineMedium.font)
                            .foregroundColor(SemanticColor.primaryText)
                    }
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(value)")
                            .font(Typography.displayMedium.font)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("W")
                            .font(Typography.bodyMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                            .padding(.bottom, 4)
                    }
                }
                
                Spacer()
                
                // FTP Trend Indicator
                VStack(spacing: Spacing.xs.value) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(Typography.displaySmall.font)
                        .foregroundColor(.blue.opacity(0.3))
                    
                    Text("詳細")
                        .font(Typography.captionSmall.font)
                        .foregroundColor(SemanticColor.tertiaryText)
                }
            }
        }
    }
}

// MARK: - Improved Monthly Progress Card

struct ImprovedMonthlyProgressCard: View {
    let workouts: [WorkoutRecord]
    
    private var groupedByWeek: [Int: Int] {
        let calendar = Calendar.current
        var result: [Int: Int] = [:]
        
        for workout in workouts {
            let week = calendar.component(.weekOfMonth, from: workout.date)
            result[week, default: 0] += 1
        }
        
        return result
    }
    
    private var weeklyAverage: Double {
        let weeksInMonth = 4.0 // Simplified
        return Double(workouts.count) / weeksInMonth
    }
    
    private var achievementRate: Int {
        let targetMonthly = 20 // Default monthly target
        return Int((Double(workouts.count) / Double(targetMonthly)) * 100)
    }
    
    var body: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                // Header
                HStack {
                    Image(systemName: "calendar")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(.green)
                    
                    Text("今月の進捗")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Spacer()
                    
                    Text("\(workouts.count)回")
                        .font(Typography.headlineSmall.font)
                        .foregroundColor(.green)
                }
                
                // Weekly Bar Chart
                if !workouts.isEmpty {
                    HStack(alignment: .bottom, spacing: Spacing.sm.value) {
                        ForEach(1...4, id: \.self) { week in
                            WeekBar(
                                week: week,
                                count: groupedByWeek[week] ?? 0,
                                maxCount: groupedByWeek.values.max() ?? 1
                            )
                        }
                    }
                    .frame(height: 60)
                }
                
                // Statistics
                HStack {
                    StatItem(
                        title: "合計",
                        value: "\(workouts.count)",
                        color: .green
                    )
                    
                    Divider()
                        .frame(height: 20)
                    
                    StatItem(
                        title: "週平均",
                        value: String(format: "%.1f", weeklyAverage),
                        color: .blue
                    )
                    
                    Divider()
                        .frame(height: 20)
                    
                    StatItem(
                        title: "達成率",
                        value: "\(achievementRate)%",
                        color: achievementRate >= 100 ? .green : .orange
                    )
                }
            }
        }
    }
}

// MARK: - Week Bar

struct WeekBar: View {
    let week: Int
    let count: Int
    let maxCount: Int
    
    private var barHeight: CGFloat {
        guard maxCount > 0 else { return 2 }
        return max(2, CGFloat(count) / CGFloat(maxCount) * 50)
    }
    
    var body: some View {
        VStack(spacing: Spacing.xs.value) {
            ZStack(alignment: .bottom) {
                // Background bar
                RoundedRectangle(cornerRadius: CornerRadius.small.radius)
                    .fill(SemanticColor.secondaryBackground.color)
                    .frame(height: 50)
                
                // Progress bar
                RoundedRectangle(cornerRadius: CornerRadius.small.radius)
                    .fill(LinearGradient(
                        colors: [.blue, .blue.opacity(0.7)],
                        startPoint: .bottom,
                        endPoint: .top
                    ))
                    .frame(height: barHeight)
            }
            .frame(maxWidth: .infinity)
            
            Text("W\(week)")
                .font(Typography.captionSmall.font)
                .foregroundColor(SemanticColor.tertiaryText)
            
            if count > 0 {
                Text("\(count)")
                    .font(Typography.captionSmall.font)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColor.secondaryText)
            }
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs.value) {
            Text(value)
                .font(Typography.bodyMedium.font)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let errors: [HomeDataError]
    @State private var showDetails = false
    
    var body: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                // Header
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(.orange)
                    
                    Text("一部のデータ取得に問題があります")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Spacer()
                    
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetails.toggle()
                        }
                    }) {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.primaryAction)
                    }
                }
                
                // Details (expandable)
                if showDetails {
                    VStack(alignment: .leading, spacing: Spacing.sm.value) {
                        ForEach(errors) { error in
                            ErrorItem(error: error)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

// MARK: - Error Item

struct ErrorItem: View {
    let error: HomeDataError
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm.value) {
            Circle()
                .fill(SemanticColor.tertiaryText.color)
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                Text(error.localizedDescription)
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.secondaryText)
                
                // Action button for resolvable errors
                if error.canResolve, let actionTitle = error.actionTitle {
                    Button(actionTitle) {
                        handleErrorAction(error)
                    }
                    .font(Typography.captionMedium.font)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
            }
            
            Spacer()
        }
    }
    
    private func handleErrorAction(_ error: HomeDataError) {
        switch error {
        case .healthKitNotAuthorized:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .noActiveTemplate:
            // TODO: Navigate to template setup
            break
        default:
            break
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(spacing: Spacing.lg.value) {
                Image(systemName: icon)
                    .font(Typography.displayMedium.font)
                    .foregroundColor(SemanticColor.tertiaryText)
                
                VStack(spacing: Spacing.sm.value) {
                    Text(title)
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Text(message)
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                if let actionTitle = actionTitle, let action = action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(Spacing.xl.value)
        }
    }
}