import Foundation
import SwiftData
import UIKit

@Model
final class BugReport: Codable {
    var id: UUID
    var timestamp: Date
    var category: BugCategory
    var bugDescription: String?  // 'description'は予約語のため変更
    var reproductionSteps: String?
    var expectedBehavior: String?
    var actualBehavior: String?
    var screenshot: Data?
    var deviceInfo: DeviceInfo
    var appVersion: String
    var currentView: String
    var userActions: [UserAction]
    var logs: [LogEntry]
    
    init(
        category: BugCategory,
        description: String? = nil,
        reproductionSteps: String? = nil,
        expectedBehavior: String? = nil,
        actualBehavior: String? = nil,
        screenshot: Data? = nil,
        currentView: String,
        userActions: [UserAction] = [],
        logs: [LogEntry] = []
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.category = category
        self.bugDescription = description
        self.reproductionSteps = reproductionSteps
        self.expectedBehavior = expectedBehavior
        self.actualBehavior = actualBehavior
        self.screenshot = screenshot
        self.deviceInfo = DeviceInfo.current
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.currentView = currentView
        self.userActions = userActions
        self.logs = logs
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, category
        case bugDescription = "description"
        case reproductionSteps, expectedBehavior, actualBehavior, screenshot
        case deviceInfo, appVersion, currentView, userActions, logs
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.category = try container.decode(BugCategory.self, forKey: .category)
        self.bugDescription = try container.decodeIfPresent(String.self, forKey: .bugDescription)
        self.reproductionSteps = try container.decodeIfPresent(String.self, forKey: .reproductionSteps)
        self.expectedBehavior = try container.decodeIfPresent(String.self, forKey: .expectedBehavior)
        self.actualBehavior = try container.decodeIfPresent(String.self, forKey: .actualBehavior)
        self.screenshot = try container.decodeIfPresent(Data.self, forKey: .screenshot)
        self.deviceInfo = try container.decode(DeviceInfo.self, forKey: .deviceInfo)
        self.appVersion = try container.decode(String.self, forKey: .appVersion)
        self.currentView = try container.decode(String.self, forKey: .currentView)
        self.userActions = try container.decode([UserAction].self, forKey: .userActions)
        self.logs = try container.decode([LogEntry].self, forKey: .logs)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(bugDescription, forKey: .bugDescription)
        try container.encodeIfPresent(reproductionSteps, forKey: .reproductionSteps)
        try container.encodeIfPresent(expectedBehavior, forKey: .expectedBehavior)
        try container.encodeIfPresent(actualBehavior, forKey: .actualBehavior)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try container.encode(deviceInfo, forKey: .deviceInfo)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(currentView, forKey: .currentView)
        try container.encode(userActions, forKey: .userActions)
        try container.encode(logs, forKey: .logs)
    }
}

enum BugCategory: String, Codable, CaseIterable {
    case buttonNotWorking = "button_not_working"
    case displayIssue = "display_issue"
    case appFreeze = "app_freeze"
    case dataNotSaved = "data_not_saved"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .buttonNotWorking: return "ボタンが効かない"
        case .displayIssue: return "表示がおかしい"
        case .appFreeze: return "アプリが固まる"
        case .dataNotSaved: return "データが保存されない"
        case .other: return "その他"
        }
    }
}

struct DeviceInfo: Codable {
    let model: String
    let osVersion: String
    let screenSize: String
    
    static var current: DeviceInfo {
        let device = UIDevice.current
        let screen = UIScreen.main
        
        return DeviceInfo(
            model: device.model,
            osVersion: "\(device.systemName) \(device.systemVersion)",
            screenSize: "\(Int(screen.bounds.width))x\(Int(screen.bounds.height))"
        )
    }
}

struct UserAction: Codable {
    let timestamp: Date
    let action: String
    let viewName: String
    let details: [String: String]?
    
    init(action: String, viewName: String, details: [String: String]? = nil) {
        self.timestamp = Date()
        self.action = action
        self.viewName = viewName
        self.details = details
    }
}

struct LogEntry: Codable {
    let timestamp: Date
    let level: LogLevel
    let message: String
    let source: String?
    
    init(level: LogLevel, message: String, source: String? = nil) {
        self.timestamp = Date()
        self.level = level
        self.message = message
        self.source = source
    }
}

enum LogLevel: String, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}