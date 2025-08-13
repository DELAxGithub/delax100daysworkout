import SwiftData
import Foundation

// MARK: - CRUD Engine Factory

struct CRUDEngineFactory {
    static func createEngine<T: PersistentModel>(
        for type: T.Type,
        modelContext: ModelContext,
        errorHandler: ErrorHandler,
        operations: (any ModelOperations)? = nil
    ) -> CRUDEngine<T> {
        return CRUDEngine<T>(
            modelContext: modelContext,
            errorHandler: errorHandler,
            operations: operations
        )
    }
    
    // MARK: - Predefined Engines for Common Models
    
    static func workoutRecordEngine(
        modelContext: ModelContext,
        errorHandler: ErrorHandler
    ) -> CRUDEngine<WorkoutRecord> {
        return CRUDEngine<WorkoutRecord>(
            modelContext: modelContext,
            errorHandler: errorHandler,
            operations: nil // WorkoutRecord already implements Validatable
        )
    }
    
    static func dailyMetricEngine(
        modelContext: ModelContext,
        errorHandler: ErrorHandler
    ) -> CRUDEngine<DailyMetric> {
        return CRUDEngine<DailyMetric>(
            modelContext: modelContext,
            errorHandler: errorHandler,
            operations: nil
        )
    }
    
    static func ftpHistoryEngine(
        modelContext: ModelContext,
        errorHandler: ErrorHandler
    ) -> CRUDEngine<FTPHistory> {
        return CRUDEngine<FTPHistory>(
            modelContext: modelContext,
            errorHandler: errorHandler,
            operations: nil
        )
    }
}