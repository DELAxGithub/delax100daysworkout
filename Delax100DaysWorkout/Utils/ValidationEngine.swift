import Foundation
import SwiftData

// MARK: - Validation Engine

protocol Validatable {
    func validate() -> ValidationResult
}

struct ValidationEngine {
    
    // MARK: - Core Validation Methods
    
    static func validate<T: Validatable>(_ model: T) -> ValidationResult {
        return model.validate()
    }
    
    static func validateBatch<T: Validatable>(_ models: [T]) -> ValidationResult {
        for (index, model) in models.enumerated() {
            let result = model.validate()
            if !result.isValid {
                return .failure("Validation failed at index \(index): \(result.errorMessage ?? "Unknown error")")
            }
        }
        return .success
    }
    
    // MARK: - Common Validation Rules
    
    static func validateRequired(_ value: String?, fieldName: String) -> ValidationResult {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure("\(fieldName) is required")
        }
        return .success
    }
    
    static func validateMinLength(_ value: String?, minLength: Int, fieldName: String) -> ValidationResult {
        guard let value = value, value.count >= minLength else {
            return .failure("\(fieldName) must be at least \(minLength) characters")
        }
        return .success
    }
    
    static func validateMaxLength(_ value: String?, maxLength: Int, fieldName: String) -> ValidationResult {
        guard let value = value, value.count <= maxLength else {
            return .failure("\(fieldName) must be no more than \(maxLength) characters")
        }
        return .success
    }
    
    static func validateRange<T: Comparable>(_ value: T?, min: T, max: T, fieldName: String) -> ValidationResult {
        guard let value = value, value >= min && value <= max else {
            return .failure("\(fieldName) must be between \(min) and \(max)")
        }
        return .success
    }
    
    static func validatePositive(_ value: Double?, fieldName: String) -> ValidationResult {
        guard let value = value, value > 0 else {
            return .failure("\(fieldName) must be positive")
        }
        return .success
    }
    
    static func validateEmail(_ email: String?) -> ValidationResult {
        guard let email = email else {
            return .failure("Email is required")
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return .failure("Invalid email format")
        }
        
        return .success
    }
    
    static func validateDate(_ date: Date?, before: Date? = nil, after: Date? = nil, fieldName: String) -> ValidationResult {
        guard let date = date else {
            return .failure("\(fieldName) is required")
        }
        
        if let beforeDate = before, date >= beforeDate {
            return .failure("\(fieldName) must be before \(beforeDate)")
        }
        
        if let afterDate = after, date <= afterDate {
            return .failure("\(fieldName) must be after \(afterDate)")
        }
        
        return .success
    }
    
    // MARK: - Composite Validation
    
    static func combineValidations(_ validations: [ValidationResult]) -> ValidationResult {
        for validation in validations {
            if !validation.isValid {
                return validation
            }
        }
        return .success
    }
    
    // MARK: - Model-Specific Validation Helpers
    
    static func validateWorkoutDuration(_ duration: TimeInterval?, fieldName: String = "Workout Duration") -> ValidationResult {
        return combineValidations([
            validatePositive(duration, fieldName: fieldName),
            validateRange(duration, min: 60, max: 28800, fieldName: fieldName) // 1 minute to 8 hours
        ])
    }
    
    static func validateWeight(_ weight: Double?, fieldName: String = "Weight") -> ValidationResult {
        return combineValidations([
            validatePositive(weight, fieldName: fieldName),
            validateRange(weight, min: 20.0, max: 300.0, fieldName: fieldName) // 20kg to 300kg
        ])
    }
    
    static func validateFTP(_ ftp: Int?, fieldName: String = "FTP") -> ValidationResult {
        guard let ftp = ftp else {
            return .failure("\(fieldName) is required")
        }
        return validateRange(ftp, min: 50, max: 600, fieldName: fieldName) // 50W to 600W
    }
    
    static func validateHeartRate(_ heartRate: Int?, fieldName: String = "Heart Rate") -> ValidationResult {
        guard let heartRate = heartRate else {
            return .failure("\(fieldName) is required")
        }
        return validateRange(heartRate, min: 40, max: 220, fieldName: fieldName) // 40 to 220 bpm
    }
    
    static func validateRepetitions(_ reps: Int?, fieldName: String = "Repetitions") -> ValidationResult {
        guard let reps = reps else {
            return .failure("\(fieldName) is required")
        }
        return validateRange(reps, min: 1, max: 1000, fieldName: fieldName) // 1 to 1000 reps
    }
    
    static func validateSets(_ sets: Int?, fieldName: String = "Sets") -> ValidationResult {
        guard let sets = sets else {
            return .failure("\(fieldName) is required")
        }
        return validateRange(sets, min: 1, max: 20, fieldName: fieldName) // 1 to 20 sets
    }
}

// MARK: - Model Extensions for Validation

extension WorkoutRecord: Validatable {
    func validate() -> ValidationResult {
        return ValidationEngine.combineValidations([
            ValidationEngine.validateRequired(summary.isEmpty ? nil : summary, fieldName: "Summary"),
            ValidationEngine.validateDate(date, before: Date().addingTimeInterval(86400), fieldName: "Date") // Can't be in future (with 1 day buffer)
        ])
    }
}

extension DailyMetric: Validatable {
    func validate() -> ValidationResult {
        var validations: [ValidationResult] = []
        
        // Validate weight if present
        if let weight = weightKg {
            validations.append(ValidationEngine.validateWeight(weight))
        }
        
        // Validate date
        validations.append(ValidationEngine.validateDate(
            date,
            before: Date().addingTimeInterval(86400),
            fieldName: "Date"
        ))
        
        // Ensure at least some data is present
        if !hasAnyData {
            validations.append(.failure("At least one metric value is required"))
        }
        
        return ValidationEngine.combineValidations(validations)
    }
}

extension FTPHistory: Validatable {
    func validate() -> ValidationResult {
        return ValidationEngine.combineValidations([
            ValidationEngine.validateFTP(ftpValue, fieldName: "FTP Value"),
            ValidationEngine.validateDate(
                date,
                before: Date().addingTimeInterval(86400),
                fieldName: "Date"
            )
        ])
    }
}

extension DailyTask: Validatable {
    func validate() -> ValidationResult {
        return ValidationEngine.combineValidations([
            ValidationEngine.validateRequired(title.isEmpty ? nil : title, fieldName: "Title"),
            ValidationEngine.validateMinLength(title, minLength: 2, fieldName: "Title"),
            ValidationEngine.validateMaxLength(title, maxLength: 100, fieldName: "Title")
        ])
    }
}

extension WeeklyTemplate: Validatable {
    func validate() -> ValidationResult {
        var validations: [ValidationResult] = []
        
        // Validate template name
        validations.append(ValidationEngine.validateRequired(name.isEmpty ? nil : name, fieldName: "Template Name"))
        validations.append(ValidationEngine.validateMinLength(name, minLength: 2, fieldName: "Template Name"))
        validations.append(ValidationEngine.validateMaxLength(name, maxLength: 50, fieldName: "Template Name"))
        
        // Validate that template has at least one task
        if dailyTasks.isEmpty {
            validations.append(.failure("Template must have at least one task"))
        }
        
        // Validate all daily tasks
        validations.append(ValidationEngine.validateBatch(dailyTasks))
        
        return ValidationEngine.combineValidations(validations)
    }
}

extension UserProfile: Validatable {
    func validate() -> ValidationResult {
        return ValidationEngine.combineValidations([
            ValidationEngine.validateWeight(goalWeightKg, fieldName: "Goal Weight")
        ])
    }
}

// MARK: - Workout Detail Extensions

extension StrengthDetail: Validatable {
    func validate() -> ValidationResult {
        var validations: [ValidationResult] = []
        
        validations.append(ValidationEngine.validatePositive(weight, fieldName: "Weight"))
        validations.append(ValidationEngine.validateRepetitions(reps))
        validations.append(ValidationEngine.validateSets(sets))
        
        return ValidationEngine.combineValidations(validations)
    }
}

extension CyclingDetail: Validatable {
    func validate() -> ValidationResult {
        var validations: [ValidationResult] = []
        
        validations.append(ValidationEngine.validatePositive(distance, fieldName: "Distance"))
        validations.append(ValidationEngine.validatePositive(Double(duration), fieldName: "Duration"))
        
        if let avgHR = averageHeartRate {
            validations.append(ValidationEngine.validateHeartRate(avgHR, fieldName: "Average Heart Rate"))
        }
        
        if let maxHR = maxHeartRate {
            validations.append(ValidationEngine.validateHeartRate(maxHR, fieldName: "Max Heart Rate"))
        }
        
        return ValidationEngine.combineValidations(validations)
    }
}

extension YogaDetail: Validatable {
    func validate() -> ValidationResult {
        var validations: [ValidationResult] = []
        
        validations.append(ValidationEngine.validateRange(Double(duration), min: 1, max: 180, fieldName: "Duration"))
        
        if let flexibility = flexibility {
            validations.append(ValidationEngine.validateRange(flexibility, min: 0, max: 10, fieldName: "Flexibility"))
        }
        
        if let balance = balance {
            validations.append(ValidationEngine.validateRange(balance, min: 0, max: 10, fieldName: "Balance"))
        }
        
        if let mindfulness = mindfulness {
            validations.append(ValidationEngine.validateRange(mindfulness, min: 0, max: 10, fieldName: "Mindfulness"))
        }
        
        return ValidationEngine.combineValidations(validations)
    }
}

extension FlexibilityDetail: Validatable {
    func validate() -> ValidationResult {
        var validations: [ValidationResult] = []
        
        validations.append(ValidationEngine.validateRange(Double(duration), min: 1, max: 300, fieldName: "Duration"))
        validations.append(ValidationEngine.validateRange(forwardBendDistance, min: -50, max: 50, fieldName: "Forward Bend Distance"))
        
        return ValidationEngine.combineValidations(validations)
    }
}

extension PilatesDetail: Validatable {
    func validate() -> ValidationResult {
        var validations: [ValidationResult] = []
        
        validations.append(ValidationEngine.validateRange(Double(duration), min: 1, max: 180, fieldName: "Duration"))
        
        if let reps = repetitions {
            validations.append(ValidationEngine.validateRepetitions(reps))
        }
        
        return ValidationEngine.combineValidations(validations)
    }
}