import Foundation
import SwiftData

enum MetricDataSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case appleHealth = "AppleHealth"
    case calculated = "Calculated"
    
    var displayName: String {
        switch self {
        case .manual: return "手動入力"
        case .appleHealth: return "Apple Health"
        case .calculated: return "自動計算"
        }
    }
    
    var iconName: String {
        switch self {
        case .manual: return "hand.tap"
        case .appleHealth: return "heart.text.square"
        case .calculated: return "function"
        }
    }
}

@Model
final class DailyMetric {
    var id: UUID = UUID()
    var date: Date
    var weightKg: Double?
    var restingHeartRate: Int?
    var maxHeartRate: Int?
    var dataSource: MetricDataSource
    var lastSyncDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(date: Date = Date(),
         weightKg: Double? = nil,
         restingHeartRate: Int? = nil,
         maxHeartRate: Int? = nil,
         dataSource: MetricDataSource = .manual) {
        self.date = date
        self.weightKg = weightKg
        self.restingHeartRate = restingHeartRate
        self.maxHeartRate = maxHeartRate
        self.dataSource = dataSource
        self.lastSyncDate = dataSource == .appleHealth ? Date() : nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        var validWeight = true
        var validRestingHR = true
        var validMaxHR = true
        
        if let weight = weightKg {
            validWeight = Self.isValidWeight(weight)
        }
        
        if let restingHR = restingHeartRate {
            validRestingHR = Self.isValidRestingHeartRate(restingHR)
        }
        
        if let maxHR = maxHeartRate {
            validMaxHR = Self.isValidMaxHeartRate(maxHR)
        }
        
        return validWeight && validRestingHR && validMaxHR && date <= Date()
    }
    
    static func isValidWeight(_ weight: Double) -> Bool {
        return weight > 30.0 && weight < 200.0
    }
    
    static func isValidRestingHeartRate(_ hr: Int) -> Bool {
        return hr >= 40 && hr <= 100
    }
    
    static func isValidMaxHeartRate(_ hr: Int) -> Bool {
        return hr >= 120 && hr <= 220
    }
    
    var hasAnyData: Bool {
        return weightKg != nil || restingHeartRate != nil || maxHeartRate != nil
    }
    
    // MARK: - Computed Properties
    
    var formattedWeight: String? {
        guard let weight = weightKg else { return nil }
        return String(format: "%.1f kg", weight)
    }
    
    var formattedRestingHR: String? {
        guard let hr = restingHeartRate else { return nil }
        return "\(hr) bpm"
    }
    
    var formattedMaxHR: String? {
        guard let hr = maxHeartRate else { return nil }
        return "\(hr) bpm"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    // MARK: - Data Management
    
    func updateFromHealthKit(weight: Double? = nil, 
                           restingHR: Int? = nil, 
                           maxHR: Int? = nil) {
        if let weight = weight, Self.isValidWeight(weight) {
            self.weightKg = weight
        }
        
        if let restingHR = restingHR, Self.isValidRestingHeartRate(restingHR) {
            self.restingHeartRate = restingHR
        }
        
        if let maxHR = maxHR, Self.isValidMaxHeartRate(maxHR) {
            self.maxHeartRate = maxHR
        }
        
        self.dataSource = .appleHealth
        self.lastSyncDate = Date()
        self.updatedAt = Date()
    }
    
    func mergeWith(_ other: DailyMetric) -> DailyMetric {
        let merged = DailyMetric(date: self.date)
        
        // より新しいデータを優先、ただしApple Healthを手動入力より優先
        merged.weightKg = preferredValue(
            current: (self.weightKg, self.dataSource, self.updatedAt),
            other: (other.weightKg, other.dataSource, other.updatedAt)
        )
        
        merged.restingHeartRate = preferredValue(
            current: (self.restingHeartRate, self.dataSource, self.updatedAt),
            other: (other.restingHeartRate, other.dataSource, other.updatedAt)
        )
        
        merged.maxHeartRate = preferredValue(
            current: (self.maxHeartRate, self.dataSource, self.updatedAt),
            other: (other.maxHeartRate, other.dataSource, other.updatedAt)
        )
        
        // データソースは最も信頼性の高いものを選択
        merged.dataSource = [self.dataSource, other.dataSource].max { a, b in
            dataSourcePriority(a) < dataSourcePriority(b)
        } ?? self.dataSource
        
        merged.lastSyncDate = [self.lastSyncDate, other.lastSyncDate].compactMap { $0 }.max()
        merged.createdAt = min(self.createdAt, other.createdAt)
        merged.updatedAt = max(self.updatedAt, other.updatedAt)
        
        return merged
    }
    
    private func preferredValue<T>(current: (T?, MetricDataSource, Date), 
                                 other: (T?, MetricDataSource, Date)) -> T? {
        let (currentValue, currentSource, currentDate) = current
        let (otherValue, otherSource, otherDate) = other
        
        guard let currentVal = currentValue else { return otherValue }
        guard let otherVal = otherValue else { return currentVal }
        
        let currentPriority = dataSourcePriority(currentSource)
        let otherPriority = dataSourcePriority(otherSource)
        
        if currentPriority != otherPriority {
            return currentPriority > otherPriority ? currentVal : otherVal
        } else {
            return currentDate > otherDate ? currentVal : otherVal
        }
    }
    
    private func dataSourcePriority(_ source: MetricDataSource) -> Int {
        switch source {
        case .appleHealth: return 3
        case .manual: return 2
        case .calculated: return 1
        }
    }
    
    // MARK: - Health Calculations
    
    var estimatedMaxHeartRate: Int? {
        // Tanaka式: 208 - (0.7 × 年齢)
        // 年齢が不明な場合は一般的な220-年齢式は使えないため nil を返す
        return nil
    }
    
    var heartRateReserve: Int? {
        guard let maxHR = maxHeartRate, let restingHR = restingHeartRate else { return nil }
        return maxHR - restingHR
    }
    
    // MARK: - Date Helpers
    
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    var dateKey: String {
        return Self.dateKey(for: date)
    }
    
    // MARK: - Query Helpers
    
    static func sameDayPredicate(for date: Date) -> Predicate<DailyMetric> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        return #Predicate<DailyMetric> { metric in
            metric.date >= startOfDay && metric.date < endOfDay
        }
    }
    
    static func dateRangePredicate(from startDate: Date, to endDate: Date) -> Predicate<DailyMetric> {
        return #Predicate<DailyMetric> { metric in
            metric.date >= startDate && metric.date <= endDate
        }
    }
}

// MARK: - Sample Data for Previews

extension DailyMetric {
    static let sampleData: [DailyMetric] = [
        DailyMetric(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            weightKg: 70.5,
            restingHeartRate: 52,
            maxHeartRate: 185,
            dataSource: .appleHealth
        ),
        DailyMetric(
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            weightKg: 70.2,
            restingHeartRate: 50,
            dataSource: .manual
        ),
        DailyMetric(
            date: Date(),
            weightKg: 69.8,
            restingHeartRate: 48,
            maxHeartRate: 187,
            dataSource: .appleHealth
        )
    ]
    
    static var sample: DailyMetric {
        sampleData[0]
    }
    
    static var sampleWithWeight: DailyMetric {
        sampleData[2]
    }
}

// MARK: - WPR Integration Extension

extension DailyMetric {
    /// DailyMetric（体重）保存後にWPRTrackingSystemを自動更新
    @MainActor
    func triggerWPRWeightUpdate(context: ModelContext) {
        // 体重データがない場合は何もしない
        guard let newWeight = self.weightKg else { return }
        
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
            
            // 体重値を更新
            wprSystem.currentWeight = newWeight
            
            // ベースラインが設定されていない場合は初期設定
            if wprSystem.baselineWeight == 0.0 {
                wprSystem.baselineWeight = newWeight
            }
            
            // 最終更新日時を更新
            wprSystem.lastUpdated = Date()
            
            // WPR再計算をトリガー
            wprSystem.recalculateWPRMetrics()
            
            // 体重変化によるボトルネック影響分析
            analyzeWeightImpactOnBottleneck(wprSystem: wprSystem, newWeight: newWeight)
            
            try context.save()
            
            print("WPRTrackingSystem updated with new weight: \(newWeight)kg")
            
        } catch {
            print("体重→WPR更新エラー: \(error)")
        }
    }
    
    /// 体重変化がボトルネックに与える影響を分析
    private func analyzeWeightImpactOnBottleneck(wprSystem: WPRTrackingSystem, newWeight: Double) {
        guard wprSystem.baselineWeight > 0 else { return }
        
        let weightChange = newWeight - wprSystem.baselineWeight
        let weightChangePercent = (weightChange / wprSystem.baselineWeight) * 100
        
        // 体重減少はWPR向上に直結するため、体重ボトルネックの改善として記録
        if abs(weightChangePercent) > 2.0 { // 2%以上の変化
            if weightChange < 0 {
                // 体重減少 = WPR改善要因
                wprSystem.projectedWPRGain += abs(weightChange) * (Double(wprSystem.currentFTP) / (wprSystem.baselineWeight * wprSystem.baselineWeight))
                
                // 体重がボトルネックの場合、改善の可能性
                if wprSystem.currentBottleneck == .weight {
                    print("体重減少により WPR ボトルネックが改善: \(String(format: "%.1f", weightChangePercent))%")
                }
            } else {
                // 体重増加 = WPR低下要因（筋量増加でない場合）
                print("体重増加による WPR への影響: \(String(format: "%.1f", weightChangePercent))%")
                
                // 体重増加が著しい場合はボトルネック候補
                if weightChangePercent > 5.0 {
                    wprSystem.currentBottleneck = .weight
                }
            }
        }
    }
}