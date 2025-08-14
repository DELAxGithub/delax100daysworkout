import SwiftUI
import SwiftData
import Foundation
import OSLog

// MARK: - Core Service Implementations

/// Default ModelContext provider using the app's main context
@MainActor
final class AppModelContextProvider: ModelContextProviding {
    private let container: ModelContainer
    
    var modelContext: ModelContext {
        container.mainContext
    }
    
    init(container: ModelContainer) {
        self.container = container
    }
    
    /// Convenience initializer using the global app container
    convenience init() {
        // This will be set up during app initialization
        self.init(container: Self.defaultContainer)
    }
    
    private static var defaultContainer: ModelContainer = {
        // Default container - will be replaced during app setup
        do {
            return try ModelContainer(for: WorkoutRecord.self)
        } catch {
            fatalError("Failed to create default ModelContainer: \(error)")
        }
    }()
    
    static func setDefaultContainer(_ container: ModelContainer) {
        defaultContainer = container
    }
}

/// Default error handler implementation
final class AppErrorHandler: ErrorHandling {
    private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "ErrorHandler")
    
    func handleSwiftDataError(_ error: Error, context: String) {
        logger.error("SwiftData error in \(context): \(error.localizedDescription)")
        
        // Additional error handling logic
        if let swiftDataError = error as? SwiftDataError {
            handleSwiftDataSpecificError(swiftDataError, context: context)
        }
        
        // Could post notifications, report to analytics, etc.
        NotificationCenter.default.post(
            name: .swiftDataErrorOccurred,
            object: nil,
            userInfo: ["error": error, "context": context]
        )
    }
    
    func handleNetworkError(_ error: Error, context: String) {
        logger.error("Network error in \(context): \(error.localizedDescription)")
        
        // Network-specific error handling
        if let urlError = error as? URLError {
            handleURLError(urlError, context: context)
        }
        
        NotificationCenter.default.post(
            name: .networkErrorOccurred,
            object: nil,
            userInfo: ["error": error, "context": context]
        )
    }
    
    func handleValidationError(_ error: Error, context: String) {
        logger.warning("Validation error in \(context): \(error.localizedDescription)")
        
        NotificationCenter.default.post(
            name: .validationErrorOccurred,
            object: nil,
            userInfo: ["error": error, "context": context]
        )
    }
    
    private func handleSwiftDataSpecificError(_ error: SwiftDataError, context: String) {
        // Handle specific SwiftData errors
        switch error {
        case .saveError:
            logger.error("Save operation failed in \(context)")
        case .fetchError:
            logger.error("Fetch operation failed in \(context)")
        default:
            logger.error("Unknown SwiftData error in \(context)")
        }
    }
    
    private func handleURLError(_ error: URLError, context: String) {
        switch error.code {
        case .notConnectedToInternet:
            logger.warning("No internet connection in \(context)")
        case .timedOut:
            logger.warning("Request timed out in \(context)")
        case .networkConnectionLost:
            logger.warning("Network connection lost in \(context)")
        default:
            logger.error("URL error \(error.code.rawValue) in \(context)")
        }
    }
}

// MARK: - Analytics Implementation

final class AppAnalyticsProvider: AnalyticsProviding {
    private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "Analytics")
    
    func trackEvent(_ event: String, parameters: [String: Any]) {
        logger.info("Analytics Event: \(event) with parameters: \(String(describing: parameters))")
        
        // TODO: Integrate with actual analytics service (Firebase, etc.)
        // For now, just log to console
    }
    
    func trackScreen(_ screenName: String) {
        logger.info("Screen viewed: \(screenName)")
        
        // TODO: Integrate with actual analytics service
    }
    
    func trackError(_ error: Error, context: String) {
        logger.error("Error tracked: \(error.localizedDescription) in \(context)")
        
        // TODO: Integrate with crash reporting service
    }
}

// MARK: - Base ViewModel Implementation

@MainActor
class BaseViewModel<T>: ViewModelProtocol {
    typealias Model = T
    
    @Published var items: [T] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Injected(AnalyticsProviding.self) private var analytics: AnalyticsProviding
    
    required init() {}
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await loadDataImplementation()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            analytics.trackError(error, context: String(describing: Self.self))
        }
    }
    
    /// Override this method in subclasses to implement specific data loading
    func loadDataImplementation() async throws {
        // Default implementation - override in subclasses
    }
    
    func trackScreenView() {
        analytics.trackScreen(String(describing: Self.self))
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let swiftDataErrorOccurred = Notification.Name("swiftDataErrorOccurred")
    static let networkErrorOccurred = Notification.Name("networkErrorOccurred")
    static let validationErrorOccurred = Notification.Name("validationErrorOccurred")
}

// MARK: - SwiftData Error Types

enum SwiftDataError: Error {
    case saveError
    case fetchError
    case deleteError
    case configurationError
}

// MARK: - Protocol-based Service Factory

final class ServiceFactory {
    private let container: DIContainer
    
    init(container: DIContainer = DIContainer.shared) {
        self.container = container
    }
    
    @MainActor
    func createCRUDEngine<T: PersistentModel>(
        for type: T.Type,
        with operations: (any ModelOperations)? = nil
    ) -> any CRUDOperations {
        return ProtocolBasedCRUDEngine<T>.create(for: type, with: operations)
    }
    
    @MainActor
    func createViewModel<T, VM: BaseViewModel<T>>(
        _ viewModelType: VM.Type
    ) -> VM {
        return VM()
    }
}

// MARK: - DI Container Configuration

extension DIContainer {
    /// Configure all core services in the DI container
    @MainActor
    func configureAppServices(modelContainer: ModelContainer) {
        // Set up model context provider
        AppModelContextProvider.setDefaultContainer(modelContainer)
        
        configure {
            ServiceRegistration(
                ModelContextProviding.self,
                implementation: AppModelContextProvider()
            )
            
            ServiceRegistration(
                ErrorHandling.self,
                implementation: AppErrorHandler()
            )
            
            ServiceRegistration(
                AnalyticsProviding.self,
                implementation: AppAnalyticsProvider()
            )
            
            ServiceRegistration(
                ServiceFactory.self,
                instance: ServiceFactory(container: self)
            )
        }
    }
}