import Foundation
import SwiftData

protocol ModelValidation {
    var validationErrors: [ValidationError] { get }
    var isValid: Bool { get }
    func validate() -> ValidationResult
}

struct ValidationError: Equatable {
    let field: String
    let message: String
    let severity: ValidationSeverity
    
    enum ValidationSeverity {
        case error
        case warning
    }
}

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationError]
    
    init(errors: [ValidationError] = []) {
        self.errors = errors.filter { $0.severity == .error }
        self.warnings = errors.filter { $0.severity == .warning }
        self.isValid = self.errors.isEmpty
    }
    
    static var success: ValidationResult {
        ValidationResult(errors: [])
    }
}

struct ValidationRules {
    
    static func validateWeight(_ weight: Double) -> ValidationError? {
        if weight < 30.0 {
            return ValidationError(field: "weight", message: "体重は30kg以上である必要があります", severity: .error)
        }
        if weight > 200.0 {
            return ValidationError(field: "weight", message: "体重は200kg以下である必要があります", severity: .error)
        }
        if weight > 150.0 {
            return ValidationError(field: "weight", message: "体重が150kgを超えています。正しい値ですか？", severity: .warning)
        }
        return nil
    }
    
    static func validateHeartRate(_ heartRate: Int, type: HeartRateType) -> ValidationError? {
        switch type {
        case .resting:
            if heartRate < 30 {
                return ValidationError(field: "restingHeartRate", message: "安静時心拍数は30bpm以上である必要があります", severity: .error)
            }
            if heartRate > 100 {
                return ValidationError(field: "restingHeartRate", message: "安静時心拍数は100bpm以下である必要があります", severity: .error)
            }
            if heartRate > 80 {
                return ValidationError(field: "restingHeartRate", message: "安静時心拍数が高めです", severity: .warning)
            }
        case .average:
            if heartRate < 40 {
                return ValidationError(field: "averageHeartRate", message: "平均心拍数は40bpm以上である必要があります", severity: .error)
            }
            if heartRate > 200 {
                return ValidationError(field: "averageHeartRate", message: "平均心拍数は200bpm以下である必要があります", severity: .error)
            }
        case .max:
            if heartRate < 100 {
                return ValidationError(field: "maxHeartRate", message: "最大心拍数は100bpm以上である必要があります", severity: .error)
            }
            if heartRate > 220 {
                return ValidationError(field: "maxHeartRate", message: "最大心拍数は220bpm以下である必要があります", severity: .error)
            }
        }
        return nil
    }
    
    static func validatePower(_ power: Double, type: PowerType) -> ValidationError? {
        switch type {
        case .average:
            if power < 0 {
                return ValidationError(field: "averagePower", message: "平均パワーは0W以上である必要があります", severity: .error)
            }
            if power > 1000 {
                return ValidationError(field: "averagePower", message: "平均パワーは1000W以下である必要があります", severity: .error)
            }
            if power > 500 {
                return ValidationError(field: "averagePower", message: "平均パワーが非常に高いです", severity: .warning)
            }
        case .max:
            if power < 0 {
                return ValidationError(field: "maxPower", message: "最大パワーは0W以上である必要があります", severity: .error)
            }
            if power > 2500 {
                return ValidationError(field: "maxPower", message: "最大パワーは2500W以下である必要があります", severity: .error)
            }
            if power > 1500 {
                return ValidationError(field: "maxPower", message: "最大パワーが非常に高いです", severity: .warning)
            }
        case .ftp:
            if power < 50 {
                return ValidationError(field: "ftp", message: "FTPは50W以上である必要があります", severity: .error)
            }
            if power > 600 {
                return ValidationError(field: "ftp", message: "FTPは600W以下である必要があります", severity: .error)
            }
            if power > 400 {
                return ValidationError(field: "ftp", message: "FTPが非常に高いです", severity: .warning)
            }
        }
        return nil
    }
    
    static func validateDistance(_ distance: Double) -> ValidationError? {
        if distance < 0 {
            return ValidationError(field: "distance", message: "距離は0km以上である必要があります", severity: .error)
        }
        if distance > 500 {
            return ValidationError(field: "distance", message: "距離は500km以下である必要があります", severity: .error)
        }
        if distance > 200 {
            return ValidationError(field: "distance", message: "距離が200kmを超えています", severity: .warning)
        }
        return nil
    }
    
    static func validateDuration(_ duration: Int) -> ValidationError? {
        if duration < 0 {
            return ValidationError(field: "duration", message: "時間は0秒以上である必要があります", severity: .error)
        }
        if duration > 86400 {
            return ValidationError(field: "duration", message: "時間は24時間以下である必要があります", severity: .error)
        }
        if duration > 28800 {
            return ValidationError(field: "duration", message: "時間が8時間を超えています", severity: .warning)
        }
        return nil
    }
    
    static func validateDate(_ date: Date, allowFuture: Bool = false) -> ValidationError? {
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now
        
        if !allowFuture && date > now {
            return ValidationError(field: "date", message: "未来の日付は設定できません", severity: .error)
        }
        if date < oneYearAgo {
            return ValidationError(field: "date", message: "1年以上前の日付は設定できません", severity: .error)
        }
        if allowFuture && date > oneYearFromNow {
            return ValidationError(field: "date", message: "1年以上先の日付は設定できません", severity: .error)
        }
        return nil
    }
    
    static func validatePercentage(_ value: Double, field: String) -> ValidationError? {
        if value < 0 {
            return ValidationError(field: field, message: "\(field)は0%以上である必要があります", severity: .error)
        }
        if value > 100 {
            return ValidationError(field: field, message: "\(field)は100%以下である必要があります", severity: .error)
        }
        return nil
    }
    
    static func validateReps(_ reps: Int) -> ValidationError? {
        if reps < 0 {
            return ValidationError(field: "reps", message: "回数は0以上である必要があります", severity: .error)
        }
        if reps > 1000 {
            return ValidationError(field: "reps", message: "回数は1000以下である必要があります", severity: .error)
        }
        if reps > 100 {
            return ValidationError(field: "reps", message: "回数が100を超えています", severity: .warning)
        }
        return nil
    }
    
    static func validateSets(_ sets: Int) -> ValidationError? {
        if sets < 0 {
            return ValidationError(field: "sets", message: "セット数は0以上である必要があります", severity: .error)
        }
        if sets > 50 {
            return ValidationError(field: "sets", message: "セット数は50以下である必要があります", severity: .error)
        }
        if sets > 20 {
            return ValidationError(field: "sets", message: "セット数が20を超えています", severity: .warning)
        }
        return nil
    }
    
    enum HeartRateType {
        case resting, average, max
    }
    
    enum PowerType {
        case average, max, ftp
    }
}

extension ValidationResult {
    var allMessages: [String] {
        errors.map { "❌ \($0.field): \($0.message)" } +
        warnings.map { "⚠️ \($0.field): \($0.message)" }
    }
    
    var description: String {
        if isValid && warnings.isEmpty {
            return "✅ 検証成功"
        } else if isValid {
            return "✅ 検証成功 (警告: \(warnings.count)件)"
        } else {
            return "❌ 検証失敗 (エラー: \(errors.count)件, 警告: \(warnings.count)件)"
        }
    }
}