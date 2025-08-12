import Foundation
import SwiftData
import SwiftUI

enum WorkoutType: String, Codable, CaseIterable {
    case cycling = "Cycling"
    case strength = "Strength"
    case flexibility = "Flexibility"

    var iconName: String {
        switch self {
        case .cycling:
            return "bicycle"
        case .strength:
            return "figure.strengthtraining.traditional"
        case .flexibility:
            return "figure.flexibility"
        }
    }

    var iconColor: Color {
        switch self {
        case .cycling: return .blue
        case .strength: return .orange
        case .flexibility: return .green
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
    
    var cyclingDetail: CyclingDetail?
    var strengthDetails: [StrengthDetail]?
    var flexibilityDetail: FlexibilityDetail?
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
}

extension WorkoutRecord: ModelValidation {
    var validationErrors: [ValidationError] {
        validate().errors + validate().warnings
    }
    
    var isValid: Bool {
        validate().isValid
    }
    
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []
        
        // 日付の検証
        if let dateError = ValidationRules.validateDate(date, allowFuture: false) {
            errors.append(dateError)
        }
        
        // サマリーの検証
        if summary.isEmpty {
            errors.append(ValidationError(
                field: "summary",
                message: "ワークアウトの概要は必須です",
                severity: .error
            ))
        } else if summary.count > 500 {
            errors.append(ValidationError(
                field: "summary",
                message: "概要は500文字以下にしてください",
                severity: .error
            ))
        }
        
        // 関連詳細データの検証
        if let cycling = cyclingDetail {
            let cyclingValidation = validateCyclingDetail(cycling)
            errors.append(contentsOf: cyclingValidation)
        }
        
        if let strength = strengthDetails {
            for (index, detail) in strength.enumerated() {
                let strengthValidation = validateStrengthDetail(detail, index: index)
                errors.append(contentsOf: strengthValidation)
            }
        }
        
        if let flexibility = flexibilityDetail {
            let flexValidation = validateFlexibilityDetail(flexibility)
            errors.append(contentsOf: flexValidation)
        }
        
        // ワークアウトタイプと詳細データの整合性チェック
        switch workoutType {
        case .cycling:
            if cyclingDetail == nil && isCompleted {
                errors.append(ValidationError(
                    field: "cyclingDetail",
                    message: "サイクリングワークアウトには詳細データが必要です",
                    severity: .warning
                ))
            }
        case .strength:
            if (strengthDetails == nil || strengthDetails?.isEmpty == true) && isCompleted {
                errors.append(ValidationError(
                    field: "strengthDetails",
                    message: "筋トレワークアウトには詳細データが必要です",
                    severity: .warning
                ))
            }
        case .flexibility:
            if flexibilityDetail == nil && isCompleted {
                errors.append(ValidationError(
                    field: "flexibilityDetail",
                    message: "柔軟性ワークアウトには詳細データが必要です",
                    severity: .warning
                ))
            }
        }
        
        return ValidationResult(errors: errors)
    }
    
    private func validateCyclingDetail(_ detail: CyclingDetail) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if let distanceError = ValidationRules.validateDistance(detail.distance) {
            errors.append(distanceError)
        }
        
        if let durationError = ValidationRules.validateDuration(detail.duration) {
            errors.append(durationError)
        }
        
        if let powerError = ValidationRules.validatePower(detail.averagePower, type: .average) {
            errors.append(powerError)
        }
        
        if let avgHR = detail.averageHeartRate {
            if let hrError = ValidationRules.validateHeartRate(avgHR, type: .average) {
                errors.append(hrError)
            }
        }
        
        if let maxHR = detail.maxHeartRate {
            if let hrError = ValidationRules.validateHeartRate(maxHR, type: .max) {
                errors.append(hrError)
            }
        }
        
        if let maxPower = detail.maxPower {
            if let powerError = ValidationRules.validatePower(maxPower, type: .max) {
                errors.append(powerError)
            }
        }
        
        // 平均と最大の整合性チェック
        if let avgHR = detail.averageHeartRate, let maxHR = detail.maxHeartRate {
            if avgHR > maxHR {
                errors.append(ValidationError(
                    field: "heartRate",
                    message: "平均心拍数が最大心拍数を超えています",
                    severity: .error
                ))
            }
        }
        
        if let maxPower = detail.maxPower {
            if detail.averagePower > maxPower {
                errors.append(ValidationError(
                    field: "power",
                    message: "平均パワーが最大パワーを超えています",
                    severity: .error
                ))
            }
        }
        
        return errors
    }
    
    private func validateStrengthDetail(_ detail: StrengthDetail, index: Int) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if detail.exercise.isEmpty {
            errors.append(ValidationError(
                field: "strengthDetail[\(index)].exercise",
                message: "エクササイズ名は必須です",
                severity: .error
            ))
        }
        
        if let setsError = ValidationRules.validateSets(detail.sets) {
            var error = setsError
            error = ValidationError(
                field: "strengthDetail[\(index)].sets",
                message: error.message,
                severity: error.severity
            )
            errors.append(error)
        }
        
        if let repsError = ValidationRules.validateReps(detail.reps) {
            var error = repsError
            error = ValidationError(
                field: "strengthDetail[\(index)].reps",
                message: error.message,
                severity: error.severity
            )
            errors.append(error)
        }
        
        if detail.weight < 0 {
            errors.append(ValidationError(
                field: "strengthDetail[\(index)].weight",
                message: "重量は0kg以上である必要があります",
                severity: .error
            ))
        } else if detail.weight > 500 {
            errors.append(ValidationError(
                field: "strengthDetail[\(index)].weight",
                message: "重量が500kgを超えています",
                severity: .warning
            ))
        }
        
        return errors
    }
    
    private func validateFlexibilityDetail(_ detail: FlexibilityDetail) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if let durationError = ValidationRules.validateDuration(detail.duration) {
            errors.append(ValidationError(
                field: "flexibilityDetail.duration",
                message: durationError.message,
                severity: durationError.severity
            ))
        }
        
        // FlexibilityDetailの詳細な検証はモデル自体のvalidate()メソッドで行う
        let detailValidation = detail.validate()
        errors.append(contentsOf: detailValidation.errors)
        errors.append(contentsOf: detailValidation.warnings)
        
        return errors
    }
}