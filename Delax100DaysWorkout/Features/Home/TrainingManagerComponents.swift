import SwiftUI
import SwiftData

// MARK: - Task Counter Card Component

struct TaskCounterCard: View {
    let title: String
    let count: Int
    let target: Int
    let subtitle: String
    let icon: String
    let color: Color
    
    var progressRate: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(count) / Double(target))
    }
    
    var body: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(Typography.headlineMedium.font)
                    
                    Text(title)
                        .font(Typography.bodyLarge.font)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Spacer()
                    
                    if count >= target {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
                
                Text("\(count)")
                    .font(Typography.displaySmall.font)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.secondaryText)
                
                // Progress Bar
                ProgressView(value: progressRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Task Counter Section

struct TaskCounterSection: View {
    let counters: [TaskCompletionCounter]
    
    var body: some View {
        SectionCard(title: "トレーニング累積", icon: "target", iconColor: .blue) {
            if counters.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("トレーニングを記録して\n累積回数を確認しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 100)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(Array(counters.prefix(4)), id: \.taskType) { counter in
                        TaskCounterCard(
                            title: TaskIdentificationUtils.getDisplayName(for: counter.taskType),
                            count: counter.completionCount,
                            target: counter.currentTarget,
                            subtitle: counter.progressText,
                            icon: getIconForTaskType(counter.taskType),
                            color: getColorForTaskType(counter.taskType)
                        )
                    }
                }
            }
        }
    }
    
    private func getIconForTaskType(_ taskType: String) -> String {
        if taskType.hasPrefix("サイクリング") {
            return "bicycle"
        } else if taskType.hasPrefix("筋トレ") {
            return "dumbbell"
        } else if taskType.contains("柔軟") {
            return "figure.flexibility"
        } else if taskType.contains("ヨガ") {
            return "figure.mind.and.body"
        } else if taskType.contains("ピラティス") {
            return "figure.pilates"
        }
        return "figure.walk"
    }
    
    private func getColorForTaskType(_ taskType: String) -> Color {
        if taskType.hasPrefix("サイクリング") {
            return .blue
        } else if taskType.hasPrefix("筋トレ") {
            return .orange
        } else if taskType.contains("柔軟") {
            return .green
        } else if taskType.contains("ヨガ") {
            return .purple
        } else if taskType.contains("ピラティス") {
            return .pink
        }
        return .gray
    }
}

// MARK: - Goal vs Achievement Section

struct GoalAchievementSection: View {
    let weightGoal: (current: Double?, target: Double, progress: String)?
    let ftpGoal: (current: Int?, target: Int, progress: String)?
    let workoutGoal: (current: Int, target: Int, progress: String)?
    
    var body: some View {
        SectionCard(title: "目標 vs 実績", icon: "chart.bar.fill", iconColor: .green) {
            VStack(spacing: 16) {
                if let weightGoal = weightGoal {
                    GoalProgressRow(
                        title: "体重管理",
                        current: weightGoal.current.map { String(format: "%.1f kg", $0) } ?? "未測定",
                        target: String(format: "%.1f kg", weightGoal.target),
                        progress: weightGoal.progress,
                        icon: "scalemass.fill",
                        color: .orange
                    )
                }
                
                if let ftpGoal = ftpGoal {
                    GoalProgressRow(
                        title: "FTP向上",
                        current: ftpGoal.current.map { "\($0)W" } ?? "未記録",
                        target: "\(ftpGoal.target)W",
                        progress: ftpGoal.progress,
                        icon: "bolt.fill",
                        color: .blue
                    )
                }
                
                if let workoutGoal = workoutGoal {
                    GoalProgressRow(
                        title: "月間トレーニング",
                        current: "\(workoutGoal.current)回",
                        target: "\(workoutGoal.target)回",
                        progress: workoutGoal.progress,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                
                if weightGoal == nil && ftpGoal == nil && workoutGoal == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("目標を設定して進捗を確認")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 80)
                }
            }
        }
    }
}

struct GoalProgressRow: View {
    let title: String
    let current: String
    let target: String
    let progress: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.bodyMedium.font)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColor.primaryText)
                
                HStack {
                    Text("現在: \(current)")
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                    
                    Text("→")
                        .font(Typography.captionSmall.font)
                        .foregroundColor(SemanticColor.tertiaryText)
                    
                    Text("目標: \(target)")
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                }
            }
            
            Spacer()
            
            Text(progress)
                .font(Typography.captionSmall.font)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Integrated Progress Chart

struct IntegratedProgressChart: View {
    let wprData: [WPRDataPoint]
    let weightData: [WeightDataPoint] 
    let ftpData: [FTPDataPoint]
    
    var body: some View {
        SectionCard(title: "統合進捗", icon: "chart.line.uptrend.xyaxis", iconColor: .purple) {
            if wprData.isEmpty && weightData.isEmpty && ftpData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("データを記録して\n統合進捗を確認しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
            } else {
                VStack(spacing: 16) {
                    // Chart placeholder - will be implemented with actual chart logic
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 120)
                        .overlay(
                            Text("統合チャート\n(WPR・体重・FTP)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        )
                    
                    // Legend
                    HStack(spacing: 16) {
                        if !wprData.isEmpty {
                            ChartLegendItem(color: .purple, label: "WPR")
                        }
                        if !weightData.isEmpty {
                            ChartLegendItem(color: .orange, label: "体重")
                        }
                        if !ftpData.isEmpty {
                            ChartLegendItem(color: .blue, label: "FTP")
                        }
                    }
                }
            }
        }
    }
}

struct ChartLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Training Intensity Balance

struct TrainingIntensitySection: View {
    let intensityData: [TrainingIntensityData]
    
    var body: some View {
        SectionCard(title: "種目別強度バランス", icon: "chart.pie.fill", iconColor: .indigo) {
            if intensityData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("トレーニング強度データを\n分析中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 100)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(Array(intensityData.prefix(4)), id: \.type) { data in
                        IntensityCard(
                            type: data.type,
                            weeklyHours: data.weeklyHours,
                            averageIntensity: data.averageIntensity,
                            trend: data.trend,
                            color: data.color
                        )
                    }
                }
            }
        }
    }
}

struct IntensityCard: View {
    let type: String
    let weeklyHours: Double
    let averageIntensity: String
    let trend: String
    let color: Color
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(alignment: .leading, spacing: 8) {
                Text(type)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                
                Text(String(format: "%.1fh", weeklyHours))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(averageIntensity)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(trend)
                    .font(.caption2)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Supporting Data Models

struct WPRDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct FTPDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let ftp: Int
}

struct TrainingIntensityData: Identifiable {
    let id = UUID()
    let type: String
    let weeklyHours: Double
    let averageIntensity: String
    let trend: String
    let color: Color
}