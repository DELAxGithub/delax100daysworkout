import Foundation
import SwiftUI

// MARK: - Field Validation Engine

struct FieldValidationEngine {
    
    // MARK: - Validation Result
    
    struct ValidationResult {
        let isValid: Bool
        let errorMessage: String?
        let severity: ValidationSeverity
        
        static let success = ValidationResult(isValid: true, errorMessage: nil, severity: .none)
        
        static func failure(_ message: String, severity: ValidationSeverity = .error) -> ValidationResult {
            return ValidationResult(isValid: false, errorMessage: message, severity: severity)
        }
        
        static func warning(_ message: String) -> ValidationResult {
            return ValidationResult(isValid: true, errorMessage: message, severity: .warning)
        }
    }
    
    enum ValidationSeverity {
        case none
        case warning
        case error
        case critical
        
        var color: Color {
            switch self {
            case .none:
                return .clear
            case .warning:
                return .orange
            case .error:
                return .red
            case .critical:
                return .purple
            }
        }
    }
    
    // MARK: - Validation Rules
    
    enum ValidationRule {
        case required
        case minLength(Int)
        case maxLength(Int)
        case numberRange(min: Double, max: Double)
        case dateRange(earliest: Date?, latest: Date?)
        case pattern(regex: String, message: String)
        case custom((Any) -> ValidationResult)
        
        func validate(_ value: Any, field: FieldTypeDetector.FieldInfo) -> ValidationResult {
            switch self {
            case .required:
                return validateRequired(value, field: field)
                
            case .minLength(let min):
                return validateMinLength(value, min: min)
                
            case .maxLength(let max):
                return validateMaxLength(value, max: max)
                
            case .numberRange(let min, let max):
                return validateNumberRange(value, min: min, max: max)
                
            case .dateRange(let earliest, let latest):
                return validateDateRange(value, earliest: earliest, latest: latest)
                
            case .pattern(let regex, let message):
                return validatePattern(value, regex: regex, message: message)
                
            case .custom(let validator):
                return validator(value)
            }
        }
        
        // MARK: - Individual Validation Methods
        
        private func validateRequired(_ value: Any, field: FieldTypeDetector.FieldInfo) -> ValidationResult {
            if value is NSNull {
                return .failure("\(field.displayName)は必須項目です")
            }
            
            if let stringValue = value as? String {
                return stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    .failure("\(field.displayName)を入力してください") : .success
            }
            
            return .success
        }
        
        private func validateMinLength(_ value: Any, min: Int) -> ValidationResult {
            guard let stringValue = value as? String else { return .success }
            return stringValue.count >= min ? .success : .failure("最低\(min)文字以上入力してください")
        }
        
        private func validateMaxLength(_ value: Any, max: Int) -> ValidationResult {
            guard let stringValue = value as? String else { return .success }
            return stringValue.count <= max ? .success : .failure("最大\(max)文字以内で入力してください")
        }
        
        private func validateNumberRange(_ value: Any, min: Double, max: Double) -> ValidationResult {
            var numberValue: Double?
            
            if let intValue = value as? Int {
                numberValue = Double(intValue)
            } else if let doubleValue = value as? Double {
                numberValue = doubleValue
            }
            
            guard let number = numberValue else { return .success }
            
            if number < min {
                return .failure("値は\(min)以上である必要があります")
            } else if number > max {
                return .failure("値は\(max)以下である必要があります")
            }
            
            return .success
        }
        
        private func validateDateRange(_ value: Any, earliest: Date?, latest: Date?) -> ValidationResult {
            guard let dateValue = value as? Date else { return .success }
            
            if let earliest = earliest, dateValue < earliest {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return .failure("日付は\(formatter.string(from: earliest))以降である必要があります")
            }
            
            if let latest = latest, dateValue > latest {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return .failure("日付は\(formatter.string(from: latest))以前である必要があります")
            }
            
            return .success
        }
        
        private func validatePattern(_ value: Any, regex: String, message: String) -> ValidationResult {
            guard let stringValue = value as? String else { return .success }
            
            do {
                let regex = try NSRegularExpression(pattern: regex)
                let range = NSRange(location: 0, length: stringValue.utf16.count)
                let matches = regex.matches(in: stringValue, range: range)
                
                return matches.isEmpty ? .failure(message) : .success
            } catch {
                return .failure("パターン検証中にエラーが発生しました")
            }
        }
    }
    
    // MARK: - Main Validation Method
    
    static func validate(
        value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> ValidationResult {
        let actualValue = value ?? NSNull()
        
        // Get validation rules for this field
        let rules = getValidationRules(for: field)
        
        // Apply each rule
        for rule in rules {
            let result = rule.validate(actualValue, field: field)
            if !result.isValid {
                return result
            }
        }
        
        // Apply business logic validation
        let businessResult = validateBusinessRules(actualValue, for: field)
        if !businessResult.isValid {
            return businessResult
        }
        
        return .success
    }
    
    // MARK: - Rule Generation
    
    private static func getValidationRules(for field: FieldTypeDetector.FieldInfo) -> [ValidationRule] {
        var rules: [ValidationRule] = []
        
        // Required field validation
        if field.isRequired {
            rules.append(.required)
        }
        
        // Type-specific validation
        switch field.type {
        case .string, .optional(.string):
            if let characterLimit = field.metadata.characterLimit {
                rules.append(.maxLength(characterLimit))
            }
            if field.name.lowercased().contains("email") {
                rules.append(.pattern(
                    regex: "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
                    message: "有効なメールアドレスを入力してください"
                ))
            }
            
        case .int, .double, .optional(.int), .optional(.double):
            if let minValue = field.metadata.minValue, let maxValue = field.metadata.maxValue {
                rules.append(.numberRange(min: minValue, max: maxValue))
            }
            
        case .date, .optional(.date):
            if field.name.lowercased() == "date" {
                rules.append(.dateRange(earliest: nil, latest: Date()))
            }
            
        default:
            break
        }
        
        // Field-specific custom rules
        rules.append(contentsOf: getCustomRulesForField(field))
        
        return rules
    }
    
    private static func getCustomRulesForField(_ field: FieldTypeDetector.FieldInfo) -> [ValidationRule] {
        switch field.name.lowercased() {
        case "summary", "title":
            return [
                .minLength(1),
                .custom { value in
                    guard let stringValue = value as? String else { return .success }
                    if stringValue.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
                        return .warning("より詳しい内容を入力することをお勧めします")
                    }
                    return .success
                }
            ]
            
        case "distance":
            return [
                .custom { value in
                    guard let distance = value as? Double else { return .success }
                    if distance > 500 {
                        return .warning("長距離のワークアウトです。正しい値か確認してください")
                    }
                    return .success
                }
            ]
            
        case "duration":
            return [
                .custom { value in
                    guard let duration = value as? Int else { return .success }
                    if duration > 480 { // 8 hours
                        return .warning("長時間のワークアウトです。正しい値か確認してください")
                    }
                    return .success
                }
            ]
            
        case "weight":
            return [
                .custom { value in
                    guard let weight = value as? Double else { return .success }
                    if weight > 500 {
                        return .failure("重量が現実的でない値です")
                    }
                    return .success
                }
            ]
            
        default:
            return []
        }
    }
    
    // MARK: - Business Logic Validation
    
    private static func validateBusinessRules(_ value: Any, for field: FieldTypeDetector.FieldInfo) -> ValidationResult {
        // Cross-field validation would go here in a real implementation
        // For now, this is a placeholder for business-specific rules
        
        switch field.name {
        case "workoutType":
            // Validate that workout type is supported
            if let stringValue = value as? String, !stringValue.isEmpty {
                let supportedTypes = ["Cycling", "Strength", "Flexibility", "Pilates", "Yoga"]
                if !supportedTypes.contains(stringValue) {
                    return .failure("サポートされていないワークアウト種目です")
                }
            }
            
        case "averagePower":
            // Validate realistic power values for cycling
            if let power = value as? Double, power > 0 {
                if power > 1500 {
                    return .warning("非常に高いパワー値です。プロレベルの値である可能性があります")
                } else if power < 50 {
                    return .warning("パワー値が低すぎる可能性があります")
                }
            }
            
        default:
            break
        }
        
        return .success
    }
    
    // MARK: - Batch Validation
    
    static func validateAll(
        fieldValues: [String: Any],
        fields: [FieldTypeDetector.FieldInfo]
    ) -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]
        
        for field in fields {
            let value = fieldValues[field.name]
            let result = validate(value: value, for: field)
            results[field.name] = result
        }
        
        return results
    }
    
    static func hasErrors(_ validationResults: [String: ValidationResult]) -> Bool {
        return validationResults.values.contains { !$0.isValid }
    }
    
    static func getErrorMessages(_ validationResults: [String: ValidationResult]) -> [String] {
        return validationResults.values.compactMap { result in
            result.isValid ? nil : result.errorMessage
        }
    }
    
    static func getWarningMessages(_ validationResults: [String: ValidationResult]) -> [String] {
        return validationResults.values.compactMap { result in
            result.severity == .warning ? result.errorMessage : nil
        }
    }
}