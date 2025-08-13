import SwiftUI

// MARK: - Text Field Renderer

struct TextFieldRenderer {
    
    @ViewBuilder
    static func createTextField(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        let textBinding = Binding(
            get: { (value.wrappedValue as? String) ?? "" },
            set: { newValue in
                value.wrappedValue = newValue.isEmpty && field.isOptional ? NSNull() : newValue
            }
        )
        
        if field.metadata.multiline {
            TextField(
                field.metadata.placeholder ?? "入力してください",
                text: textBinding,
                axis: .vertical
            )
            .lineLimit(3...6)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        } else if field.metadata.isSecure {
            SecureField(
                field.metadata.placeholder ?? "パスワードを入力",
                text: textBinding
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
        } else {
            TextField(
                field.metadata.placeholder ?? "入力してください",
                text: textBinding
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    static func validateText(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        guard let stringValue = value as? String else {
            return field.isRequired ? .failure("テキストが必要です") : .success
        }
        
        let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if field.isRequired && trimmed.isEmpty {
            return .failure("\(field.displayName)は必須項目です")
        }
        
        if let maxLength = field.metadata.characterLimit, trimmed.count > maxLength {
            return .failure("最大\(maxLength)文字以内で入力してください")
        }
        
        // Field-specific validation
        switch field.name.lowercased() {
        case "email":
            return validateEmail(trimmed)
        case "phone":
            return validatePhone(trimmed)
        case "url":
            return validateURL(trimmed)
        default:
            return .success
        }
    }
    
    private static func validateEmail(_ email: String) -> FieldValidationEngine.ValidationResult {
        let emailRegex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return predicate.evaluate(with: email) ? 
            .success : .failure("有効なメールアドレスを入力してください")
    }
    
    private static func validatePhone(_ phone: String) -> FieldValidationEngine.ValidationResult {
        let phoneRegex = "^[0-9+\\-\\s\\(\\)]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        return predicate.evaluate(with: phone) ? 
            .success : .failure("有効な電話番号を入力してください")
    }
    
    private static func validateURL(_ url: String) -> FieldValidationEngine.ValidationResult {
        return URL(string: url) != nil ? 
            .success : .failure("有効なURLを入力してください")
    }
}