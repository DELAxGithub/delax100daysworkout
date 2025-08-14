import SwiftUI
import SwiftData
import Foundation

// MARK: - Mock Implementations for Testing

/// Mock ModelContext provider for testing
final class MockModelContextProvider: ModelContextProviding {
    var modelContext: ModelContext
    
    init() {
        // Create in-memory container for testing
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: WorkoutRecord.self, DailyLog.self, UserProfile.self,
            configurations: configuration
        )
        self.modelContext = container.mainContext
    }
    
    init(customModels: [any PersistentModel.Type]) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: customModels.first!,
            configurations: configuration
        )
        self.modelContext = container.mainContext
    }
}

/// Mock error handler for testing
final class MockErrorHandler: ErrorHandling {
    var capturedErrors: [(Error, String)] = []
    var swiftDataErrors: [(Error, String)] = []
    var networkErrors: [(Error, String)] = []
    var validationErrors: [(Error, String)] = []
    
    func handleSwiftDataError(_ error: Error, context: String) {
        swiftDataErrors.append((error, context))
        capturedErrors.append((error, context))
    }
    
    func handleNetworkError(_ error: Error, context: String) {
        networkErrors.append((error, context))
        capturedErrors.append((error, context))
    }
    
    func handleValidationError(_ error: Error, context: String) {
        validationErrors.append((error, context))
        capturedErrors.append((error, context))
    }
    
    func clear() {
        capturedErrors.removeAll()
        swiftDataErrors.removeAll()
        networkErrors.removeAll()
        validationErrors.removeAll()
    }
    
    var hasErrors: Bool {
        !capturedErrors.isEmpty
    }
    
    var lastError: Error? {
        capturedErrors.last?.0
    }
}

/// Mock analytics provider for testing
final class MockAnalyticsProvider: AnalyticsProviding {
    var trackedEvents: [(String, [String: Any])] = []
    var trackedScreens: [String] = []
    var trackedErrors: [(Error, String)] = []
    
    func trackEvent(_ event: String, parameters: [String: Any]) {
        trackedEvents.append((event, parameters))
    }
    
    func trackScreen(_ screenName: String) {
        trackedScreens.append(screenName)
    }
    
    func trackError(_ error: Error, context: String) {
        trackedErrors.append((error, context))
    }
    
    func clear() {
        trackedEvents.removeAll()
        trackedScreens.removeAll()
        trackedErrors.removeAll()
    }
    
    var eventCount: Int { trackedEvents.count }
    var screenCount: Int { trackedScreens.count }
    var errorCount: Int { trackedErrors.count }
}

/// Mock CRUD operations for testing
final class MockCRUDEngine<T: PersistentModel>: CRUDOperations {
    typealias Model = T
    
    var mockData: [T] = []
    var shouldFailOperations = false
    var operationCalls: [String] = []
    
    func create(_ model: T) async -> Bool {
        operationCalls.append("create")
        guard !shouldFailOperations else { return false }
        mockData.append(model)
        return true
    }
    
    func createBatch(_ models: [T]) async -> Bool {
        operationCalls.append("createBatch")
        guard !shouldFailOperations else { return false }
        mockData.append(contentsOf: models)
        return true
    }
    
    func fetch(predicate: Predicate<T>?, sortBy: [SortDescriptor<T>], limit: Int?) async -> [T] {
        operationCalls.append("fetch")
        guard !shouldFailOperations else { return [] }
        
        var result = mockData
        
        // Apply limit if specified
        if let limit = limit, limit < result.count {
            result = Array(result.prefix(limit))
        }
        
        return result
    }
    
    func count(predicate: Predicate<T>?) async -> Int {
        operationCalls.append("count")
        guard !shouldFailOperations else { return 0 }
        return mockData.count
    }
    
    func delete(_ model: T) async -> Bool {
        operationCalls.append("delete")
        guard !shouldFailOperations else { return false }
        mockData.removeAll { $0.id == model.id }
        return true
    }
    
    func deleteAll(where predicate: Predicate<T>?) async -> Bool {
        operationCalls.append("deleteAll")
        guard !shouldFailOperations else { return false }
        mockData.removeAll()
        return true
    }
    
    // Test utilities
    func reset() {
        mockData.removeAll()
        operationCalls.removeAll()
        shouldFailOperations = false
    }
    
    func addMockData(_ items: [T]) {
        mockData.append(contentsOf: items)
    }
    
    var callCount: Int { operationCalls.count }
    
    func wasMethodCalled(_ method: String) -> Bool {
        operationCalls.contains(method)
    }
}

/// Mock weekly plan manager for testing
final class MockWeeklyPlanManager: WeeklyPlanManaging {
    var mockPlan: WeeklyTemplate?
    var shouldFailOperations = false
    var operationCalls: [String] = []
    
    func generateWeeklyPlan(for profile: UserProfile) async -> WeeklyTemplate? {
        operationCalls.append("generateWeeklyPlan")
        guard !shouldFailOperations else { return nil }
        return mockPlan
    }
    
    func updateWeeklyPlan(_ template: WeeklyTemplate) async -> Bool {
        operationCalls.append("updateWeeklyPlan")
        guard !shouldFailOperations else { return false }
        mockPlan = template
        return true
    }
    
    func getCurrentWeekPlan() async -> WeeklyTemplate? {
        operationCalls.append("getCurrentWeekPlan")
        guard !shouldFailOperations else { return nil }
        return mockPlan
    }
    
    func reset() {
        mockPlan = nil
        operationCalls.removeAll()
        shouldFailOperations = false
    }
}

/// Mock health data provider for testing
final class MockHealthDataProvider: HealthDataProviding {
    var isAuthorized = false
    var shouldFailOperations = false
    var mockHeartRate: Double?
    var operationCalls: [String] = []
    
    func requestAuthorization() async -> Bool {
        operationCalls.append("requestAuthorization")
        guard !shouldFailOperations else { return false }
        isAuthorized = true
        return true
    }
    
    func syncHealthData() async -> Bool {
        operationCalls.append("syncHealthData")
        guard !shouldFailOperations else { return false }
        return isAuthorized
    }
    
    func getLatestHeartRate() async -> Double? {
        operationCalls.append("getLatestHeartRate")
        guard !shouldFailOperations else { return nil }
        return mockHeartRate
    }
    
    func reset() {
        isAuthorized = false
        shouldFailOperations = false
        mockHeartRate = nil
        operationCalls.removeAll()
    }
}

// MARK: - Mock Model Operations

final class MockModelOperations<T>: ModelOperations {
    typealias Model = T
    
    var shouldFailValidation = false
    var validationMessage: String?
    var operationCalls: [String] = []
    
    func validateModel(_ model: T) -> ValidationResult {
        operationCalls.append("validateModel")
        if shouldFailValidation {
            return ValidationResult(isValid: false, errorMessage: validationMessage ?? "Mock validation failed")
        }
        return ValidationResult(isValid: true)
    }
    
    func beforeCreateModel(_ model: T) -> T {
        operationCalls.append("beforeCreateModel")
        return model
    }
    
    func afterCreateModel(_ model: T) {
        operationCalls.append("afterCreateModel")
    }
    
    func beforeDeleteModel(_ model: T) -> Bool {
        operationCalls.append("beforeDeleteModel")
        return !shouldFailValidation
    }
    
    func afterDeleteModel(_ model: T) {
        operationCalls.append("afterDeleteModel")
    }
    
    func reset() {
        shouldFailValidation = false
        validationMessage = nil
        operationCalls.removeAll()
    }
}

// MARK: - Test DI Container Setup

extension DIContainer {
    /// Configure DI container for testing with mock implementations
    static func createTestContainer() -> DIContainer {
        let container = DIContainer()
        
        container.configure {
            ServiceRegistration(
                ModelContextProviding.self,
                implementation: MockModelContextProvider()
            )
            
            ServiceRegistration(
                ErrorHandling.self,
                implementation: MockErrorHandler()
            )
            
            ServiceRegistration(
                AnalyticsProviding.self,
                implementation: MockAnalyticsProvider()
            )
            
            ServiceRegistration(
                WeeklyPlanManaging.self,
                implementation: MockWeeklyPlanManager()
            )
            
            ServiceRegistration(
                HealthDataProviding.self,
                implementation: MockHealthDataProvider()
            )
        }
        
        return container
    }
    
    /// Get mock services for testing
    func getMockErrorHandler() -> MockErrorHandler? {
        resolve(ErrorHandling.self) as? MockErrorHandler
    }
    
    func getMockAnalytics() -> MockAnalyticsProvider? {
        resolve(AnalyticsProviding.self) as? MockAnalyticsProvider
    }
    
    func getMockWeeklyPlanManager() -> MockWeeklyPlanManager? {
        resolve(WeeklyPlanManaging.self) as? MockWeeklyPlanManager
    }
    
    func getMockHealthDataProvider() -> MockHealthDataProvider? {
        resolve(HealthDataProviding.self) as? MockHealthDataProvider
    }
}