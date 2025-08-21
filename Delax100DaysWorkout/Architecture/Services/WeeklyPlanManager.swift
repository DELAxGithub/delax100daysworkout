import Foundation

// WeeklyPlanManagerプロトコル
@MainActor
protocol WeeklyPlanManager {
    var autoUpdateEnabled: Bool { get set }
    var maxCostPerUpdate: Double { get set }
    var updateFrequency: TimeInterval { get set }
    var lastUpdateDate: Date? { get set }
    var analysisCount: Int { get set }
    var updateStatus: UpdateStatus { get }
    
    var analysisDataDescription: String { get }
    var analysisResultDescription: String { get }
    var monthlyUsageDescription: String { get }
    
    func requestManualUpdate() async
}

// 更新状態を表すenum
enum UpdateStatus: Equatable {
    case idle
    case analyzing
    case completed
    case failed(String)
}