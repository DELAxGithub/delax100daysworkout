import SwiftUI

// MARK: - Number Field Renderer

struct NumberFieldRenderer {
    
    @ViewBuilder
    static func createNumberField(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        HStack(spacing: Spacing.sm.value) {
            switch field.type {
            case .int, .optional(.int):
                integerField(field: field, value: value)
            case .double, .optional(.double):
                decimalField(field: field, value: value)
            default:
                integerField(field: field, value: value)
            }
            
            if isEditing {
                VStack(spacing: 2) {
                    stepperButtons(field: field, value: value)
                }
            }
        }
    }
    
    @ViewBuilder
    private static func integerField(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>
    ) -> some View {
        TextField(
            field.metadata.placeholder ?? "0",
            text: Binding(
                get: {
                    if let intValue = value.wrappedValue as? Int {
                        return String(intValue)
                    }
                    return "0"
                },
                set: { newValue in
                    if let intValue = Int(newValue) {
                        // Apply min/max constraints
                        let constrainedValue = constrainInteger(
                            intValue, 
                            min: field.metadata.minValue,
                            max: field.metadata.maxValue
                        )
                        value.wrappedValue = constrainedValue
                    } else if field.isOptional && newValue.isEmpty {
                        value.wrappedValue = NSNull()
                    }
                }
            )
        )
        .keyboardType(.numberPad)
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    @ViewBuilder
    private static func decimalField(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>
    ) -> some View {
        TextField(
            field.metadata.placeholder ?? "0.0",
            text: Binding(
                get: {
                    if let doubleValue = value.wrappedValue as? Double {
                        return String(format: "%.2f", doubleValue)
                    }
                    return "0.0"
                },
                set: { newValue in
                    if let doubleValue = Double(newValue) {
                        // Apply min/max constraints
                        let constrainedValue = constrainDouble(
                            doubleValue,
                            min: field.metadata.minValue,
                            max: field.metadata.maxValue
                        )
                        value.wrappedValue = constrainedValue
                    } else if field.isOptional && newValue.isEmpty {
                        value.wrappedValue = NSNull()
                    }
                }
            )
        )
        .keyboardType(.decimalPad)
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    @ViewBuilder
    private static func stepperButtons(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>
    ) -> some View {
        switch field.type {
        case .int, .optional(.int):
            Stepper("", value: Binding(
                get: { value.wrappedValue as? Int ?? 0 },
                set: { newValue in
                    let constrainedValue = constrainInteger(
                        newValue,
                        min: field.metadata.minValue,
                        max: field.metadata.maxValue
                    )
                    value.wrappedValue = constrainedValue
                }
            ), step: 1)
            .labelsHidden()
            
        case .double, .optional(.double):
            Stepper("", value: Binding(
                get: { value.wrappedValue as? Double ?? 0.0 },
                set: { newValue in
                    let constrainedValue = constrainDouble(
                        newValue,
                        min: field.metadata.minValue,
                        max: field.metadata.maxValue
                    )
                    value.wrappedValue = constrainedValue
                }
            ), step: 0.1)
            .labelsHidden()
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Validation
    
    static func validateNumber(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        switch field.type {
        case .int, .optional(.int):
            return validateInteger(value, for: field)
        case .double, .optional(.double):
            return validateDouble(value, for: field)
        default:
            return .success
        }
    }
    
    private static func validateInteger(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        guard let intValue = value as? Int else {
            return field.isRequired ? .failure("数値が必要です") : .success
        }
        
        if let minValue = field.metadata.minValue, Double(intValue) < minValue {
            return .failure("値は\(Int(minValue))以上である必要があります")
        }
        
        if let maxValue = field.metadata.maxValue, Double(intValue) > maxValue {
            return .failure("値は\(Int(maxValue))以下である必要があります")
        }
        
        return .success
    }
    
    private static func validateDouble(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        guard let doubleValue = value as? Double else {
            return field.isRequired ? .failure("数値が必要です") : .success
        }
        
        if let minValue = field.metadata.minValue, doubleValue < minValue {
            return .failure("値は\(minValue)以上である必要があります")
        }
        
        if let maxValue = field.metadata.maxValue, doubleValue > maxValue {
            return .failure("値は\(maxValue)以下である必要があります")
        }
        
        return .success
    }
    
    // MARK: - Helper Methods
    
    private static func constrainInteger(_ value: Int, min: Double?, max: Double?) -> Int {
        var result = value
        
        if let minValue = min {
            result = Swift.max(result, Int(minValue))
        }
        
        if let maxValue = max {
            result = Swift.min(result, Int(maxValue))
        }
        
        return result
    }
    
    private static func constrainDouble(_ value: Double, min: Double?, max: Double?) -> Double {
        var result = value
        
        if let minValue = min {
            result = Swift.max(result, minValue)
        }
        
        if let maxValue = max {
            result = Swift.min(result, maxValue)
        }
        
        return result
    }
}