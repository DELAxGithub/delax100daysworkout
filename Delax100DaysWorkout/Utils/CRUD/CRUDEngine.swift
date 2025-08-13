import SwiftUI
import SwiftData
import Foundation
import OSLog

// MARK: - Generic CRUD Engine

@MainActor
class CRUDEngine<T: PersistentModel>: ObservableObject {
    var modelContext: ModelContext
    var errorHandler: ErrorHandler
    private let operations: (any ModelOperations)?
    private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "CRUDEngine")
    
    @Published var isLoading = false
    @Published var lastOperationResult: CRUDResult = .idle
    
    enum CRUDResult {
        case idle
        case success(String)
        case failure(AppError)
    }
    
    init(
        modelContext: ModelContext,
        errorHandler: ErrorHandler,
        operations: (any ModelOperations)? = nil
    ) {
        self.modelContext = modelContext
        self.errorHandler = errorHandler
        self.operations = operations
    }
    
    // MARK: - Core Operation Wrapper
    
    private func performOperation<Result>(
        _ operationName: String,
        operation: @escaping () throws -> Result
    ) async -> Result? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try operation()
            lastOperationResult = .success("\(operationName) completed successfully")
            return result
        } catch {
            let appError: AppError
            if let existingAppError = error as? AppError {
                appError = existingAppError
            } else {
                appError = AppError.swiftDataOperationFailed("\(operationName) failed: \(error.localizedDescription)")
            }
            
            errorHandler.handleSwiftDataError(error, context: operationName)
            lastOperationResult = .failure(appError)
            logger.error("\(operationName) failed for \(String(describing: T.self)): \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - CRUD Operations Extensions

extension CRUDEngine {
    
    // MARK: - Create Operations
    
    func create(_ model: T) async -> Bool {
        return await performOperation("Create") {
            var processedModel = model
            
            if let ops = operations as? any ModelOperations<T> {
                let validationResult = ops.validate(processedModel)
                guard validationResult.isValid else {
                    throw AppError.invalidInput(validationResult.errorMessage ?? "Validation failed")
                }
                processedModel = ops.beforeCreate(processedModel)
            }
            
            modelContext.insert(processedModel)
            try modelContext.save()
            
            if let ops = operations as? any ModelOperations<T> {
                ops.afterCreate(processedModel)
            }
            
            logger.info("Successfully created \(String(describing: T.self))")
            return true
        } ?? false
    }
    
    func createBatch(_ models: [T]) async -> Bool {
        return await performOperation("Create Batch (\(models.count) items)") {
            var processedModels: [T] = []
            
            for model in models {
                if let ops = operations as? any ModelOperations<T> {
                    let validationResult = ops.validate(model)
                    guard validationResult.isValid else {
                        throw AppError.invalidInput("Batch validation failed: \(validationResult.errorMessage ?? "Unknown error")")
                    }
                    processedModels.append(ops.beforeCreate(model))
                } else {
                    processedModels.append(model)
                }
            }
            
            for model in processedModels {
                modelContext.insert(model)
            }
            
            try modelContext.save()
            
            if let ops = operations as? any ModelOperations<T> {
                for model in processedModels {
                    ops.afterCreate(model)
                }
            }
            
            logger.info("Successfully created batch of \(models.count) \(String(describing: T.self)) objects")
            return true
        } ?? false
    }
    
    // MARK: - Read Operations
    
    func fetch(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        limit: Int? = nil
    ) async -> [T] {
        return await performOperation("Fetch") {
            var descriptor = FetchDescriptor<T>(
                predicate: predicate,
                sortBy: sortBy
            )
            
            if let limit = limit {
                descriptor.fetchLimit = limit
            }
            
            let results = try modelContext.fetch(descriptor)
            logger.info("Successfully fetched \(results.count) \(String(describing: T.self)) objects")
            return results
        } ?? []
    }
    
    func count(predicate: Predicate<T>? = nil) async -> Int {
        return await performOperation("Count") {
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            return try modelContext.fetchCount(descriptor)
        } ?? 0
    }
    
    // MARK: - Delete Operations
    
    func delete(_ model: T) async -> Bool {
        return await performOperation("Delete") {
            if let ops = operations as? any ModelOperations<T> {
                guard ops.beforeDelete(model) else {
                    throw AppError.databaseError("Pre-delete validation failed")
                }
            }
            
            modelContext.delete(model)
            try modelContext.save()
            
            if let ops = operations as? any ModelOperations<T> {
                ops.afterDelete(model)
            }
            
            logger.info("Successfully deleted \(String(describing: T.self))")
            return true
        } ?? false
    }
    
    func deleteAll(where predicate: Predicate<T>? = nil) async -> Bool {
        return await performOperation("Delete All") {
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            let modelsToDelete = try modelContext.fetch(descriptor)
            
            if let ops = operations as? any ModelOperations<T> {
                for model in modelsToDelete {
                    guard ops.beforeDelete(model) else {
                        throw AppError.databaseError("Delete all validation failed")
                    }
                }
            }
            
            for model in modelsToDelete {
                modelContext.delete(model)
            }
            
            try modelContext.save()
            
            if let ops = operations as? any ModelOperations<T> {
                for model in modelsToDelete {
                    ops.afterDelete(model)
                }
            }
            
            logger.info("Successfully deleted all \(modelsToDelete.count) \(String(describing: T.self)) objects")
            return true
        } ?? false
    }
}