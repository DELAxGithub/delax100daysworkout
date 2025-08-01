import SwiftUI
import SwiftData

struct AIApprovalSheet: View {
    let session: PlanUpdateSession
    let planManager: WeeklyPlanManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingChangeDetails = false
    @State private var selectedChange: PlanChange?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    costSection
                    
                    reasoningSection
                    
                    changesSection
                    
                    confidenceSection
                    
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("AI提案の確認")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        planManager.rejectAISuggestion()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingChangeDetails) {
            if let change = selectedChange {
                ChangeDetailSheet(change: change)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading) {
                    Text("AI分析結果")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("あなたの進捗に基づく最適化提案")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
        }
    }
    
    private var costSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("分析コスト")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("$\(String(format: "%.4f", session.estimatedCost))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("信頼度")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(session.aiSuggestion.confidence * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(confidenceColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var reasoningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分析結果")
                .font(.headline)
            
            Text(session.aiSuggestion.reasoning)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var changesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("提案される変更")
                    .font(.headline)
                
                Spacer()
                
                Text("\(session.aiSuggestion.recommendedChanges.count)件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(session.aiSuggestion.recommendedChanges.enumerated()), id: \.offset) { index, change in
                    ChangeRowView(change: change) {
                        selectedChange = change
                        showingChangeDetails = true
                    }
                }
            }
        }
    }
    
    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("信頼度評価")
                .font(.headline)
            
            HStack {
                Text("AI信頼度")
                    .font(.subheadline)
                
                Spacer()
                
                ProgressView(value: session.aiSuggestion.confidence)
                    .frame(width: 100)
                    .tint(confidenceColor)
                
                Text("\(Int(session.aiSuggestion.confidence * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(confidenceColor)
            }
            
            Text(confidenceDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("提案を承認して適用") {
                Task {
                    await planManager.approveAISuggestion()
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .frame(maxWidth: .infinity)
            
            Button("提案を拒否") {
                planManager.rejectAISuggestion()
                dismiss()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .frame(maxWidth: .infinity)
        }
        .padding(.top)
    }
    
    private var confidenceColor: Color {
        if session.aiSuggestion.confidence >= 0.8 {
            return .green
        } else if session.aiSuggestion.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var confidenceDescription: String {
        if session.aiSuggestion.confidence >= 0.8 {
            return "高い信頼度。提案された変更は安全で効果的です。"
        } else if session.aiSuggestion.confidence >= 0.6 {
            return "中程度の信頼度。慎重に検討してください。"
        } else {
            return "低い信頼度。手動での調整を推奨します。"
        }
    }
}

struct ChangeRowView: View {
    let change: PlanChange
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        changeTypeIcon
                        
                        Text(change.taskTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(dayOfWeekName(change.dayOfWeek))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Text(change.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var changeTypeIcon: some View {
        Group {
            switch change.changeType {
            case .modify:
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.blue)
            case .add:
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
            case .remove:
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            case .intensity:
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func dayOfWeekName(_ dayOfWeek: Int) -> String {
        let days = ["日", "月", "火", "水", "木", "金", "土"]
        return days[dayOfWeek]
    }
}

struct ChangeDetailSheet: View {
    let change: PlanChange
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    
                    reasonSection
                    
                    if let oldDetails = change.oldDetails {
                        comparisonSection(oldDetails: oldDetails)
                    } else {
                        newDetailsSection
                    }
                }
                .padding()
            }
            .navigationTitle("変更詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                switch change.changeType {
                case .modify:
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                case .add:
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                case .remove:
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                case .intensity:
                    Image(systemName: "bolt.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading) {
                    Text(change.taskTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(dayOfWeekName(change.dayOfWeek) + "曜日")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
        }
    }
    
    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("変更理由")
                .font(.headline)
            
            Text(change.reason)
                .font(.subheadline)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private func comparisonSection(oldDetails: TargetDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("変更内容")
                .font(.headline)
            
            HStack(alignment: .top, spacing: 16) {
                // Before
                VStack(alignment: .leading, spacing: 8) {
                    Text("変更前")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    TargetDetailsView(details: oldDetails)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                
                // After
                VStack(alignment: .leading, spacing: 8) {
                    Text("変更後")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    TargetDetailsView(details: change.newDetails)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var newDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("新しい内容")
                .font(.headline)
            
            TargetDetailsView(details: change.newDetails)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private func dayOfWeekName(_ dayOfWeek: Int) -> String {
        let days = ["日", "月", "火", "水", "木", "金", "土"]
        return days[dayOfWeek]
    }
}

struct TargetDetailsView: View {
    let details: TargetDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let exercises = details.exercises, !exercises.isEmpty {
                Text("エクササイズ: \(exercises.joined(separator: ", "))")
                    .font(.caption)
            }
            
            if let sets = details.targetSets, let reps = details.targetReps {
                Text("セット: \(sets) × \(reps)")
                    .font(.caption)
            }
            
            if let power = details.targetPower {
                Text("目標パワー: \(power)W")
                    .font(.caption)
            }
            
            if let duration = details.duration {
                Text("時間: \(duration)分")
                    .font(.caption)
            }
            
            if let targetDuration = details.targetDuration {
                Text("目標時間: \(targetDuration)分")
                    .font(.caption)
            }
            
            if let forwardBend = details.targetForwardBend {
                Text("前屈: \(String(format: "%.1f", forwardBend))cm")
                    .font(.caption)
            }
            
            if let splitAngle = details.targetSplitAngle {
                Text("開脚角度: \(String(format: "%.0f", splitAngle))°")
                    .font(.caption)
            }
        }
    }
}

#Preview {
    AIApprovalSheet(
        session: PlanUpdateSession(
            currentTemplate: WeeklyTemplate.createDefaultTemplate(),
            aiSuggestion: WeeklyPlanSuggestion(
                recommendedChanges: [
                    PlanChange(
                        dayOfWeek: 1,
                        changeType: .modify,
                        taskTitle: "Push筋トレ",
                        oldDetails: nil,
                        newDetails: TargetDetails(exercises: ["ベンチプレス", "ダンベルプレス"], targetSets: 4, targetReps: 12),
                        reason: "前週の完了率が高く、強度を上げることが可能"
                    )
                ],
                reasoning: "全体的なパフォーマンスが向上しているため、強度を調整しました。",
                estimatedCost: 0.0234,
                confidence: 0.85
            ),
            estimatedCost: 0.0234
        ),
        planManager: WeeklyPlanManager(modelContext: ModelContext(try! ModelContainer(for: WorkoutRecord.self)))
    )
}