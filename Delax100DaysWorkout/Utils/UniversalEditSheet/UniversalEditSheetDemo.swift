import SwiftUI
import SwiftData

// MARK: - Universal Edit Sheet Demo & Testing

struct UniversalEditSheetDemo: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingWorkoutEdit = false
    @State private var showingMetricEdit = false
    @State private var showingTaskEdit = false
    @State private var showingProfileEdit = false
    
    @State private var testWorkout: WorkoutRecord?
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg.value) {
                    // Header
                    headerSection
                    
                    // Model Testing Buttons
                    testingSection
                    
                    // Test Results
                    if !testResults.isEmpty {
                        resultsSection
                    }
                    
                    // Usage Examples
                    examplesSection
                }
                .padding(.horizontal)
            }
            .background(SemanticColor.primaryBackground.color)
            .navigationTitle("Universal Edit Sheet")
            .navigationBarTitleDisplayMode(.large)
        }
        .universalEditSheet(
            for: WorkoutRecord.self,
            isPresented: $showingWorkoutEdit,
            existingModel: testWorkout
        ) { savedWorkout in
            testResults.append("✅ WorkoutRecord saved: \(savedWorkout.summary)")
        }
        .universalEditSheet(
            for: DailyMetric.self,
            isPresented: $showingMetricEdit
        ) { savedMetric in
            testResults.append("✅ DailyMetric saved for date: \(savedMetric.date)")
        }
        .universalEditSheet(
            for: DailyTask.self,
            isPresented: $showingTaskEdit
        ) { savedTask in
            testResults.append("✅ DailyTask saved: \(savedTask.title)")
        }
        .universalEditSheet(
            for: UserProfile.self,
            isPresented: $showingProfileEdit
        ) { savedProfile in
            testResults.append("✅ UserProfile saved: \(savedProfile.name ?? "Unnamed")")
        }
        .onAppear {
            setupTestData()
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Universal Edit Sheet System")
                            .font(Typography.headlineMedium.font)
                            .foregroundColor(SemanticColor.primaryText.color)
                        
                        Text("19+モデル対応の汎用編集システム")
                            .font(Typography.bodyMedium.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    FeatureBadge(title: "型安全", icon: "checkmark.shield", color: .green)
                    FeatureBadge(title: "自動UI生成", icon: "wand.and.rays", color: .blue)
                    FeatureBadge(title: "バリデーション統合", icon: "checkmark.circle", color: .orange)
                    FeatureBadge(title: "BaseCard統合", icon: "rectangle.stack", color: .purple)
                }
            }
            .padding(Spacing.md.value)
        }
    }
    
    private var testingSection: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                HStack {
                    Text("モデル別テスト")
                        .font(Typography.headlineSmall.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.md.value) {
                    
                    ModelTestButton(
                        title: "WorkoutRecord",
                        subtitle: "607行→自動生成",
                        icon: "figure.strengthtraining.traditional",
                        color: .orange
                    ) {
                        showingWorkoutEdit = true
                    }
                    
                    ModelTestButton(
                        title: "DailyMetric",
                        subtitle: "体重・体組成記録",
                        icon: "scalemass",
                        color: .blue
                    ) {
                        showingMetricEdit = true
                    }
                    
                    ModelTestButton(
                        title: "DailyTask",
                        subtitle: "タスク管理",
                        icon: "checklist",
                        color: .green
                    ) {
                        showingTaskEdit = true
                    }
                    
                    ModelTestButton(
                        title: "UserProfile",
                        subtitle: "ユーザープロフィール",
                        icon: "person.circle",
                        color: .purple
                    ) {
                        showingProfileEdit = true
                    }
                }
            }
            .padding(Spacing.md.value)
        }
    }
    
    private var resultsSection: some View {
        BaseCard(style: OutlinedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundColor(.green)
                    Text("テスト結果")
                        .font(Typography.headlineSmall.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                    
                    Button("クリア") {
                        testResults.removeAll()
                    }
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.secondaryAction.color)
                }
                
                ForEach(testResults, id: \.self) { result in
                    Text(result)
                        .font(Typography.bodySmall.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                }
            }
            .padding(Spacing.md.value)
        }
    }
    
    private var examplesSection: some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                HStack {
                    Text("使用例")
                        .font(Typography.headlineSmall.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    CodeExample(
                        title: "新規作成",
                        code: ".universalEditSheet(for: WorkoutRecord.self, isPresented: $showEdit)"
                    )
                    
                    CodeExample(
                        title: "既存編集",
                        code: ".universalEditSheet(for: WorkoutRecord.self, existingModel: workout)"
                    )
                    
                    CodeExample(
                        title: "読み取り専用",
                        code: ".universalViewSheet(for: workout, isPresented: $showView)"
                    )
                }
            }
            .padding(Spacing.md.value)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupTestData() {
        // Create a sample workout for editing
        testWorkout = WorkoutRecord(
            date: Date(),
            workoutType: .cycling,
            summary: "テスト用ワークアウト"
        )
        
        testResults.append("🚀 Universal Edit Sheet System initialized")
        testResults.append("📊 Analyzing 19+ SwiftData models...")
        testResults.append("✅ System ready for testing")
    }
}

// MARK: - Supporting Views

struct FeatureBadge: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.xs.value) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(title)
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.primaryText.color)
        }
        .padding(.vertical, Spacing.xs.value)
        .padding(.horizontal, Spacing.sm.value)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ModelTestButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm.value) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: Spacing.xs.value) {
                    Text(title)
                        .font(Typography.labelMedium.font)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Text(subtitle)
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md.value)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium.value)
                    .fill(SemanticColor.surfaceBackground.color)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CodeExample: View {
    let title: String
    let code: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.value) {
            Text(title)
                .font(Typography.captionMedium.font)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColor.primaryText.color)
            
            Text(code)
                .font(.system(size: 12, family: .monospaced))
                .foregroundColor(SemanticColor.secondaryText.color)
                .padding(.horizontal, Spacing.sm.value)
                .padding(.vertical, Spacing.xs.value)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small.value)
                        .fill(SemanticColor.surfaceBackground.color.opacity(0.5))
                )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UniversalEditSheetDemo()
    }
    .modelContainer(for: [
        WorkoutRecord.self,
        DailyMetric.self,
        DailyTask.self,
        UserProfile.self
    ])
}