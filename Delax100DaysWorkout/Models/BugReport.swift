import Foundation
import SwiftData
import UIKit

struct BugReport: Codable {
    let id: UUID
    let timestamp: Date
    let category: BugCategory
    let description: String?
    let reproductionSteps: String?
    let expectedBehavior: String?
    let actualBehavior: String?
    let screenshot: Data?
    let deviceInfo: DeviceInfo
    let appVersion: String
    let currentView: String
    let userActions: [UserAction]
    let logs: [LogEntry]
    
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
        self.description = description
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