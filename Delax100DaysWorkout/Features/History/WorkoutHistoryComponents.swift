import SwiftUI
import SwiftData

// MARK: - Workout History Row

struct WorkoutHistoryRow: View {
    let workout: WorkoutRecord
    let isEditMode: Bool
    let isSelected: Bool
    let onEdit: (WorkoutRecord) -> Void
    let onDelete: (WorkoutRecord) -> Void
    let onSelect: (Bool) -> Void
    
    @State private var showingEditSheet = false
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                HStack {
                    // 編集モードでの選択チェックボックス
                    if isEditMode {
                        Button(action: {
                            onSelect(!isSelected)
                        }) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? SemanticColor.primaryAction : SemanticColor.secondaryText)
                                .font(Typography.headlineSmall.font)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Image(systemName: workout.workoutType.iconName)
                        .foregroundColor(workout.workoutType.iconColor)
                        .font(Typography.headlineSmall.font)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs.value) {
                        Text(workout.summary)
                            .font(Typography.headlineMedium.font)
                            .foregroundColor(SemanticColor.primaryText)
                            .lineLimit(2)
                        
                        Text(workout.workoutType.rawValue)
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: Spacing.xs.value) {
                        Text(workout.date, format: .dateTime.month().day().hour().minute())
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                        
                        if workout.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(SemanticColor.successAction)
                                .font(Typography.captionMedium.font)
                        }
                        
                        if workout.isQuickRecord {
                            Text("クイック記録")
                                .font(Typography.captionSmall.font)
                                .padding(.horizontal, Spacing.xs.value)
                                .padding(.vertical, Spacing.xs.value)
                                .background(SemanticColor.primaryAction.color.opacity(0.1))
                                .cornerRadius(CornerRadius.small.radius)
                                .foregroundColor(SemanticColor.primaryAction)
                        }
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xs.value)
        .contentShape(Rectangle())
        .onLongPressGesture {
            if !isEditMode {
                showingEditSheet = true
            }
        }
        .onTapGesture {
            if isEditMode {
                onSelect(!isSelected)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !isEditMode {
                Button("編集") {
                    showingEditSheet = true
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isEditMode {
                Button("削除", role: .destructive) {
                    onDelete(workout)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            WorkoutEditSheet(workoutRecord: workout)
        }
    }
}

// MARK: - Workout History Edit Sheet

struct WorkoutHistoryEditSheet: View {
    let workout: WorkoutRecord
    let onSave: (WorkoutRecord) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var editedSummary: String = ""
    @State private var editedWorkoutType: WorkoutType = .cycling
    @State private var editedDate: Date = Date()
    @State private var editedIsCompleted: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("ワークアウト名", text: $editedSummary)
                    
                    Picker("種類", selection: $editedWorkoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    
                    DatePicker("日時", selection: $editedDate)
                    
                    Toggle("完了済み", isOn: $editedIsCompleted)
                }
                
                Section {
                    Text("※ 詳細編集は元のワークアウト編集画面をご利用ください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("ワークアウト編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let editedWorkout = WorkoutRecord(
                            date: editedDate,
                            workoutType: editedWorkoutType,
                            summary: editedSummary
                        )
                        editedWorkout.isCompleted = editedIsCompleted
                        onSave(editedWorkout)
                        dismiss()
                    }
                    .disabled(editedSummary.isEmpty)
                }
            }
        }
        .onAppear {
            editedSummary = workout.summary
            editedWorkoutType = workout.workoutType
            editedDate = workout.date
            editedIsCompleted = workout.isCompleted
        }
    }
}

// MARK: - Filter Sheet

struct WorkoutFilterSheet: View {
    @Binding var selectedWorkoutType: WorkoutType?
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("ワークアウト種類") {
                    Picker("種類フィルター", selection: $selectedWorkoutType) {
                        Text("全て").tag(WorkoutType?.none)
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(WorkoutType?.some(type))
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("期間") {
                    DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                    DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                }
                
                Section {
                    Button("フィルターをリセット") {
                        selectedWorkoutType = nil
                        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                        endDate = Date()
                    }
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - History Summary Card

struct HistorySummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(Typography.captionMedium.font)
                    Spacer()
                }
                
                Text(value)
                    .font(Typography.headlineSmall.font)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColor.primaryText)
                
                Text(title)
                    .font(Typography.captionSmall.font)
                    .foregroundColor(SemanticColor.secondaryText)
            }
        }
        .frame(width: 80, height: 60)
    }
}