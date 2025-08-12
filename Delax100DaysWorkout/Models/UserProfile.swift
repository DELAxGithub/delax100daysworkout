import Foundation
import SwiftData

@Model
final class UserProfile {
    // A unique identifier, although for a single-user app, we'll likely only have one instance.
    @Attribute(.unique) var id: UUID
    
    // Goal Tracking
    var goalDate: Date
    
    // Weight Goals (in kilograms)
    var startWeightKg: Double
    var goalWeightKg: Double
    
    // Cycling FTP (Functional Threshold Power) Goals
    var startFtp: Int
    var goalFtp: Int
    
    init(id: UUID = UUID(), goalDate: Date = Date().addingTimeInterval(100 * 24 * 60 * 60), startWeightKg: Double = 0.0, goalWeightKg: Double = 0.0, startFtp: Int = 0, goalFtp: Int = 0) {
        self.id = id
        self.goalDate = goalDate
        self.startWeightKg = startWeightKg
        self.goalWeightKg = goalWeightKg
        self.startFtp = startFtp
        self.goalFtp = goalFtp
    }
}

extension UserProfile: ModelValidation {
    var validationErrors: [ValidationError] {
        validate().errors + validate().warnings
    }
    
    var isValid: Bool {
        validate().isValid
    }
    
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []
        
        // 目標日付の検証
        if let dateError = ValidationRules.validateDate(goalDate, allowFuture: true) {
            errors.append(dateError)
        }
        
        // 開始体重の検証
        if startWeightKg > 0 {
            if let weightError = ValidationRules.validateWeight(startWeightKg) {
                errors.append(ValidationError(
                    field: "startWeightKg",
                    message: weightError.message,
                    severity: weightError.severity
                ))
            }
        }
        
        // 目標体重の検証
        if goalWeightKg > 0 {
            if let weightError = ValidationRules.validateWeight(goalWeightKg) {
                errors.append(ValidationError(
                    field: "goalWeightKg",
                    message: weightError.message,
                    severity: weightError.severity
                ))
            }
        }
        
        // 開始FTPの検証
        if startFtp > 0 {
            if let ftpError = ValidationRules.validatePower(Double(startFtp), type: .ftp) {
                errors.append(ValidationError(
                    field: "startFtp",
                    message: ftpError.message,
                    severity: ftpError.severity
                ))
            }
        }
        
        // 目標FTPの検証
        if goalFtp > 0 {
            if let ftpError = ValidationRules.validatePower(Double(goalFtp), type: .ftp) {
                errors.append(ValidationError(
                    field: "goalFtp",
                    message: ftpError.message,
                    severity: ftpError.severity
                ))
            }
        }
        
        // 論理的整合性チェック
        if startWeightKg > 0 && goalWeightKg > 0 {
            let weightChangePercent = abs((goalWeightKg - startWeightKg) / startWeightKg * 100)
            if weightChangePercent > 30 {
                errors.append(ValidationError(
                    field: "weightGoal",
                    message: "体重変化が30%を超えています。現実的な目標設定を推奨します",
                    severity: .warning
                ))
            }
        }
        
        if startFtp > 0 && goalFtp > 0 {
            let ftpChangePercent = Double(abs(goalFtp - startFtp)) / Double(startFtp) * 100
            if ftpChangePercent > 50 {
                errors.append(ValidationError(
                    field: "ftpGoal",
                    message: "FTP変化が50%を超えています。段階的な目標設定を推奨します",
                    severity: .warning
                ))
            }
        }
        
        return ValidationResult(errors: errors)
    }
    
    func setGoals(startWeight: Double? = nil, goalWeight: Double? = nil,
                  startFtp: Int? = nil, goalFtp: Int? = nil,
                  goalDate: Date? = nil) -> ValidationResult {
        
        if let weight = startWeight {
            self.startWeightKg = weight
        }
        if let weight = goalWeight {
            self.goalWeightKg = weight
        }
        if let ftp = startFtp {
            self.startFtp = ftp
        }
        if let ftp = goalFtp {
            self.goalFtp = ftp
        }
        if let date = goalDate {
            self.goalDate = date
        }
        
        return validate()
    }
}