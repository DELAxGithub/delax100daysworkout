import SwiftData
import Foundation

// MARK: - CRUD Engine Factory

struct CRUDEngineFactory {
    @MainActor
    static func createEngine<T: PersistentModel>(
        for type: T.Type,
        modelContext: ModelContext,
        errorHandler: ErrorHandler
    ) -> CRUDEngine<T> {
        return CRUDEngine<T>(
            modelContext: modelContext,
            errorHandler: errorHandler
        )
    }
    
    // MARK: - Predefined Engines for Common Models
    
    @MainActor
    static func workoutRecordEngine(
        modelContext: ModelContext,
        errorHandler: ErrorHandler
    ) -> CRUDEngine<WorkoutRecord> {
        return CRUDEngine<WorkoutRecord>(
            modelContext: modelContext,
            errorHandler: errorHandler
        )
    }
    
    @MainActor
    static func dailyMetricEngine(
        modelContext: ModelContext,
        errorHandler: ErrorHandler
    ) -> CRUDEngine<DailyMetric> {
        return CRUDEngine<DailyMetric>(
            modelContext: modelContext,
            errorHandler: errorHandler
        )
    }
    
    @MainActor
    static func ftpHistoryEngine(
        modelContext: ModelContext,
        errorHandler: ErrorHandler
    ) -> CRUDEngine<FTPHistory> {
        return CRUDEngine<FTPHistory>(
            modelContext: modelContext,
            errorHandler: errorHandler
        )
    }
}