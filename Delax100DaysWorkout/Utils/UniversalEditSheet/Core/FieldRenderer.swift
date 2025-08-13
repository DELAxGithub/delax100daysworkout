import SwiftUI

// MARK: - Field Renderer Coordinator (Simplified)

struct FieldRenderer {
    
    // MARK: - Main Entry Point
    
    @ViewBuilder
    static func createField(
        for field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs.value) {
            // Field Label with unified styling
            FieldLabelView(field: field)
            
            // Delegate to specific renderer
            Group {
                switch field.type.rendererType {
                case .textField:
                    TextFieldRenderer.createTextField(field: field, value: value, isEditing: isEditing)
                case .numberField:
                    NumberFieldRenderer.createNumberField(field: field, value: value, isEditing: isEditing)
                case .toggle:
                    ToggleRenderer.createToggle(field: field, value: value, isEditing: isEditing)
                case .datePicker:
                    DatePickerRenderer.createDatePicker(field: field, value: value, isEditing: isEditing)
                case .enumPicker:
                    EnumFieldRenderer.createEnumPicker(field: field, value: value, isEditing: isEditing)
                case .relationshipPicker:
                    RelationshipRenderer.createRelationshipPicker(field: field, value: value, isEditing: isEditing)
                case .arrayField:
                    ArrayRenderer.createArrayField(field: field, value: value, isEditing: isEditing)
                }
            }
            .disabled(!isEditing)
        }
    }
    
    // MARK: - Validation Coordinator
    
    static func validateField(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        switch field.type.rendererType {
        case .textField:
            return TextFieldRenderer.validateText(value, for: field)
        case .numberField:
            return NumberFieldRenderer.validateNumber(value, for: field)
        case .enumPicker:
            return EnumFieldRenderer.validateEnum(value, for: field)
        case .datePicker:
            return DatePickerRenderer.validateDate(value, for: field)
        default:
            return .success
        }
    }
    
    // MARK: - Helper Methods
    
    static func isEmpty(_ value: Any, for fieldType: FieldTypeDetector.FieldType) -> Bool {
        switch fieldType {
        case .string:
            return (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        case .int:
            return (value as? Int) == nil
        case .double:
            return (value as? Double) == nil
        case .bool:
            return false // Bool always has a value
        case .date:
            return (value as? Date) == nil
        case .enumeration:
            return (value as? String)?.isEmpty ?? true
        case .relationship, .array:
            return value is NSNull
        case .optional(let wrapped):
            return value is NSNull || isEmpty(value, for: wrapped)
        case .unknown:
            return value is NSNull
        }
    }
}

// MARK: - Unified Field Label Component

private struct FieldLabelView: View {
    let field: FieldTypeDetector.FieldInfo
    
    var body: some View {
        HStack {
            Text(field.displayName)
                .font(Typography.bodyLarge.font)
                .foregroundColor(SemanticColor.primaryText.color)
            
            if field.isRequired {
                Text("*")
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.errorAction.color)
            }
            
            Spacer()
            
            if let unit = field.metadata.unit {
                Text(unit)
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
            }
        }
    }
}