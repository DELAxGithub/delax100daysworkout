import Foundation

// MARK: - Field Metadata Generator

struct FieldMetadataGenerator {
    
    // MARK: - Metadata Generation
    
    static func generateMetadata(for fieldName: String, fieldType: FieldTypeDetector.FieldType) -> FieldTypeDetector.FieldMetadata {
        switch fieldName.lowercased() {
        case "summary", "title", "name":
            return textFieldMetadata(placeholder: "入力してください", characterLimit: 100)
            
        case "description", "notes", "comment":
            return textFieldMetadata(placeholder: "詳細を入力してください", characterLimit: 500, multiline: true)
            
        case "email":
            return textFieldMetadata(placeholder: "例: user@example.com", characterLimit: 255)
            
        case "password":
            return textFieldMetadata(placeholder: "パスワードを入力", isSecure: true)
            
        case "distance":
            return numericFieldMetadata(placeholder: "0", unit: "km", minValue: 0, maxValue: 1000)
            
        case "duration":
            return numericFieldMetadata(placeholder: "0", unit: "分", minValue: 0, maxValue: 1440)
            
        case "weight":
            return numericFieldMetadata(placeholder: "0.0", unit: "kg", minValue: 0, maxValue: 1000)
            
        case "power", "averagepower":
            return numericFieldMetadata(placeholder: "0", unit: "W", minValue: 0, maxValue: 2000)
            
        case "speed", "averagespeed":
            return numericFieldMetadata(placeholder: "0.0", unit: "km/h", minValue: 0, maxValue: 100)
            
        case "heartrate", "averageheartrate", "maxheartrate":
            return numericFieldMetadata(placeholder: "0", unit: "bpm", minValue: 30, maxValue: 220)
            
        case "temperature":
            return numericFieldMetadata(placeholder: "20", unit: "°C", minValue: -40, maxValue: 50)
            
        case "humidity":
            return numericFieldMetadata(placeholder: "50", unit: "%", minValue: 0, maxValue: 100)
            
        case "altitude", "elevation":
            return numericFieldMetadata(placeholder: "0", unit: "m", minValue: -500, maxValue: 9000)
            
        case "age":
            return numericFieldMetadata(placeholder: "25", unit: "歳", minValue: 0, maxValue: 150)
            
        case "height":
            return numericFieldMetadata(placeholder: "170", unit: "cm", minValue: 50, maxValue: 250)
            
        case "bodyfat", "bodyfatpercentage":
            return numericFieldMetadata(placeholder: "15", unit: "%", minValue: 3, maxValue: 50)
            
        case "sets":
            return numericFieldMetadata(placeholder: "3", unit: "セット", minValue: 1, maxValue: 20)
            
        case "reps", "repetitions":
            return numericFieldMetadata(placeholder: "10", unit: "回", minValue: 1, maxValue: 100)
            
        case "calories":
            return numericFieldMetadata(placeholder: "0", unit: "kcal", minValue: 0, maxValue: 10000)
            
        case "ftp":
            return numericFieldMetadata(placeholder: "250", unit: "W", minValue: 50, maxValue: 600)
            
        default:
            return FieldTypeDetector.FieldMetadata()
        }
    }
    
    // MARK: - Helper Methods
    
    private static func textFieldMetadata(
        placeholder: String,
        characterLimit: Int? = nil,
        multiline: Bool = false,
        isSecure: Bool = false
    ) -> FieldTypeDetector.FieldMetadata {
        return FieldTypeDetector.FieldMetadata(
            placeholder: placeholder,
            characterLimit: characterLimit,
            multiline: multiline,
            isSecure: isSecure
        )
    }
    
    private static func numericFieldMetadata(
        placeholder: String,
        unit: String,
        minValue: Double,
        maxValue: Double
    ) -> FieldTypeDetector.FieldMetadata {
        return FieldTypeDetector.FieldMetadata(
            placeholder: placeholder,
            unit: unit,
            minValue: minValue,
            maxValue: maxValue
        )
    }
    
    // MARK: - Field Priority and Grouping
    
    static func getFieldPriority(_ fieldName: String) -> Int {
        let priorityOrder = [
            "summary": 1, "title": 1, "name": 1,
            "workoutType": 2, "type": 2, "category": 2,
            "date": 3,
            "isCompleted": 4,
            "duration": 10, "distance": 11, "weight": 12,
            "description": 20, "notes": 21, "comment": 22,
            "createdAt": 100, "updatedAt": 101
        ]
        
        return priorityOrder[fieldName.lowercased()] ?? 50
    }
    
    static func getFieldGroup(_ fieldName: String) -> String {
        switch fieldName.lowercased() {
        case "summary", "title", "name", "type", "workouttype", "category":
            return "基本情報"
        case "date", "startdate", "enddate", "targetdate":
            return "日時"
        case "duration", "distance", "weight", "power", "speed", "heartrate":
            return "測定値"
        case "description", "notes", "comment", "memo":
            return "メモ"
        case "iscompleted", "ispublic", "enabled", "active":
            return "設定"
        case "createdat", "updatedat", "version":
            return "システム"
        default:
            return "その他"
        }
    }
    
    static func shouldHideField(_ fieldName: String) -> Bool {
        let hiddenFields = [
            "persistentModelID",
            "_$backingData", 
            "_$observationRegistrar",
            "id" // Often auto-generated
        ]
        
        return hiddenFields.contains(fieldName) || 
               fieldName.hasPrefix("_") || 
               fieldName.hasPrefix("$")
    }
    
    // MARK: - Validation Rules
    
    static func getStandardValidationRules(for fieldName: String) -> [FieldValidationEngine.ValidationRule] {
        switch fieldName.lowercased() {
        case "email":
            return [.pattern(
                regex: "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
                message: "有効なメールアドレスを入力してください"
            )]
            
        case "phone", "phonenumber":
            return [.pattern(
                regex: "^[0-9+\\-\\s\\(\\)]+$",
                message: "有効な電話番号を入力してください"
            )]
            
        case "url", "website":
            return [.custom { value in
                guard let stringValue = value as? String, !stringValue.isEmpty else { return .success }
                return URL(string: stringValue) != nil ? .success : .failure("有効なURLを入力してください")
            }]
            
        case "summary", "title", "name":
            return [.minLength(1), .maxLength(100)]
            
        case "description", "notes":
            return [.maxLength(1000)]
            
        default:
            return []
        }
    }
}