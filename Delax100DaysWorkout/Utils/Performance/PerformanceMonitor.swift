import SwiftUI
import os.signpost

// MARK: - Performance Monitor

@MainActor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.delax.workout", category: "Performance")
    private let signposter = OSSignposter(logger: Logger(subsystem: "com.delax.workout", category: "Signposts"))
    
    @Published var metrics: [PerformanceMetric] = []
    @Published var isMonitoring = false
    
    private var activeOperations: [String: OSSignpostID] = [:]
    
    private init() {}
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        isMonitoring = true
        logger.info("Performance monitoring started")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        activeOperations.removeAll()
        logger.info("Performance monitoring stopped")
    }
    
    // MARK: - Operation Tracking
    
    func startOperation(_ name: String, category: PerformanceCategory = .general) -> String {
        guard isMonitoring else { return "" }
        
        let operationId = "\(name)_\(UUID().uuidString.prefix(8))"
        let signpostId = signposter.makeSignpostID()
        
        activeOperations[operationId] = signpostId
        // Performance tracking temporarily disabled due to API constraints
        
        logger.debug("Started operation: \(name)")
        return operationId
    }
    
    func endOperation(_ operationId: String, name: String, metadata: [String: Any] = [:]) {
        guard isMonitoring,
              let signpostId = activeOperations.removeValue(forKey: operationId) else { return }
        
        // Performance tracking temporarily disabled due to API constraints
        
        let metric = PerformanceMetric(
            name: name,
            category: .general,
            timestamp: Date(),
            metadata: metadata
        )
        
        metrics.append(metric)
        logger.debug("Ended operation: \(name)")
        
        // Keep only recent metrics
        if metrics.count > 100 {
            metrics.removeFirst(50)
        }
    }
    
    // MARK: - Convenience Methods
    
    func measureCardInteraction<T>(_ operation: () -> T, cardType: String) -> T {
        let operationId = startOperation("card_interaction", category: .interaction)
        let result = operation()
        endOperation(operationId, name: "card_interaction", metadata: ["cardType": cardType])
        return result
    }
    
    func measureViewRender<T>(_ operation: () -> T, viewName: String) -> T {
        let operationId = startOperation("view_render", category: .rendering)
        let result = operation()
        endOperation(operationId, name: "view_render", metadata: ["viewName": viewName])
        return result
    }
    
    // MARK: - Analytics
    
    func getAverageTime(for operationName: String) -> TimeInterval? {
        let relevantMetrics = metrics.filter { $0.name == operationName }
        guard !relevantMetrics.isEmpty else { return nil }
        
        let totalTime = relevantMetrics.compactMap { $0.duration }.reduce(0, +)
        return totalTime / Double(relevantMetrics.count)
    }
    
    func getP95Time(for operationName: String) -> TimeInterval? {
        let durations = metrics
            .filter { $0.name == operationName }
            .compactMap { $0.duration }
            .sorted()
        
        guard !durations.isEmpty else { return nil }
        
        let p95Index = Int(Double(durations.count) * 0.95)
        return durations[min(p95Index, durations.count - 1)]
    }
    
    func exportMetrics() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(metrics)
            return String(data: data, encoding: .utf8) ?? "Export failed"
        } catch {
            return "Export error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Performance Metric

struct PerformanceMetric: Codable, Identifiable {
    let id = UUID()
    let name: String
    let category: PerformanceCategory
    let timestamp: Date
    let metadata: [String: String]
    
    var duration: TimeInterval? {
        metadata["duration"].flatMap(Double.init)
    }
    
    init(name: String, category: PerformanceCategory, timestamp: Date, metadata: [String: Any]) {
        self.name = name
        self.category = category
        self.timestamp = timestamp
        
        // Convert metadata to String dictionary
        self.metadata = metadata.compactMapValues { value in
            if let string = value as? String {
                return string
            } else if let number = value as? NSNumber {
                return number.stringValue
            } else {
                return String(describing: value)
            }
        }
    }
}

// MARK: - Performance Category

enum PerformanceCategory: String, Codable, CaseIterable {
    case general = "general"
    case interaction = "interaction"
    case rendering = "rendering"
    case networking = "networking"
    case database = "database"
    case animation = "animation"
}

// MARK: - Performance Wrapper

struct PerformanceWrapper<Content: View>: View {
    let viewName: String
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .onAppear {
                PerformanceMonitor.shared.measureViewRender({}, viewName: viewName)
            }
    }
}

// MARK: - View Extensions

extension View {
    func performanceTracked(_ viewName: String) -> some View {
        PerformanceWrapper(viewName: viewName) {
            self
        }
    }
    
    func measureInteraction<T>(_ operation: @escaping () -> T, name: String) -> some View {
        self.onTapGesture {
            _ = PerformanceMonitor.shared.measureCardInteraction(operation, cardType: name)
        }
    }
}