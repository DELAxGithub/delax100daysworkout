import SwiftUI

// MARK: - Enum Field Renderer

struct EnumFieldRenderer {
    
    @ViewBuilder
    static func createEnumPicker(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        if case .enumeration(let type, let cases) = field.type {
            if cases.count <= 4 && !cases.isEmpty {
                segmentedPicker(cases: cases, value: value, isEditing: isEditing)
            } else {
                menuPicker(cases: cases, value: value, isEditing: isEditing, field: field)
            }
        } else {
            Text("Enumeration configuration error")
                .foregroundColor(SemanticColor.errorAction.color)
        }
    }
    
    @ViewBuilder
    private static func segmentedPicker(
        cases: [String],
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        Picker("", selection: Binding(
            get: { 
                let currentValue = String(describing: value.wrappedValue)
                return cases.contains(currentValue) ? currentValue : (cases.first ?? "")
            },
            set: { newValue in
                value.wrappedValue = newValue
            }
        )) {
            ForEach(cases, id: \.self) { enumCase in
                Text(formatEnumCaseDisplay(enumCase))
                    .tag(enumCase)
            }
        }
        .pickerStyle(.segmented)
        .disabled(!isEditing)
    }
    
    @ViewBuilder
    private static func menuPicker(
        cases: [String],
        value: Binding<Any>,
        isEditing: Bool,
        field: FieldTypeDetector.FieldInfo
    ) -> some View {
        Menu {
            ForEach(cases, id: \.self) { enumCase in
                Button(formatEnumCaseDisplay(enumCase)) {
                    if isEditing {
                        value.wrappedValue = enumCase
                    }
                }
            }
        } label: {
            HStack {
                Text(getCurrentDisplayValue(value.wrappedValue, cases: cases))
                    .foregroundColor(isEditing ? SemanticColor.primaryText.color : SemanticColor.secondaryText.color)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(SemanticColor.secondaryText.color)
                    .font(.caption)
            }
            .padding(.vertical, Spacing.sm.value)
            .padding(.horizontal, Spacing.md.value)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium.value)
                    .fill(SemanticColor.surfaceBackground.color)
                    .stroke(SemanticColor.primaryBorder.color, lineWidth: 1)
            )
        }
        .disabled(!isEditing)
    }
    
    // MARK: - Special Enum Renderers
    
    @ViewBuilder
    static func createWorkoutTypePicker(
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        if let workoutType = value.wrappedValue as? WorkoutType {
            Picker("種目", selection: Binding(
                get: { workoutType },
                set: { newValue in
                    value.wrappedValue = newValue
                }
            )) {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.iconName)
                            .foregroundColor(type.iconColor)
                        Text(type.rawValue)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!isEditing)
        } else {
            // Fallback for non-WorkoutType enums
            Text("Invalid workout type")
                .foregroundColor(SemanticColor.errorAction.color)
        }
    }
    
    // MARK: - Validation
    
    static func validateEnum(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        if case .enumeration(_, let cases) = field.type {
            let stringValue = String(describing: value)
            
            if field.isRequired && (value is NSNull || stringValue.isEmpty) {
                return .failure("\(field.displayName)を選択してください")
            }
            
            if !stringValue.isEmpty && !cases.contains(stringValue) {
                return .failure("無効な選択です")
            }
            
            return .success
        }
        
        return .success
    }
    
    // MARK: - Helper Methods
    
    private static func formatEnumCaseDisplay(_ enumCase: String) -> String {
        // Convert camelCase to display format
        return enumCase
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
    
    private static func getCurrentDisplayValue(_ value: Any, cases: [String]) -> String {
        let stringValue = String(describing: value)
        
        if stringValue == "NSNull()" || stringValue.isEmpty {
            return "選択してください"
        }
        
        return cases.contains(stringValue) ? formatEnumCaseDisplay(stringValue) : "未選択"
    }
    
    // MARK: - Enum Type Detection
    
    static func isWorkoutTypeEnum(_ field: FieldTypeDetector.FieldInfo) -> Bool {
        if case .enumeration(let type, _) = field.type {
            return type.contains("WorkoutType")
        }
        return false
    }
    
    static func isDifficultyEnum(_ field: FieldTypeDetector.FieldInfo) -> Bool {
        if case .enumeration(let type, _) = field.type {
            return type.contains("Difficulty") || type.contains("Intensity")
        }
        return false
    }
    
    static func getPriorityOrder(for enumType: String) -> [String] {
        switch enumType {
        case let type where type.contains("Priority"):
            return ["high", "medium", "low"]
        case let type where type.contains("Difficulty"):
            return ["beginner", "intermediate", "advanced", "expert"]
        case let type where type.contains("WorkoutType"):
            return ["cycling", "strength", "flexibility", "pilates", "yoga"]
        default:
            return []
        }
    }
}