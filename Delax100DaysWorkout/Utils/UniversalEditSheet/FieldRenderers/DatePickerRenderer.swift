import SwiftUI

// MARK: - Date Picker Renderer

struct DatePickerRenderer {
    
    @ViewBuilder
    static func createDatePicker(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        let dateBinding = Binding(
            get: { value.wrappedValue as? Date ?? Date() },
            set: { value.wrappedValue = $0 }
        )
        
        VStack(alignment: .leading, spacing: Spacing.sm.value) {
            DatePicker(
                "",
                selection: dateBinding,
                displayedComponents: getDateComponents(for: field.name)
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .disabled(!isEditing)
            
            // Optional date range indicator
            if let rangeText = getDateRangeText(for: field.name) {
                Text(rangeText)
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
            }
        }
    }
    
    @ViewBuilder
    static func createInlineDatePicker(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        DatePicker(
            "",
            selection: Binding(
                get: { value.wrappedValue as? Date ?? Date() },
                set: { value.wrappedValue = $0 }
            ),
            displayedComponents: getDateComponents(for: field.name)
        )
        .labelsHidden()
        .datePickerStyle(.graphical)
        .disabled(!isEditing)
    }
    
    @ViewBuilder
    static func createWheelDatePicker(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        DatePicker(
            "",
            selection: Binding(
                get: { value.wrappedValue as? Date ?? Date() },
                set: { value.wrappedValue = $0 }
            ),
            displayedComponents: getDateComponents(for: field.name)
        )
        .labelsHidden()
        .datePickerStyle(.wheel)
        .disabled(!isEditing)
    }
    
    // MARK: - Validation
    
    static func validateDate(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        guard let dateValue = value as? Date else {
            return field.isRequired ? .failure("日付が必要です") : .success
        }
        
        // Field-specific date validation
        switch field.name.lowercased() {
        case "date", "recorddate":
            // Record dates shouldn't be in the future
            if dateValue > Date() {
                return .failure("記録日は現在より前の日付である必要があります")
            }
            
        case "birthdate", "birthday":
            // Birth dates should be reasonable
            let hundredYearsAgo = Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date.distantPast
            if dateValue < hundredYearsAgo {
                return .failure("生年月日が正しくありません")
            }
            if dateValue > Date() {
                return .failure("生年月日は現在より前の日付である必要があります")
            }
            
        case "targetdate", "deadline":
            // Target dates can be in the future
            let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date.distantFuture
            if dateValue > oneYearFromNow {
                return .warning("目標日が1年以上先に設定されています")
            }
            
        default:
            break
        }
        
        return .success
    }
    
    // MARK: - Helper Methods
    
    private static func getDateComponents(for fieldName: String) -> DatePickerComponents {
        switch fieldName.lowercased() {
        case "date", "recorddate", "targetdate":
            return [.date, .hourAndMinute]
        case "birthdate", "birthday":
            return [.date]
        case "time", "starttime", "endtime":
            return [.hourAndMinute]
        default:
            return [.date, .hourAndMinute]
        }
    }
    
    private static func getDateRangeText(for fieldName: String) -> String? {
        switch fieldName.lowercased() {
        case "date", "recorddate":
            return "記録は現在時刻より前で入力してください"
        case "birthdate":
            return "生年月日を入力してください"
        case "targetdate":
            return "目標達成予定日"
        default:
            return nil
        }
    }
    
    static func getDatePickerStyle(for fieldName: String) -> DatePickerStyle {
        switch fieldName.lowercased() {
        case "birthdate", "birthday":
            return .wheel // More precise for birth dates
        case "targetdate", "deadline":
            return .graphical // Visual calendar for planning
        default:
            return .compact // Compact for general use
        }
    }
}