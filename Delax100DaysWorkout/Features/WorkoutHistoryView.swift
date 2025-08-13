import SwiftUI
import SwiftData

// MARK: - Main View

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var workoutRecords: [WorkoutRecord]
    
    @State private var showingFilterSheet = false
    @State private var selectedWorkoutType: WorkoutType? = nil
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: WorkoutRecord?
    @State private var searchText = ""
    @State private var showingBulkDeleteAlert = false
    @State private var isEditMode = false
    @State private var selectedWorkouts: Set<WorkoutRecord.ID> = []
    
    private var filteredWorkouts: [WorkoutRecord] {
        var filtered = workoutRecords
        
        // フィルター適用
        if let selectedType = selectedWorkoutType {
            filtered = filtered.filter { $0.workoutType == selectedType }
        }
        
        filtered = filtered.filter { $0.date >= startDate && $0.date <= endDate }
        
        // 検索適用
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.summary.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                BaseCard(style: DefaultCardStyle()) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(SemanticColor.secondaryText)
                        TextField("ワークアウト検索...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(Typography.bodyMedium.font)
                        
                        if !searchText.isEmpty {
                            Button("クリア") {
                                searchText = ""
                            }
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.primaryAction)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Summary Cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        HistorySummaryCard(
                            title: "総回数",
                            value: "\(filteredWorkouts.count)",
                            subtitle: "ワークアウト",
                            color: .green,
                            icon: "figure.run"
                        )
                        
                        HistorySummaryCard(
                            title: "今月",
                            value: "\(currentMonthCount)",
                            subtitle: "回",
                            color: .blue,
                            icon: "calendar"
                        )
                        
                        HistorySummaryCard(
                            title: "完了率",
                            value: "\(completionRate)%",
                            subtitle: "達成",
                            color: .orange,
                            icon: "checkmark.circle.fill"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                if filteredWorkouts.isEmpty {
                    ContentUnavailableView(
                        "ワークアウト履歴なし",
                        systemImage: "figure.run.circle",
                        description: Text(searchText.isEmpty ? "ワークアウトを記録して履歴を確認しましょう" : "検索条件に一致するワークアウトが見つかりません")
                    )
                } else {
                    List {
                        ForEach(filteredWorkouts) { workout in
                            WorkoutHistoryRow(
                                workout: workout,
                                isEditMode: isEditMode,
                                isSelected: selectedWorkouts.contains(workout.id),
                                onEdit: { editedWorkout in
                                    updateWorkout(workout, with: editedWorkout)
                                },
                                onDelete: { workoutToDelete in
                                    self.workoutToDelete = workoutToDelete
                                    showingDeleteAlert = true
                                },
                                onSelect: { isSelected in
                                    if isSelected {
                                        selectedWorkouts.insert(workout.id)
                                    } else {
                                        selectedWorkouts.remove(workout.id)
                                    }
                                }
                            )
                        }
                        .onDelete(perform: isEditMode ? nil : deleteWorkouts)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("ワークアウト履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !filteredWorkouts.isEmpty {
                        Button(isEditMode ? "完了" : "編集") {
                            withAnimation {
                                isEditMode.toggle()
                                if !isEditMode {
                                    selectedWorkouts.removeAll()
                                }
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isEditMode && !filteredWorkouts.isEmpty {
                            if selectedWorkouts.isEmpty {
                                Button("全選択") {
                                    selectedWorkouts = Set(filteredWorkouts.map { $0.id })
                                }
                                .foregroundColor(.blue)
                            } else {
                                Button("選択削除(\(selectedWorkouts.count))") {
                                    showingBulkDeleteAlert = true
                                }
                                .foregroundColor(.red)
                                
                                Button("全削除") {
                                    selectedWorkouts = Set(filteredWorkouts.map { $0.id })
                                    showingBulkDeleteAlert = true
                                }
                                .foregroundColor(.red)
                            }
                        }
                        
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                WorkoutFilterSheet(
                    selectedWorkoutType: $selectedWorkoutType,
                    startDate: $startDate,
                    endDate: $endDate
                )
            }
            .alert("ワークアウトを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let workout = workoutToDelete {
                        deleteWorkout(workout)
                        workoutToDelete = nil
                    }
                }
                Button("キャンセル", role: .cancel) {
                    workoutToDelete = nil
                }
            } message: {
                Text("このワークアウト記録を削除してもよろしいですか？この操作は取り消せません。")
            }
            .alert("ワークアウトを削除", isPresented: $showingBulkDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteSelectedWorkouts()
                    selectedWorkouts.removeAll()
                    isEditMode = false
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("\(selectedWorkouts.count)件のワークアウトを削除してもよろしいですか？この操作は取り消せません。")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentMonthCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return filteredWorkouts.filter { 
            $0.date >= startOfMonth && $0.date <= now 
        }.count
    }
    
    private var completionRate: Int {
        guard !filteredWorkouts.isEmpty else { return 0 }
        let completedCount = filteredWorkouts.filter { $0.isCompleted }.count
        return Int((Double(completedCount) / Double(filteredWorkouts.count)) * 100)
    }
    
    // MARK: - Methods
    
    private func updateWorkout(_ workout: WorkoutRecord, with editedWorkout: WorkoutRecord) {
        workout.summary = editedWorkout.summary
        workout.workoutType = editedWorkout.workoutType
        workout.date = editedWorkout.date
        workout.isCompleted = editedWorkout.isCompleted
        
        try? modelContext.save()
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredWorkouts[index])
            }
            try? modelContext.save()
        }
    }
    
    private func deleteWorkout(_ workout: WorkoutRecord) {
        withAnimation {
            modelContext.delete(workout)
            try? modelContext.save()
        }
    }
    
    private func deleteSelectedWorkouts() {
        withAnimation {
            let workoutsToDelete = filteredWorkouts.filter { selectedWorkouts.contains($0.id) }
            for workout in workoutsToDelete {
                modelContext.delete(workout)
            }
            try? modelContext.save()
        }
    }
}


#Preview {
    WorkoutHistoryView()
        .modelContainer(for: [WorkoutRecord.self])
}