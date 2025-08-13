import SwiftUI

// MARK: - Toggle Renderer

struct ToggleRenderer {
    
    @ViewBuilder
    static func createToggle(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { value.wrappedValue as? Bool ?? false },
                set: { value.wrappedValue = $0 }
            ))
            .labelsHidden()
            .disabled(!isEditing)
            
            Spacer()
            
            // Optional status text
            if let statusText = getToggleStatusText(field.name, isOn: value.wrappedValue as? Bool ?? false) {
                Text(statusText)
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
            }
        }
    }
    
    @ViewBuilder
    static func createSwitchWithIcon(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool,
        icon: String,
        color: Color = .blue
    ) -> some View {
        HStack(spacing: Spacing.md.value) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                Text(field.displayName)
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.primaryText.color)
                
                if let description = getFieldDescription(field.name) {
                    Text(description)
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { value.wrappedValue as? Bool ?? false },
                set: { value.wrappedValue = $0 }
            ))
            .labelsHidden()
            .disabled(!isEditing)
        }
    }
    
    // MARK: - Helper Methods
    
    private static func getToggleStatusText(_ fieldName: String, isOn: Bool) -> String? {
        switch fieldName.lowercased() {
        case "iscompleted":
            return isOn ? "完了" : "未完了"
        case "isenabled", "enabled":
            return isOn ? "有効" : "無効"
        case "ispublic", "public":
            return isOn ? "公開" : "非公開"
        case "isactive", "active":
            return isOn ? "アクティブ" : "非アクティブ"
        case "notifications":
            return isOn ? "通知ON" : "通知OFF"
        default:
            return nil
        }
    }
    
    private static func getFieldDescription(_ fieldName: String) -> String? {
        switch fieldName.lowercased() {
        case "iscompleted":
            return "タスクが完了済みかどうか"
        case "notifications":
            return "プッシュ通知を受け取る"
        case "ispublic":
            return "他のユーザーに公開する"
        default:
            return nil
        }
    }
    
    static func validateToggle(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        // Toggles typically don't need validation as they always have a boolean value
        return .success
    }
}