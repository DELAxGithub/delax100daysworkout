import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let database = Logger(subsystem: subsystem, category: "Database")
    static let general = Logger(subsystem: subsystem, category: "General")
    static let performance = Logger(subsystem: subsystem, category: "Performance")
    static let error = Logger(subsystem: subsystem, category: "Error")
    static let debug = Logger(subsystem: subsystem, category: "Debug")
}