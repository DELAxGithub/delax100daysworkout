import SwiftUI
import SwiftData

struct WeeklyScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WeeklyTemplate> { $0.isActive }) private var activeTemplates: [WeeklyTemplate]
    
    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date()) - 1
    
    private let dayNames = ["日", "月", "火", "水", "木", "金", "土"]
    private let dayColors: [Color] = [.red, .gray, .gray, .gray, .gray, .gray, .blue]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 曜日セレクター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<7) { day in
                            DayButton(
                                day: day,
                                dayName: dayNames[day],
                                isSelected: selectedDay == day,
                                color: dayColors[day]
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDay = day
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                Divider()
                
                // タスクリスト
                if let template = activeTemplates.first {
                    let tasks = template.tasksForDay(selectedDay)
                    
                    if tasks.isEmpty {
                        ContentUnavailableView(
                            "休息日",
                            systemImage: "moon.zzz",
                            description: Text("\(dayNames[selectedDay])曜日はトレーニングがありません")
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(tasks) { task in
                                    WeeklyTaskCard(task: task)
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "テンプレートがありません",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("アクティブなテンプレートを作成してください")
                    )
                }
            }
            .navigationTitle("週間スケジュール")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        jumpToToday()
                    } label: {
                        Label("今日へ", systemImage: "calendar.day.timeline.left")
                    }
                }
            }
        }
        .onAppear {
            ensureActiveTemplate()
        }
    }
    
    private func jumpToToday() {
        withAnimation(.spring(response: 0.3)) {
            selectedDay = Calendar.current.component(.weekday, from: Date()) - 1
        }
    }
    
    private func ensureActiveTemplate() {
        if activeTemplates.isEmpty {
            let defaultTemplate = WeeklyTemplate.createDefaultTemplate()
            defaultTemplate.activate()
            modelContext.insert(defaultTemplate)
        }
    }
}

struct DayButton: View {
    let day: Int
    let dayName: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : color)
                
                if isToday() {
                    Circle()
                        .fill(isSelected ? Color.white : color)
                        .frame(width: 6, height: 6)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : Color(.systemGray6))
            )
        }
    }
    
    private func isToday() -> Bool {
        Calendar.current.component(.weekday, from: Date()) - 1 == day
    }
}

struct WeeklyTaskCard: View {
    let task: DailyTask
    
    private var workoutIcon: String {
        switch task.workoutType {
        case .cycling:
            return "bicycle"
        case .strength:
            return "figure.strengthtraining.traditional"
        case .flexibility:
            return "figure.flexibility"
        }
    }
    
    private var workoutColor: Color {
        switch task.workoutType {
        case .cycling:
            return .blue
        case .strength:
            return .orange
        case .flexibility:
            return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Image(systemName: workoutIcon)
                    .font(.title2)
                    .foregroundColor(workoutColor)
                    .frame(width: 40, height: 40)
                    .background(workoutColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                    
                    if let description = task.taskDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if task.isFlexible {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            
            // 詳細情報
            if let details = task.targetDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    switch task.workoutType {
                    case .cycling:
                        CyclingDetailsView(details: details)
                    case .strength:
                        StrengthDetailsView(details: details)
                    case .flexibility:
                        FlexibilityDetailsView(details: details)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct CyclingDetailsView: View {
    let details: TargetDetails
    
    var body: some View {
        HStack(spacing: 20) {
            if let duration = details.duration {
                DetailItem(
                    icon: "clock",
                    label: "時間",
                    value: "\(duration)分"
                )
            }
            
            if let intensity = details.intensity {
                DetailItem(
                    icon: "bolt",
                    label: "強度",
                    value: intensity.displayName
                )
            }
            
            if let power = details.targetPower {
                DetailItem(
                    icon: "speedometer",
                    label: "パワー",
                    value: "\(power)W"
                )
            }
        }
    }
}

struct StrengthDetailsView: View {
    let details: TargetDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let exercises = details.exercises, !exercises.isEmpty {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.secondary)
                    Text(exercises.joined(separator: ", "))
                        .font(.caption)
                }
            }
            
            HStack(spacing: 20) {
                if let sets = details.targetSets {
                    DetailItem(
                        icon: "repeat",
                        label: "セット",
                        value: "\(sets)"
                    )
                }
                
                if let reps = details.targetReps {
                    DetailItem(
                        icon: "number",
                        label: "レップ",
                        value: "\(reps)"
                    )
                }
            }
        }
    }
}

struct FlexibilityDetailsView: View {
    let details: TargetDetails
    
    var body: some View {
        HStack(spacing: 20) {
            if let duration = details.targetDuration {
                DetailItem(
                    icon: "clock",
                    label: "時間",
                    value: "\(duration)分"
                )
            }
            
            if let forwardBend = details.targetForwardBend {
                DetailItem(
                    icon: "arrow.down",
                    label: "前屈",
                    value: "\(forwardBend)cm"
                )
            }
            
            if let splitAngle = details.targetSplitAngle {
                DetailItem(
                    icon: "angle",
                    label: "開脚",
                    value: "\(splitAngle)°"
                )
            }
        }
    }
}

struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
}

// プレビュー用の拡張
extension CyclingIntensity {
    var displayName: String {
        switch self {
        case .endurance: return "Endurance"
        case .sst: return "SST"
        case .vo2max: return "VO2max"
        case .recovery: return "Recovery"
        case .z2: return "Zone 2"
        case .tempo: return "Tempo"
        case .anaerobic: return "Anaerobic"
        case .sprint: return "Sprint"
        }
    }
}

#Preview {
    WeeklyScheduleView()
        .modelContainer(for: [WeeklyTemplate.self], inMemory: true)
}