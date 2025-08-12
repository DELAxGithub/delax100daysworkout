import Foundation
import Combine

@MainActor
class SmartRefreshManager: ObservableObject {
    static let shared = SmartRefreshManager()
    
    private var lastRefreshTimes: [String: Date] = [:]
    private var refreshInProgress: Set<String> = []
    private let refreshQueue = DispatchQueue(label: "com.delax.refresh", attributes: .concurrent)
    
    private let defaultMinInterval: TimeInterval = 30
    private let aggressiveMinInterval: TimeInterval = 5
    private let conservativeMinInterval: TimeInterval = 60
    
    private init() {}
    
    func shouldRefresh(
        for identifier: String,
        minInterval: RefreshInterval = .default
    ) -> Bool {
        if refreshInProgress.contains(identifier) {
            return false
        }
        
        guard let lastRefresh = lastRefreshTimes[identifier] else {
            return true
        }
        
        let interval: TimeInterval
        switch minInterval {
        case .aggressive:
            interval = aggressiveMinInterval
        case .default:
            interval = defaultMinInterval
        case .conservative:
            interval = conservativeMinInterval
        case .custom(let seconds):
            interval = seconds
        }
        
        return Date().timeIntervalSince(lastRefresh) >= interval
    }
    
    func beginRefresh(for identifier: String) {
        refreshInProgress.insert(identifier)
    }
    
    func endRefresh(for identifier: String) {
        refreshInProgress.remove(identifier)
        lastRefreshTimes[identifier] = Date()
    }
    
    func refreshWithThrottle<T>(
        identifier: String,
        minInterval: RefreshInterval = .default,
        action: @escaping () async throws -> T
    ) async throws -> T? {
        guard shouldRefresh(for: identifier, minInterval: minInterval) else {
            return nil
        }
        
        beginRefresh(for: identifier)
        defer { endRefresh(for: identifier) }
        
        return try await action()
    }
    
    func batchRefresh<T>(
        identifiers: [String],
        minInterval: RefreshInterval = .default,
        actions: [(String, () async throws -> T)]
    ) async throws -> [String: T] {
        var results: [String: T] = [:]
        
        await withTaskGroup(of: (String, T?).self) { group in
            for (identifier, action) in actions {
                if shouldRefresh(for: identifier, minInterval: minInterval) {
                    group.addTask { [weak self] in
                        guard let self = self else { return (identifier, nil) }
                        
                        self.beginRefresh(for: identifier)
                        defer { self.endRefresh(for: identifier) }
                        
                        do {
                            let result = try await action()
                            return (identifier, result)
                        } catch {
                            print("Batch refresh error for \(identifier): \(error)")
                            return (identifier, nil)
                        }
                    }
                }
            }
            
            for await (identifier, result) in group {
                if let result = result {
                    results[identifier] = result
                }
            }
        }
        
        return results
    }
    
    func reset(for identifier: String? = nil) {
        if let identifier = identifier {
            lastRefreshTimes.removeValue(forKey: identifier)
            refreshInProgress.remove(identifier)
        } else {
            lastRefreshTimes.removeAll()
            refreshInProgress.removeAll()
        }
    }
    
    enum RefreshInterval {
        case aggressive
        case `default`
        case conservative
        case custom(TimeInterval)
    }
}