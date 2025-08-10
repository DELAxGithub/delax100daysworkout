import Foundation
import SwiftData

enum FTPMeasurementMethod: String, Codable, CaseIterable {
    case twentyMinuteTest = "20MinTest"
    case rampTest = "RampTest"
    case manual = "Manual"
    case autoCalculated = "AutoCalculated"
    
    var displayName: String {
        switch self {
        case .twentyMinuteTest: return "20分テスト"
        case .rampTest: return "ランプテスト"
        case .manual: return "手動入力"
        case .autoCalculated: return "自動計算"
        }
    }
    
    var description: String {
        switch self {
        case .twentyMinuteTest: return "20分間の最大持続パワーテスト"
        case .rampTest: return "段階的負荷増加テスト"
        case .manual: return "ユーザーによる手動入力"
        case .autoCalculated: return "ワークアウトデータから自動計算"
        }
    }
}

@Model
final class FTPHistory {
    var id: UUID = UUID()
    var date: Date
    var ftpValue: Int                 // ワット
    var measurementMethod: FTPMeasurementMethod
    var notes: String?
    var isAutoCalculated: Bool
    var sourceWorkoutId: UUID?        // 元となったワークアウトのID
    var createdAt: Date
    
    init(date: Date = Date(), 
         ftpValue: Int, 
         measurementMethod: FTPMeasurementMethod = .manual, 
         notes: String? = nil, 
         isAutoCalculated: Bool = false,
         sourceWorkoutId: UUID? = nil) {
        self.date = date
        self.ftpValue = ftpValue
        self.measurementMethod = measurementMethod
        self.notes = notes
        self.isAutoCalculated = isAutoCalculated
        self.sourceWorkoutId = sourceWorkoutId
        self.createdAt = Date()
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        return Self.isValidFTP(ftpValue) && date <= Date()
    }
    
    static func isValidFTP(_ value: Int) -> Bool {
        return value >= 50 && value <= 500
    }
    
    // MARK: - Computed Properties
    
    var formattedFTP: String {
        return "\(ftpValue) W"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    var methodDisplayText: String {
        return measurementMethod.displayName
    }
    
    // MARK: - Comparison
    
    func ftpChange(from previousFTP: FTPHistory?) -> Int? {
        guard let previous = previousFTP else { return nil }
        return ftpValue - previous.ftpValue
    }
    
    func ftpChangePercentage(from previousFTP: FTPHistory?) -> Double? {
        guard let previous = previousFTP, previous.ftpValue > 0 else { return nil }
        return Double(ftpValue - previous.ftpValue) / Double(previous.ftpValue) * 100
    }
    
    // MARK: - Power Zones Calculation
    
    func getPowerZones() -> PowerZones {
        return PowerZones(ftp: ftpValue)
    }
}

// MARK: - Power Zones Helper

struct PowerZones {
    let ftp: Int
    
    var zone1: ClosedRange<Int> { // Active Recovery
        0...Int(Double(ftp) * 0.55)
    }
    
    var zone2: ClosedRange<Int> { // Endurance
        Int(Double(ftp) * 0.56)...Int(Double(ftp) * 0.75)
    }
    
    var zone3: ClosedRange<Int> { // Tempo
        Int(Double(ftp) * 0.76)...Int(Double(ftp) * 0.90)
    }
    
    var zone4: ClosedRange<Int> { // Lactate Threshold / SST
        Int(Double(ftp) * 0.91)...Int(Double(ftp) * 1.05)
    }
    
    var zone5: ClosedRange<Int> { // VO2 Max
        Int(Double(ftp) * 1.06)...Int(Double(ftp) * 1.20)
    }
    
    var zone6: ClosedRange<Int> { // Anaerobic Capacity
        Int(Double(ftp) * 1.21)...Int(Double(ftp) * 1.50)
    }
    
    func getZone(for power: Int) -> Int? {
        switch power {
        case zone1: return 1
        case zone2: return 2
        case zone3: return 3
        case zone4: return 4
        case zone5: return 5
        case zone6: return 6
        default: return power > zone6.upperBound ? 7 : nil
        }
    }
    
    func getZoneName(for zone: Int) -> String {
        switch zone {
        case 1: return "アクティブリカバリー"
        case 2: return "エンデュランス"
        case 3: return "テンポ"
        case 4: return "SST/LT"
        case 5: return "VO2 Max"
        case 6: return "アナエロビック"
        case 7: return "ニューロマスキュラー"
        default: return "不明"
        }
    }
}

// MARK: - Sample Data for Previews

extension FTPHistory {
    static let sampleData: [FTPHistory] = [
        FTPHistory(
            date: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            ftpValue: 220,
            measurementMethod: .twentyMinuteTest,
            notes: "初回FTPテスト"
        ),
        FTPHistory(
            date: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
            ftpValue: 235,
            measurementMethod: .rampTest,
            notes: "2週間のトレーニング後"
        ),
        FTPHistory(
            date: Date(),
            ftpValue: 245,
            measurementMethod: .autoCalculated,
            notes: "SST×5での推定値",
            isAutoCalculated: true
        )
    ]
    
    static var sample: FTPHistory {
        sampleData[0]
    }
}

// MARK: - WPR Integration Extension

extension FTPHistory {
    /// FTPHistory保存後にWPRTrackingSystemを自動更新
    @MainActor
    func triggerWPRFTPUpdate(context: ModelContext) {
        do {
            // WPRTrackingSystemを取得または作成
            let descriptor = FetchDescriptor<WPRTrackingSystem>()
            let systems = try context.fetch(descriptor)
            
            let wprSystem: WPRTrackingSystem
            if let existingSystem = systems.first {
                wprSystem = existingSystem
            } else {
                // 新規WPRシステム作成
                wprSystem = WPRTrackingSystem()
                context.insert(wprSystem)
            }
            
            // FTP値を更新
            wprSystem.currentFTP = self.ftpValue
            
            // ベースラインが設定されていない場合は初期設定
            if wprSystem.baselineFTP == 0 {
                wprSystem.baselineFTP = self.ftpValue
            }
            
            // 最終更新日時を更新
            wprSystem.lastUpdated = Date()
            
            // WPR再計算をトリガー
            wprSystem.recalculateWPRMetrics()
            
            try context.save()
            
            print("WPRTrackingSystem updated with new FTP: \(self.ftpValue)W")
            
        } catch {
            print("FTP→WPR更新エラー: \(error)")
        }
    }
}