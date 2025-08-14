import SwiftUI
import SwiftData
import OSLog
import Combine

@MainActor
class CRUDAnalytics: ObservableObject {
    static let shared = CRUDAnalytics()
    
    @Published var metrics: CRUDMetrics = CRUDMetrics()
    @Published var realtimeStats: RealtimeStats = RealtimeStats()
    
    private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "CRUDAnalytics")
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        startRealtimeMonitoring()
    }
    
    func trackOperation<T: PersistentModel>(
        _ operation: CRUDOperation,
        for modelType: T.Type,
        duration: TimeInterval,
        success: Bool,
        recordCount: Int = 1
    ) {
        let metric = OperationMetric(
            modelType: String(describing: modelType),
            operation: operation,
            duration: duration,
            success: success,
            recordCount: recordCount,
            timestamp: Date()
        )
        
        metrics.addMetric(metric)
        realtimeStats.update(with: metric)
        
        logger.info("CRUD: \(operation.rawValue) \(modelType) - \(duration)ms - \(success ? "✓" : "✗")")
    }
    
    private func startRealtimeMonitoring() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRealtimeMetrics()
            }
            .store(in: &cancellables)
    }
    
    private func updateRealtimeMetrics() {
        realtimeStats.updateCurrentStats()
    }
}

struct CRUDMetrics {
    private var operations: [OperationMetric] = []
    private let maxStoredOperations = 1000
    
    mutating func addMetric(_ metric: OperationMetric) {
        operations.append(metric)
        if operations.count > maxStoredOperations {
            operations.removeFirst(operations.count - maxStoredOperations)
        }
    }
    
    func getStats(for timeRange: TimeRange = .hour) -> AnalyticsStats {
        let cutoff = timeRange.cutoffDate
        let relevantOps = operations.filter { $0.timestamp >= cutoff }
        
        return AnalyticsStats(
            totalOperations: relevantOps.count,
            successRate: calculateSuccessRate(relevantOps),
            averageDuration: calculateAverageDuration(relevantOps),
            operationBreakdown: calculateOperationBreakdown(relevantOps),
            modelBreakdown: calculateModelBreakdown(relevantOps),
            errorRate: calculateErrorRate(relevantOps)
        )
    }
    
    private func calculateSuccessRate(_ ops: [OperationMetric]) -> Double {
        guard !ops.isEmpty else { return 0 }
        return Double(ops.filter(\.success).count) / Double(ops.count)
    }
    
    private func calculateAverageDuration(_ ops: [OperationMetric]) -> TimeInterval {
        guard !ops.isEmpty else { return 0 }
        return ops.map(\.duration).reduce(0, +) / Double(ops.count)
    }
    
    private func calculateOperationBreakdown(_ ops: [OperationMetric]) -> [CRUDOperation: Int] {
        Dictionary(grouping: ops, by: \.operation)
            .mapValues(\.count)
    }
    
    private func calculateModelBreakdown(_ ops: [OperationMetric]) -> [String: Int] {
        Dictionary(grouping: ops, by: \.modelType)
            .mapValues(\.count)
    }
    
    private func calculateErrorRate(_ ops: [OperationMetric]) -> Double {
        guard !ops.isEmpty else { return 0 }
        return Double(ops.filter { !$0.success }.count) / Double(ops.count)
    }
}

@Observable
class RealtimeStats {
    var operationsPerSecond: Double = 0
    var activeOperations: Int = 0
    var currentErrors: Int = 0
    
    private var recentOperations: [Date] = []
    
    init() {}
    
    func update(with metric: OperationMetric) {
        recentOperations.append(metric.timestamp)
        if !metric.success {
            currentErrors += 1
        }
    }
    
    func updateCurrentStats() {
        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1)
        
        recentOperations = recentOperations.filter { $0 >= oneSecondAgo }
        operationsPerSecond = Double(recentOperations.count)
        
        // Reset error count periodically
        if Int(now.timeIntervalSince1970) % 60 == 0 {
            currentErrors = 0
        }
    }
}

struct OperationMetric {
    let modelType: String
    let operation: CRUDOperation
    let duration: TimeInterval
    let success: Bool
    let recordCount: Int
    let timestamp: Date
}

enum CRUDOperation: String, CaseIterable {
    case create, read, update, delete, batch
}

enum TimeRange: String, CaseIterable {
    case minute = "1m"
    case hour = "1h"
    case day = "24h"
    case week = "7d"
    
    var cutoffDate: Date {
        let now = Date()
        switch self {
        case .minute: return now.addingTimeInterval(-60)
        case .hour: return now.addingTimeInterval(-3600)
        case .day: return now.addingTimeInterval(-86400)
        case .week: return now.addingTimeInterval(-604800)
        }
    }
}

struct AnalyticsStats {
    let totalOperations: Int
    let successRate: Double
    let averageDuration: TimeInterval
    let operationBreakdown: [CRUDOperation: Int]
    let modelBreakdown: [String: Int]
    let errorRate: Double
}

struct CRUDAnalyticsDashboard: View {
    @StateObject private var analytics = CRUDAnalytics.shared
    @State private var selectedTimeRange: TimeRange = .hour
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Time Range Selector
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Realtime Stats
                RealtimeStatsCard(stats: analytics.realtimeStats)
                
                // Analytics Cards
                let stats = analytics.metrics.getStats(for: selectedTimeRange)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricCard(title: "Operations", value: "\(stats.totalOperations)", subtitle: "total", color: .blue)
                    MetricCard(title: "Success Rate", value: "\(Int(stats.successRate * 100))", subtitle: "%", color: .green)
                    MetricCard(title: "Avg Duration", value: "\(Int(stats.averageDuration))", subtitle: "ms", color: .orange)
                    MetricCard(title: "Error Rate", value: "\(Int(stats.errorRate * 100))", subtitle: "%", color: .red)
                }
                
                // Operation Breakdown
                OperationBreakdownChart(breakdown: stats.operationBreakdown)
                
                // Model Usage Chart
                ModelUsageChart(breakdown: stats.modelBreakdown)
            }
            .padding()
        }
        .navigationTitle("CRUD Analytics")
    }
}

struct RealtimeStatsCard: View {
    var stats: RealtimeStats
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Realtime")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(Int(stats.operationsPerSecond))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("ops/sec")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(stats.activeOperations)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(stats.currentErrors)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(stats.currentErrors > 0 ? .red : .primary)
                    Text("errors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct OperationBreakdownChart: View {
    let breakdown: [CRUDOperation: Int]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Operations")
                .font(.headline)
                .fontWeight(.bold)
            
            ForEach(CRUDOperation.allCases, id: \.self) { operation in
                let count = breakdown[operation] ?? 0
                HStack {
                    Text(operation.rawValue.capitalized)
                    Spacer()
                    Text("\(count)")
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ModelUsageChart: View {
    let breakdown: [String: Int]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Models")
                .font(.headline)
                .fontWeight(.bold)
            
            ForEach(breakdown.sorted(by: { $0.value > $1.value }), id: \.key) { model, count in
                HStack {
                    Text(model)
                        .lineLimit(1)
                    Spacer()
                    Text("\(count)")
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}