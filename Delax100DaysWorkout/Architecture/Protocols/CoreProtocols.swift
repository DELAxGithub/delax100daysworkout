import SwiftUI
import SwiftData
import Foundation

// MARK: - Core Data Layer Protocols

/// Provides access to ModelContext for data operations
protocol ModelContextProviding {
    var modelContext: ModelContext { get }
}

/// Generic CRUD operations for any PersistentModel
protocol CRUDOperations {
    associatedtype Model: PersistentModel
    
    func create(_ model: Model) async -> Bool
    func createBatch(_ models: [Model]) async -> Bool
    func fetch(predicate: Predicate<Model>?, sortBy: [SortDescriptor<Model>], limit: Int?) async -> [Model]
    func count(predicate: Predicate<Model>?) async -> Int
    func delete(_ model: Model) async -> Bool
    func deleteAll(where predicate: Predicate<Model>?) async -> Bool
}

/// Error handling abstraction
protocol ErrorHandling {
    func handleSwiftDataError(_ error: Error, context: String)
    func handleNetworkError(_ error: Error, context: String)
    func handleValidationError(_ error: Error, context: String)
}

/// Model validation and lifecycle hooks
protocol ModelOperations {
    associatedtype Model
    
    func validateModel(_ model: Model) -> ValidationResult
    func beforeCreateModel(_ model: Model) -> Model
    func afterCreateModel(_ model: Model)
    func beforeDeleteModel(_ model: Model) -> Bool
    func afterDeleteModel(_ model: Model)
}

// MARK: - Service Layer Protocols

/// Generic service abstraction for business logic
protocol ServiceProtocol {
    associatedtype Model
    var isLoading: Bool { get }
    func loadData() async
}

/// Weekly plan management abstraction
protocol WeeklyPlanManaging {
    func generateWeeklyPlan(for profile: UserProfile) async -> WeeklyTemplate?
    func updateWeeklyPlan(_ template: WeeklyTemplate) async -> Bool
    func getCurrentWeekPlan() async -> WeeklyTemplate?
}

/// Analytics service abstraction
protocol AnalyticsProviding {
    func trackEvent(_ event: String, parameters: [String: Any])
    func trackScreen(_ screenName: String)
    func trackError(_ error: Error, context: String)
}

/// Health data integration abstraction
protocol HealthDataProviding {
    var isAuthorized: Bool { get }
    func requestAuthorization() async -> Bool
    func syncHealthData() async -> Bool
    func getLatestHeartRate() async -> Double?
}

// MARK: - UI Layer Protocols

/// Generic ViewModel protocol with common functionality
protocol ViewModelProtocol: ObservableObject {
    associatedtype Model
    var items: [Model] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func loadData() async
    func refresh() async
}

/// Navigation handling abstraction
protocol NavigationHandling {
    func navigate(to destination: any Hashable)
    func dismiss()
    func popToRoot()
}

// MARK: - Supporting Types

struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    init(isValid: Bool, errorMessage: String? = nil) {
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
}

// MARK: - Protocol Extensions for Default Implementations

extension CRUDOperations {
    func fetch() async -> [Model] {
        await fetch(predicate: nil, sortBy: [], limit: nil)
    }
    
    func fetchFirst(predicate: Predicate<Model>? = nil) async -> Model? {
        let results = await fetch(predicate: predicate, sortBy: [], limit: 1)
        return results.first
    }
}

extension ViewModelProtocol {
    func refresh() async {
        await loadData()
    }
}