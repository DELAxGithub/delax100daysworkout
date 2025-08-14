import SwiftUI
import SwiftData
import Foundation

// MARK: - Dependency Injection Container

/// Thread-safe dependency injection container
@MainActor
final class DIContainer: ObservableObject {
    static let shared = DIContainer()
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    
    private init() {}
    
    // MARK: - Registration Methods
    
    /// Register a singleton instance
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        singletons[key] = instance
    }
    
    /// Register a factory closure for creating instances
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// Register a service implementation for a protocol
    func register<Protocol, Implementation>(
        _ protocolType: Protocol.Type,
        implementation: Implementation
    ) where Implementation: Protocol {
        let key = String(describing: protocolType)
        services[key] = implementation
    }
    
    // MARK: - Resolution Methods
    
    /// Resolve a service by type
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // Check singletons first
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Check services
        if let service = services[key] as? T {
            return service
        }
        
        // Check factories
        if let factory = factories[key] {
            let instance = factory() as? T
            return instance
        }
        
        return nil
    }
    
    /// Resolve a service by type, throwing if not found
    func resolve<T>(_ type: T.Type) throws -> T {
        guard let service = resolve(type) else {
            throw DIError.serviceNotRegistered(String(describing: type))
        }
        return service
    }
    
    /// Resolve with automatic dependency injection
    func autowire<T>(_ type: T.Type) -> T? where T: Injectable {
        return T.init(container: self)
    }
    
    // MARK: - Utility Methods
    
    /// Check if a service is registered
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return singletons[key] != nil || services[key] != nil || factories[key] != nil
    }
    
    /// Clear all registrations (useful for testing)
    func clear() {
        services.removeAll()
        factories.removeAll()
        singletons.removeAll()
    }
    
    /// Get all registered service keys (for debugging)
    var registeredServices: [String] {
        Set(services.keys)
            .union(Set(factories.keys))
            .union(Set(singletons.keys))
            .sorted()
    }
}

// MARK: - DI Errors

enum DIError: Error, LocalizedError {
    case serviceNotRegistered(String)
    case circularDependency(String)
    case injectionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let service):
            return "Service not registered: \(service)"
        case .circularDependency(let service):
            return "Circular dependency detected: \(service)"
        case .injectionFailed(let service):
            return "Dependency injection failed: \(service)"
        }
    }
}

// MARK: - Injectable Protocol

/// Types that can be automatically injected with dependencies
protocol Injectable {
    init(container: DIContainer)
}

// MARK: - Property Wrapper for Dependency Injection

@propertyWrapper
struct Injected<T> {
    private let container: DIContainer
    private let type: T.Type
    
    init(_ type: T.Type, container: DIContainer = DIContainer.shared) {
        self.type = type
        self.container = container
    }
    
    var wrappedValue: T {
        guard let service = container.resolve(type) else {
            fatalError("Service \(String(describing: type)) not registered in DI container")
        }
        return service
    }
}

// MARK: - Environment DI Support

struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer.shared
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

// MARK: - SwiftUI View Extension

extension View {
    func diContainer(_ container: DIContainer) -> some View {
        environment(\.diContainer, container)
    }
}

// MARK: - Service Scope

enum ServiceScope {
    case singleton
    case transient
    case scoped
}

// MARK: - Service Registration Builder

@resultBuilder
struct ServiceRegistrationBuilder {
    static func buildBlock(_ registrations: ServiceRegistration...) -> [ServiceRegistration] {
        registrations
    }
}

struct ServiceRegistration {
    let register: (DIContainer) -> Void
    
    init<T>(_ type: T.Type, instance: T) {
        self.register = { container in
            container.register(type, instance: instance)
        }
    }
    
    init<T>(_ type: T.Type, factory: @escaping () -> T) {
        self.register = { container in
            container.register(type, factory: factory)
        }
    }
    
    init<Protocol, Implementation>(
        _ protocolType: Protocol.Type,
        implementation: Implementation
    ) where Implementation: Protocol {
        self.register = { container in
            container.register(protocolType, implementation: implementation)
        }
    }
}

extension DIContainer {
    func configure(@ServiceRegistrationBuilder _ registrations: () -> [ServiceRegistration]) {
        let services = registrations()
        for service in services {
            service.register(self)
        }
    }
}