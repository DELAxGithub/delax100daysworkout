import SwiftUI
import SwiftData
import OSLog

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
    @State private var showingBulkDeleteAlert = false
    @State private var isEditMode = false
    @State private var selectedWorkouts: Set<WorkoutRecord.ID> = []
    
    // Search functionality
    @State private var searchText = ""
    @State private var selectedSort: SearchConfiguration.SortOption = .dateNewest
    @State private var isSearchActive = false
    private let searchViewModel = HistorySearchViewModel<WorkoutRecord>()
    
    private var filteredWorkouts: [WorkoutRecord] {
        var filtered = workoutRecords
        
        // Update search view model with all records
        searchViewModel.updateRecords(filtered)
        
        // Apply search if active
        if isSearchActive && !searchText.isEmpty {
            filtered = searchViewModel.filteredRecords
        } else if !searchText.isEmpty {
            // Fallback to basic search
            filtered = HistorySearchEngine.filterRecords(filtered, searchText: searchText, sortOption: selectedSort)
        } else {
            // Apply manual sorting when no search
            filtered = HistorySearchEngine.filterRecords(filtered, searchText: "", sortOption: selectedSort)
        }
        
        // Apply additional filters
        if let selectedType = selectedWorkoutType {
            filtered = filtered.filter { $0.workoutType == selectedType }
        }
        
        filtered = filtered.filter { $0.date >= startDate && $0.date <= endDate }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Unified Search Bar
                UnifiedSearchBar(
                    searchText: $searchText,
                    selectedSort: $selectedSort,
                    isSearchActive: $isSearchActive,
                    configuration: .workoutHistory,
                    onClear: {
                        searchText = ""
                        isSearchActive = false
                        searchViewModel.clearSearch()
                    }
                )
                .padding(.horizontal)
                .onChange(of: searchText) { _, newValue in
                    searchViewModel.searchText = newValue
                    searchViewModel.activateSearch()
                    isSearchActive = !newValue.isEmpty
                }
                .onChange(of: selectedSort) { _, newValue in
                    searchViewModel.selectedSort = newValue
                }
                
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
                            DraggableWorkoutHistoryRow(
                                workout: workout,
                                isEditMode: isEditMode,
                                isSelected: selectedWorkouts.contains(workout.id),
                                onEdit: { _ in
                                    // onEdit callback kept for compatibility
                                    // But actual editing is handled by WorkoutEditSheet directly
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
                                },
                                onMove: { draggedWorkout, targetWorkout in
                                    moveWorkout(draggedWorkout, to: targetWorkout)
                                }
                            )
                        }
                        .onDelete(perform: isEditMode ? nil : deleteWorkouts)
                        .onMove(perform: isEditMode ? nil : moveWorkouts)
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
    
    // MARK: - Drag & Drop Support
    
    private func moveWorkouts(from source: IndexSet, to destination: Int) {
        // For now, we'll just update the dates to maintain order
        // This is a simple approach for workout history reordering
        var workouts = filteredWorkouts
        workouts.move(fromOffsets: source, toOffset: destination)
        
        // Update dates to maintain the new order
        let baseDate = Date()
        for (index, workout) in workouts.enumerated() {
            let timeInterval = TimeInterval(-index * 60) // 1 minute intervals
            workout.date = baseDate.addingTimeInterval(timeInterval)
        }
        
        do {
            try modelContext.save()
            HapticManager.shared.trigger(.impact(.medium))
        } catch {
            Logger.error.error("Error reordering workouts: \(error.localizedDescription)")
            HapticManager.shared.trigger(.notification(.error))
        }
    }
    
    private func moveWorkout(_ draggedWorkout: WorkoutRecord, to targetWorkout: WorkoutRecord) {
        // Find indices
        guard let draggedIndex = filteredWorkouts.firstIndex(of: draggedWorkout),
              let targetIndex = filteredWorkouts.firstIndex(of: targetWorkout) else {
            return
        }
        
        // Move the workout
        let sourceIndexSet = IndexSet(integer: draggedIndex)
        let destinationIndex = targetIndex
        
        moveWorkouts(from: sourceIndexSet, to: destinationIndex)
    }
}


#Preview {
    WorkoutHistoryView()
        .modelContainer(for: [WorkoutRecord.self])
}