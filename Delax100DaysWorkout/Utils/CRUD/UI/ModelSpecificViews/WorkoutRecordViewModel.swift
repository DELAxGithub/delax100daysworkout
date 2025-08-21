import SwiftUI
import SwiftData
import OSLog

@MainActor
class WorkoutRecordViewModel: ObservableObject {
    @Published var workoutRecords: [WorkoutRecord] = []
    @Published var searchText = ""
    @Published var selectedWorkoutType: WorkoutType?
    @Published var showCompletedOnly = false
    
    private let crudEngine: CRUDEngine<WorkoutRecord>
    private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "WorkoutRecordViewModel")
    
    init(modelContext: ModelContext) {
        self.crudEngine = CRUDEngine<WorkoutRecord>(
            modelContext: modelContext,
            errorHandler: ErrorHandler()
        )
    }
    
    func loadWorkoutRecords() async {
        let predicate = createPredicate()
        let sortDescriptors = [SortDescriptor(\WorkoutRecord.date, order: .reverse)]
        
        workoutRecords = await crudEngine.fetch(
            predicate: predicate,
            sortBy: sortDescriptors
        )
        
        logger.info("Loaded \(self.workoutRecords.count) workout records")
    }
    
    private func createPredicate() -> Predicate<WorkoutRecord>? {
        var predicates: [Predicate<WorkoutRecord>] = []
        
        if !searchText.isEmpty {
            let searchText = self.searchText
            let searchPredicate = #Predicate<WorkoutRecord> { record in
                record.summary.localizedStandardContains(searchText)
            }
            predicates.append(searchPredicate)
        }
        
        if let workoutType = selectedWorkoutType {
            let selectedType = workoutType
            let typePredicate = #Predicate<WorkoutRecord> { record in
                record.workoutType == selectedType
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
    
    func createRecord(_ record: WorkoutRecord) async {
        let success = await crudEngine.create(record)
        if success {
            await loadWorkoutRecords()
        }
    }
    
    func updateRecord(_ record: WorkoutRecord) async {
        await loadWorkoutRecords()
        logger.info("Updated workout record: \(record.summary)")
    }
    
    func deleteRecord(_ record: WorkoutRecord) async {
        let success = await crudEngine.delete(record)
        if success {
            await loadWorkoutRecords()
        }
    }
    
    func toggleCompletion(_ record: WorkoutRecord, modelContext: ModelContext) async {
        record.isCompleted.toggle()
        if record.isCompleted {
            record.markAsCompleted()
        }
        await loadWorkoutRecords()
    }
}