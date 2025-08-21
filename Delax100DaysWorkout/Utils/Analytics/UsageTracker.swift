import SwiftUI
import Foundation
import OSLog

// MARK: - Usage Tracker

@MainActor
class UsageTracker: ObservableObject {
    static let shared = UsageTracker()
    
    @Published var events: [UsageEvent] = []
    @Published var isTracking = false
    
    private let maxEvents = 1000
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "UsageTrackerEvents"
    
    private init() {
        loadPersistedEvents()
    }
    
    // MARK: - Tracking Control
    
    func startTracking() {
        isTracking = true
        track(.systemEvent("tracking_started"))
    }
    
    func stopTracking() {
        track(.systemEvent("tracking_stopped"))
        isTracking = false
        persistEvents()
    }
    
    // MARK: - Event Tracking
    
    func track(_ event: UsageEvent) {
        guard isTracking else { return }
        
        events.append(event)
        
        // Maintain event limit
        if events.count > maxEvents {
            events.removeFirst(maxEvents / 2)
        }
        
        // Auto-persist for important events
        if case .componentUsage = event {
            persistEvents()
        }
    }
    
    // MARK: - Component Usage
    
    func trackCardUsage(_ cardType: String, action: CardAction) {
        track(.componentUsage(
            component: "BaseCard",
            action: action.rawValue,
            metadata: ["cardType": cardType]
        ))
    }
    
    func trackViewNavigation(from: String, to: String) {
        track(.navigation(
            from: from,
            to: to,
            timestamp: Date()
        ))
    }
    
    func trackFeatureUsage(_ feature: String, context: [String: String] = [:]) {
        track(.featureUsage(
            feature: feature,
            timestamp: Date(),
            context: context
        ))
    }
    
    // MARK: - Analytics
    
    func getUsageStats() -> UsageStats {
        let totalEvents = events.count
        let cardEvents = events.filter { 
            if case .componentUsage(let component, _, _) = $0 {
                return component == "BaseCard"
            }
            return false
        }
        
        let navigationEvents = events.filter {
            if case .navigation = $0 { return true }
            return false
        }
        
        let featureEvents = events.filter {
            if case .featureUsage = $0 { return true }
            return false
        }
        
        // Calculate card action distribution
        var cardActionCounts: [String: Int] = [:]
        for event in cardEvents {
            if case .componentUsage(_, let action, _) = event {
                cardActionCounts[action, default: 0] += 1
            }
        }
        
        return UsageStats(
            totalEvents: totalEvents,
            cardInteractions: cardEvents.count,
            navigationEvents: navigationEvents.count,
            featureUsages: featureEvents.count,
            cardActionDistribution: cardActionCounts,
            trackingDuration: getTrackingDuration()
        )
    }
    
    private func getTrackingDuration() -> TimeInterval {
        guard let firstEvent = events.first,
              let lastEvent = events.last else { return 0 }
        
        return lastEvent.timestamp.timeIntervalSince(firstEvent.timestamp)
    }
    
    // MARK: - Data Export
    
    func exportData() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(events)
            return String(data: data, encoding: .utf8) ?? "Export failed"
        } catch {
            return "Export error: \(error.localizedDescription)"
        }
    }
    
    func generateReport() -> UsageReport {
        let stats = getUsageStats()
        
        return UsageReport(
            generatedAt: Date(),
            stats: UsageStatsSnapshot(from: stats),
            topFeatures: getTopFeatures(),
            userJourney: getUserJourney(),
            recommendations: generateRecommendations()
        )
    }
    
    private func getTopFeatures() -> [String] {
        var featureCounts: [String: Int] = [:]
        
        for event in events {
            if case .featureUsage(let feature, _, _) = event {
                featureCounts[feature, default: 0] += 1
            }
        }
        
        return featureCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func getUserJourney() -> [String] {
        return events
            .compactMap { event in
                if case .navigation(_, let to, _) = event {
                    return to
                }
                return nil
            }
            .suffix(10)
            .map { $0 }
    }
    
    private func generateRecommendations() -> [String] {
        let stats = getUsageStats()
        var recommendations: [String] = []
        
        // Card usage recommendations
        if stats.cardInteractions < 5 {
            recommendations.append("Consider adding more interactive cards")
        }
        
        // Navigation recommendations
        if stats.navigationEvents > stats.cardInteractions * 2 {
            recommendations.append("Users navigate frequently - consider improving card content")
        }
        
        // Feature adoption recommendations
        if stats.featureUsages < 10 {
            recommendations.append("Feature adoption is low - consider improving discoverability")
        }
        
        return recommendations
    }
    
    // MARK: - Persistence
    
    private func persistEvents() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(events)
            userDefaults.set(data, forKey: eventsKey)
        } catch {
            Logger.error.error("Failed to persist usage events: \(error)")
        }
    }
    
    private func loadPersistedEvents() {
        guard let data = userDefaults.data(forKey: eventsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            events = try decoder.decode([UsageEvent].self, from: data)
        } catch {
            Logger.error.error("Failed to load persisted events: \(error)")
        }
    }
}

// MARK: - Usage Event

enum UsageEvent: Codable {
    case componentUsage(component: String, action: String, metadata: [String: String])
    case navigation(from: String, to: String, timestamp: Date)
    case featureUsage(feature: String, timestamp: Date, context: [String: String])
    case systemEvent(String)
    
    var timestamp: Date {
        switch self {
        case .componentUsage, .systemEvent:
            return Date()
        case .navigation(_, _, let timestamp):
            return timestamp
        case .featureUsage(_, let timestamp, _):
            return timestamp
        }
    }
}

// MARK: - Card Action

enum CardAction: String, Codable {
    case tap = "tap"
    case longPress = "long_press"
    case swipeLeft = "swipe_left"
    case swipeRight = "swipe_right"
    case appeared = "appeared"
    case disappeared = "disappeared"
}

// MARK: - Usage Stats

struct UsageStats {
    let totalEvents: Int
    let cardInteractions: Int
    let navigationEvents: Int
    let featureUsages: Int
    let cardActionDistribution: [String: Int]
    let trackingDuration: TimeInterval
    
    var cardInteractionRate: Double {
        guard totalEvents > 0 else { return 0 }
        return Double(cardInteractions) / Double(totalEvents)
    }
    
    var averageSessionLength: TimeInterval {
        return trackingDuration / max(1, Double(navigationEvents))
    }
}

// MARK: - Usage Report

struct UsageReport: Codable {
    let generatedAt: Date
    let stats: UsageStatsSnapshot
    let topFeatures: [String]
    let userJourney: [String]
    let recommendations: [String]
}

struct UsageStatsSnapshot: Codable {
    let totalEvents: Int
    let cardInteractions: Int
    let navigationEvents: Int
    let featureUsages: Int
    let cardInteractionRate: Double
    let averageSessionLength: TimeInterval
    
    init(from stats: UsageStats) {
        self.totalEvents = stats.totalEvents
        self.cardInteractions = stats.cardInteractions
        self.navigationEvents = stats.navigationEvents
        self.featureUsages = stats.featureUsages
        self.cardInteractionRate = stats.cardInteractionRate
        self.averageSessionLength = stats.averageSessionLength
    }
}

// MARK: - View Extensions

extension View {
    func trackCardUsage(_ cardType: String, action: CardAction) -> some View {
        self.onAppear {
            UsageTracker.shared.trackCardUsage(cardType, action: .appeared)
        }
        .onDisappear {
            UsageTracker.shared.trackCardUsage(cardType, action: .disappeared)
        }
    }
    
    func trackNavigation(to destination: String) -> some View {
        self.onAppear {
            UsageTracker.shared.trackViewNavigation(from: "unknown", to: destination)
        }
    }
    
    func trackFeature(_ feature: String, context: [String: String] = [:]) -> some View {
        self.onAppear {
            UsageTracker.shared.trackFeatureUsage(feature, context: context)
        }
    }
}