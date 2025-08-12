import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date
    var weightKg: Double
    
    init(date: Date, weightKg: Double) {
        self.date = date
        self.weightKg = weightKg
    }
}

extension DailyLog: ModelValidation {
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
        
        // 体重の検証
        if let weightError = ValidationRules.validateWeight(weightKg) {
            errors.append(weightError)
        }
        
        return ValidationResult(errors: errors)
    }
    
    func setWeight(_ weight: Double) -> ValidationResult {
        self.weightKg = weight
        return validate()
    }
}