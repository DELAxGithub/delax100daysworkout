import Foundation
import SwiftData
import SwiftUI

enum WorkoutType: String, Codable, CaseIterable {
    case cycling = "Cycling"
    case strength = "Strength"
    case flexibility = "Flexibility"
    case pilates = "Pilates"
    case yoga = "Yoga"

    var iconName: String {
        switch self {
        case .cycling:
            return "bicycle"
        case .strength:
            return "figure.strengthtraining.traditional"
        case .flexibility, .pilates, .yoga:
            return "figure.flexibility"
        }
    }

    var iconColor: Color {
        switch self {
        case .cycling: return .blue
        case .strength: return .orange
        case .flexibility, .pilates, .yoga: return .green
        }
    }
}

// MARK: - Subtypes for detailed categorization

enum CyclingZone: String, Codable, CaseIterable {
    case z2 = "Z2"
    case sst = "SST"
    case vo2 = "VO2"
    case recovery = "Recovery"
    
    var displayName: String {
        switch self {
        case .z2: return "有酸素 (Z2)"
        case .sst: return "スイートスポット"
        case .vo2: return "高強度 (VO2)"
        case .recovery: return "回復走"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .z2: return "Z2"
        case .sst: return "SST"
        case .vo2: return "VO2"
        case .recovery: return "回復"
        }
    }
    
    var defaultDuration: Int {
        switch self {
        case .z2: return 90
        case .sst: return 60
        case .vo2: return 30
        case .recovery: return 45
        }
    }
}

enum WorkoutMuscleGroup: String, Codable, CaseIterable {
    case chest = "chest"
    case legs = "legs"
    case back = "back"
    case shoulders = "shoulders"
    case arms = "arms"
    case core = "core"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .chest: return "胸"
        case .legs: return "足"
        case .back: return "背中"
        case .shoulders: return "肩"
        case .arms: return "腕"
        case .core: return "腹筋"
        case .custom: return "その他"
        }
    }
}

enum FlexibilityType: String, Codable, CaseIterable {
    case forwardBend = "forwardBend"
    case split = "split"
    case pilates = "pilates"
    case yoga = "yoga"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .forwardBend: return "前屈"
        case .split: return "開脚"
        case .pilates: return "ピラティス"
        case .yoga: return "ヨガ"
        case .general: return "一般柔軟"
        }
    }
    
    var hasMeasurement: Bool {
        switch self {
        case .forwardBend, .split: return true
        case .pilates, .yoga, .general: return false
        }
    }
}

@Model
final class WorkoutRecord {
    var date: Date
    var workoutType: WorkoutType
    var summary: String
    var isCompleted: Bool = false
    var isQuickRecord: Bool = false
    
    // Direct data storage - avoiding @Transient to prevent SwiftData crashes
    var cyclingData: SimpleCyclingData?
    var strengthData: SimpleStrengthData?
    var flexibilityData: SimpleFlexibilityData?
    
    var templateTask: DailyTask?
    
    init(date: Date, workoutType: WorkoutType, summary: String, isQuickRecord: Bool = false) {
        self.date = date
        self.workoutType = workoutType
        self.summary = summary
        self.isQuickRecord = isQuickRecord
    }
    
    func markAsCompleted() {
        self.isCompleted = true
    }
    
    static func fromDailyTask(_ task: DailyTask, date: Date = Date()) -> WorkoutRecord {
        let record = WorkoutRecord(
            date: date,
            workoutType: task.workoutType,
            summary: task.title,
            isQuickRecord: true
        )
        record.templateTask = task
        return record
    }
    
    // MARK: - Migration Support
    
    /// 既存のpilates/yogaレコードをflexibilityに移行
    func migrateToFlexibility() {
        switch workoutType.rawValue {
        case "Pilates":
            workoutType = .flexibility
            if !summary.contains("ピラティス") {
                summary = "ピラティス - \(summary)"
            }
            
        case "Yoga":
            workoutType = .flexibility
            if !summary.contains("ヨガ") {
                summary = "ヨガ - \(summary)"
            }
            
        default:
            break
        }
    }
}

// MARK: - Protocol Conformances

extension WorkoutRecord: Searchable {
    var searchableText: String {
        return summary
    }
    
    var searchableDate: Date {
        return date
    }
    
    var searchableValue: Double {
        // Return a meaningful numeric value for sorting
        switch workoutType {
        case .cycling:
            return Double(cyclingData?.duration ?? 0)
        case .strength:
            return strengthData?.weight ?? 0.0
        case .flexibility, .pilates, .yoga:
            return Double(flexibilityData?.duration ?? 0)
        }
    }
}

// MARK: - Simple Data Structures for Quick Recording

/// シンプルなサイクリングデータ
struct SimpleCyclingData: Codable, Equatable {
    let zone: CyclingZone
    let duration: Int  // 分
    let power: Int?    // ワット（オプション）
    let averageHeartRate: Int?  // 平均心拍数（bpm）
    let wattsPerBpm: Double?    // ワットパー心拍（自動計算）
    
    init(zone: CyclingZone, duration: Int? = nil, power: Int? = nil, averageHeartRate: Int? = nil) {
        self.zone = zone
        self.duration = duration ?? zone.defaultDuration
        self.power = power
        self.averageHeartRate = averageHeartRate
        
        // ワットパー心拍の自動計算
        if let power = power, let heartRate = averageHeartRate, power > 0, heartRate > 0 {
            self.wattsPerBpm = Double(power) / Double(heartRate)
        } else {
            self.wattsPerBpm = nil
        }
    }
}

/// シンプルな筋トレデータ
struct SimpleStrengthData: Codable, Equatable {
    let muscleGroup: WorkoutMuscleGroup
    let customName: String?  // カスタム部位の名前
    let weight: Double       // kg
    let reps: Int
    let sets: Int
    
    init(muscleGroup: WorkoutMuscleGroup, customName: String? = nil, weight: Double, reps: Int, sets: Int) {
        self.muscleGroup = muscleGroup
        self.customName = customName
        self.weight = weight
        self.reps = reps
        self.sets = sets
    }
}

/// シンプルな柔軟性データ
struct SimpleFlexibilityData: Codable, Equatable {
    let type: FlexibilityType
    let duration: Int        // 分
    let measurement: Double? // cm（前屈・開脚のみ）
    
    init(type: FlexibilityType, duration: Int, measurement: Double? = nil) {
        self.type = type
        self.duration = duration
        self.measurement = measurement
    }
}