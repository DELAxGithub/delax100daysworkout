import SwiftUI
import SwiftData

struct FormFieldFactory {
    
    @ViewBuilder
    static func createField(
        for property: PropertyAnalyzer.PropertyInfo,
        value: Binding<Any?>,
        isEditing: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(property.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if property.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            
            Group {
                switch property.formFieldType {
                case .textField:
                    createTextField(value: value, isEditing: isEditing)
                case .numberField:
                    createNumberField(for: property.type, value: value, isEditing: isEditing)
                case .toggle:
                    createToggle(value: value, isEditing: isEditing)
                case .datePicker:
                    createDatePicker(value: value, isEditing: isEditing)
                case .picker:
                    createPicker(for: property.type, value: value, isEditing: isEditing)
                case .relationshipPicker:
                    createRelationshipPicker(value: value, isEditing: isEditing)
                }
            }
            .disabled(!isEditing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private static func createTextField(value: Binding<Any?>, isEditing: Bool) -> some View {
        TextField("Enter text", text: Binding(
            get: { (value.wrappedValue as? String) ?? "" },
            set: { value.wrappedValue = $0.isEmpty ? nil : $0 }
        ))
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .disabled(!isEditing)
    }
    
    @ViewBuilder
    private static func createNumberField(
        for type: PropertyAnalyzer.PropertyType,
        value: Binding<Any?>,
        isEditing: Bool
    ) -> some View {
        HStack {
            TextField("0", text: Binding(
                get: {
                    switch type {
                    case .int:
                        return String(value.wrappedValue as? Int ?? 0)
                    case .double:
                        return String(format: "%.2f", value.wrappedValue as? Double ?? 0.0)
                    default:
                        return "0"
                    }
                },
                set: { newValue in
                    switch type {
                    case .int:
                        value.wrappedValue = Int(newValue) ?? 0
                    case .double:
                        value.wrappedValue = Double(newValue) ?? 0.0
                    default:
                        break
                    }
                }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if case .double = type {
                Stepper("", value: Binding(
                    get: { value.wrappedValue as? Double ?? 0.0 },
                    set: { value.wrappedValue = $0 }
                ), step: 0.1)
                .labelsHidden()
            } else if case .int = type {
                Stepper("", value: Binding(
                    get: { value.wrappedValue as? Int ?? 0 },
                    set: { value.wrappedValue = $0 }
                ))
                .labelsHidden()
            }
        }
        .disabled(!isEditing)
    }
    
    @ViewBuilder
    private static func createToggle(value: Binding<Any?>, isEditing: Bool) -> some View {
        Toggle("", isOn: Binding(
            get: { value.wrappedValue as? Bool ?? false },
            set: { value.wrappedValue = $0 }
        ))
        .labelsHidden()
        .disabled(!isEditing)
    }
    
    @ViewBuilder
    private static func createDatePicker(value: Binding<Any?>, isEditing: Bool) -> some View {
        DatePicker(
            "",
            selection: Binding(
                get: { value.wrappedValue as? Date ?? Date() },
                set: { value.wrappedValue = $0 }
            ),
            displayedComponents: [.date, .hourAndMinute]
        )
        .labelsHidden()
        .disabled(!isEditing)
    }
    
    @ViewBuilder
    private static func createPicker(
        for type: PropertyAnalyzer.PropertyType,
        value: Binding<Any?>,
        isEditing: Bool
    ) -> some View {
        if case .enumeration(let enumTypeName) = type {
            Text("Enum picker for: \(enumTypeName)")
                .foregroundColor(.secondary)
        } else {
            Text("Unknown picker type")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private static func createRelationshipPicker(value: Binding<Any?>, isEditing: Bool) -> some View {
        Button(action: {
            // TODO: Implement relationship picker
        }) {
            HStack {
                Text("Select related item")
                    .foregroundColor(.blue)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .disabled(!isEditing)
    }
}

extension FormFieldFactory {
    static func validateField(
        property: PropertyAnalyzer.PropertyInfo,
        value: Any?
    ) -> FieldValidationEngine.ValidationResult {
        for rule in property.validationRules {
            let result = rule.validate(value)
            if !result.isValid {
                return result
            }
        }
        return FieldValidationEngine.ValidationResult.success
    }
    
    static func createValidationMessage(for result: FieldValidationEngine.ValidationResult) -> some View {
        Group {
            if !result.isValid, let message = result.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}