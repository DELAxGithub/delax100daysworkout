import SwiftUI
import SwiftData
import OSLog

struct WorkoutRecordCRUDView: View {
    @StateObject private var viewModel = WorkoutRecordViewModel()
    @State private var selectedRecord: WorkoutRecord?
    @State private var showingCreateForm = false
    @State private var showingEditForm = false
    @State private var showingDetailView = false
    
    var body: some View {
        CRUDMasterView.workoutRecordView()
    }
    
    private var workoutFilterSection: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Workout Type", selection: $selectedWorkoutType) {
                    Text("All Types").tag(nil as WorkoutType?)
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.iconName)
                            .tag(type as WorkoutType?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Toggle("Completed Only", isOn: $showCompletedOnly)
                    .toggleStyle(SwitchToggleStyle())
            }
            .padding(.horizontal)
            
            Divider()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.mixed.cardio")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Workout Records")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start tracking your workouts")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Create First Workout") {
                showingCreateForm = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var recordsList: some View {
        List {
            ForEach(filteredRecords) { record in
                WorkoutRecordRow(
                    record: record,
                    onTap: {
                        selectedRecord = record
                        showingDetailView = true
                    },
                    onEdit: {
                        selectedRecord = record
                        showingEditForm = true
                    },
                    onToggleComplete: {
                        Task {
                            await toggleCompletion(record)
                        }
                    }
                )
            }
            .onDelete(perform: deleteRecords)
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredRecords: [WorkoutRecord] {
        workoutRecords.filter { record in
            let matchesSearch = searchText.isEmpty || 
                record.summary.localizedCaseInsensitiveContains(searchText) ||
                record.workoutType.rawValue.localizedCaseInsensitiveContains(searchText)
            
            let matchesType = selectedWorkoutType == nil || record.workoutType == selectedWorkoutType
            
            let matchesCompletion = !showCompletedOnly || record.isCompleted
            
            return matchesSearch && matchesType && matchesCompletion
        }
    }
    
    private var createWorkoutForm: some View {
        WorkoutRecordFormView(
            mode: .create,
            onSave: { record in
                Task {
                    await createRecord(record)
                }
                showingCreateForm = false
            },
            onCancel: {
                showingCreateForm = false
            }
        )
    }
    
    private var editWorkoutForm: some View {
        WorkoutRecordFormView(
            mode: .edit(selectedRecord!),
            onSave: { record in
                Task {
                    await updateRecord(record)
                }
                showingEditForm = false
            },
            onCancel: {
                showingEditForm = false
            }
        )
    }
    
    private var detailWorkoutView: some View {
        WorkoutRecordDetailView(record: selectedRecord!)
    }
    
    // MARK: - CRUD Operations
    
    @MainActor
    private func loadWorkoutRecords() async {
        let predicate = createPredicate()
        let sortDescriptors = [SortDescriptor(\WorkoutRecord.date, order: .reverse)]
        
        workoutRecords = await crudEngine.fetch(
            predicate: predicate,
            sortBy: sortDescriptors
        )
        
        logger.info("Loaded \(workoutRecords.count) workout records")
    }
    
    private func createPredicate() -> Predicate<WorkoutRecord>? {
        var predicates: [Predicate<WorkoutRecord>] = []
        
        if !searchText.isEmpty {
            let searchPredicate = #Predicate<WorkoutRecord> { record in
                record.summary.localizedStandardContains(searchText)
            }
            predicates.append(searchPredicate)
        }
        
        if let workoutType = selectedWorkoutType {
            let typePredicate = #Predicate<WorkoutRecord> { record in
                record.workoutType == workoutType
            }
            predicates.append(typePredicate)
        }
        
        if showCompletedOnly {
            let completedPredicate = #Predicate<WorkoutRecord> { record in
                record.isCompleted == true
            }
            predicates.append(completedPredicate)
        }
        
        return predicates.isEmpty ? nil : predicates.reduce(predicates[0]) { result, predicate in
            return #Predicate<WorkoutRecord> { record in
                result.evaluate(record) && predicate.evaluate(record)
            }
        }
    }
    
    @MainActor
    private func createRecord(_ record: WorkoutRecord) async {
        let success = await crudEngine.create(record)
        if success {
            await loadWorkoutRecords()
        }
    }
    
    @MainActor
    private func updateRecord(_ record: WorkoutRecord) async {
        await loadWorkoutRecords()
        logger.info("Updated workout record: \(record.summary)")
    }
    
    @MainActor
    private func toggleCompletion(_ record: WorkoutRecord) async {
        record.isCompleted.toggle()
        if record.isCompleted {
            record.markAsCompleted(modelContext: modelContext)
        }
        await loadWorkoutRecords()
    }
    
    private func deleteRecords(offsets: IndexSet) {
        for index in offsets {
            let record = filteredRecords[index]
            Task {
                await deleteRecord(record)
            }
        }
    }
    
    @MainActor
    private func deleteRecord(_ record: WorkoutRecord) async {
        let success = await crudEngine.delete(record)
        if success {
            await loadWorkoutRecords()
        }
    }
}

struct WorkoutRecordRow: View {
    let record: WorkoutRecord
    let onTap: () -> Void
    let onEdit: () -> Void
    let onToggleComplete: () -> Void
    
    var body: some View {
        HStack {
            // Workout Type Icon
            Label("", systemImage: record.workoutType.iconName)
                .foregroundColor(record.workoutType.iconColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.summary)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(record.workoutType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Button(action: onToggleComplete) {
                    Image(systemName: record.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(record.isCompleted ? .green : .gray)
                        .font(.title3)
                }
                
                Menu {
                    Button("Edit", action: onEdit)
                    Button("View Details", action: onTap)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}