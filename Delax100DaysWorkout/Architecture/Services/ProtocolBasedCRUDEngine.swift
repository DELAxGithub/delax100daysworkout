import SwiftUI
import SwiftData
import Foundation
import OSLog

// MARK: - Protocol-based CRUD Engine Implementation

@MainActor
final class ProtocolBasedCRUDEngine<T: PersistentModel>: ObservableObject, CRUDOperations {
    typealias Model = T
    
    @Injected(ModelContextProviding.self) private var contextProvider: ModelContextProviding
    @Injected(ErrorHandling.self) private var errorHandler: ErrorHandling
    
    private var modelOperations: (any ModelOperations)?
    private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "ProtocolBasedCRUDEngine")
    
    @Published var isLoading = false
    @Published var lastOperationResult: CRUDResult = .idle
    
    enum CRUDResult {
        case idle
        case success(String)
        case failure(AppError)
    }
    
    // MARK: - Initializers
    
    /// DI Container initialization
    init(container: DIContainer = DIContainer.shared) {
        // Dependencies are injected via @Injected property wrappers
    }
    
    /// Manual initialization (for testing or special cases)
    init(
        contextProvider: ModelContextProviding,
        errorHandler: ErrorHandling,
        modelOperations: (any ModelOperations)? = nil
    ) {
        self.modelOperations = modelOperations
        // Override injected dependencies
        DIContainer.shared.register(ModelContextProviding.self, instance: contextProvider)
        DIContainer.shared.register(ErrorHandling.self, instance: errorHandler)
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
    
    // MARK: - CRUDOperations Protocol Implementation
    
    func create(_ model: T) async -> Bool {
        return await performOperation("Create") { [self] in
            var processedModel = model
            
            if let ops = modelOperations as? any ModelOperations {
                let validationResult = ops.validateModel(processedModel)
                guard validationResult.isValid else {
                    throw AppError.invalidInput(validationResult.errorMessage ?? "Validation failed")
                }
                processedModel = ops.beforeCreateModel(processedModel)
            }
            
            contextProvider.modelContext.insert(processedModel)
            try contextProvider.modelContext.save()
            
            if let ops = modelOperations as? any ModelOperations {
                ops.afterCreateModel(processedModel)
            }
            
            logger.info("Successfully created \(String(describing: T.self))")
            return true
        } ?? false
    }
    
    func createBatch(_ models: [T]) async -> Bool {
        return await performOperation("Create Batch (\(models.count) items)") { [self] in
            var processedModels: [T] = []
            
            for model in models {
                if let ops = modelOperations as? any ModelOperations {
                    let validationResult = ops.validateModel(model)
                    guard validationResult.isValid else {
                        throw AppError.invalidInput("Batch validation failed: \(validationResult.errorMessage ?? "Unknown error")")
                    }
                    processedModels.append(ops.beforeCreateModel(model))
                } else {
                    processedModels.append(model)
                }
            }
            
            for model in processedModels {
                contextProvider.modelContext.insert(model)
            }
            
            try contextProvider.modelContext.save()
            
            if let ops = modelOperations as? any ModelOperations {
                for model in processedModels {
                    ops.afterCreateModel(model)
                }
            }
            
            logger.info("Successfully created batch of \(models.count) \(String(describing: T.self)) objects")
            return true
        } ?? false
    }
    
    func fetch(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        limit: Int? = nil
    ) async -> [T] {
        return await performOperation("Fetch") { [self] in
            var descriptor = FetchDescriptor<T>(
                predicate: predicate,
                sortBy: sortBy
            )
            
            if let limit = limit {
                descriptor.fetchLimit = limit
            }
            
            let results = try contextProvider.modelContext.fetch(descriptor)
            logger.info("Successfully fetched \(results.count) \(String(describing: T.self)) objects")
            return results
        } ?? []
    }
    
    func count(predicate: Predicate<T>? = nil) async -> Int {
        return await performOperation("Count") { [self] in
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            return try contextProvider.modelContext.fetchCount(descriptor)
        } ?? 0
    }
    
    func delete(_ model: T) async -> Bool {
        return await performOperation("Delete") { [self] in
            if let ops = modelOperations as? any ModelOperations {
                guard ops.beforeDeleteModel(model) else {
                    throw AppError.databaseError("Pre-delete validation failed")
                }
            }
            
            contextProvider.modelContext.delete(model)
            try contextProvider.modelContext.save()
            
            if let ops = modelOperations as? any ModelOperations {
                ops.afterDeleteModel(model)
            }
            
            logger.info("Successfully deleted \(String(describing: T.self))")
            return true
        } ?? false
    }
    
    func deleteAll(where predicate: Predicate<T>? = nil) async -> Bool {
        return await performOperation("Delete All") { [self] in
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            let modelsToDelete = try contextProvider.modelContext.fetch(descriptor)
            
            if let ops = modelOperations as? any ModelOperations {
                for model in modelsToDelete {
                    guard ops.beforeDeleteModel(model) else {
                        throw AppError.databaseError("Delete all validation failed")
                    }
                }
            }
            
            for model in modelsToDelete {
                contextProvider.modelContext.delete(model)
            }
            
            try contextProvider.modelContext.save()
            
            if let ops = modelOperations as? any ModelOperations {
                for model in modelsToDelete {
                    ops.afterDeleteModel(model)
                }
            }
            
            logger.info("Successfully deleted all \(modelsToDelete.count) \(String(describing: T.self)) objects")
            return true
        } ?? false
    }
}

// MARK: - Injectable Conformance

extension ProtocolBasedCRUDEngine: Injectable {
    convenience init(container: DIContainer) {
        self.init(container: container)
    }
}

// MARK: - Convenience Factory

extension ProtocolBasedCRUDEngine {
    static func create<ModelType: PersistentModel>(
        for type: ModelType.Type,
        with operations: (any ModelOperations)? = nil
    ) -> ProtocolBasedCRUDEngine<ModelType> {
        let engine = ProtocolBasedCRUDEngine<ModelType>()
        engine.modelOperations = operations
        return engine
    }
}