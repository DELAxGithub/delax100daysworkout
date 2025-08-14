import SwiftUI
import SwiftData
import Foundation

struct PropertyAnalyzer {
    
    indirect enum PropertyType: Hashable {
        case string
        case int
        case double
        case bool
        case date
        case enumeration(typeName: String)
        case relationship
        case optional(wrapped: PropertyType)
        case unknown
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .string:
                hasher.combine("string")
            case .int:
                hasher.combine("int")
            case .double:
                hasher.combine("double")
            case .bool:
                hasher.combine("bool")
            case .date:
                hasher.combine("date")
            case .enumeration(let typeName):
                hasher.combine("enum_\(typeName)")
            case .relationship:
                hasher.combine("relationship")
            case .optional(let wrapped):
                hasher.combine("optional")
                wrapped.hash(into: &hasher)
            case .unknown:
                hasher.combine("unknown")
            }
        }
        
        static func == (lhs: PropertyType, rhs: PropertyType) -> Bool {
            switch (lhs, rhs) {
            case (.string, .string), (.int, .int), (.double, .double), (.bool, .bool), (.date, .date), (.relationship, .relationship), (.unknown, .unknown):
                return true
            case (.enumeration(let lhsType), .enumeration(let rhsType)):
                return lhsType == rhsType
            case (.optional(let lhsWrapped), .optional(let rhsWrapped)):
                return lhsWrapped == rhsWrapped
            default:
                return false
            }
        }
    }
    
    struct PropertyInfo: Hashable {
        let name: String
        let type: PropertyType
        let isOptional: Bool
        let isRequired: Bool
        let displayName: String
        
        var formFieldType: FormFieldType {
            switch type {
            case .string:
                return .textField
            case .int, .double:
                return .numberField
            case .bool:
                return .toggle
            case .date:
                return .datePicker
            case .enumeration:
                return .picker
            case .optional(let wrapped):
                return PropertyInfo(name: name, type: wrapped, isOptional: true, isRequired: false, displayName: displayName).formFieldType
            case .relationship:
                return .relationshipPicker
            case .unknown:
                return .textField
            }
        }
    }
    
    enum FormFieldType {
        case textField
        case numberField
        case toggle
        case datePicker
        case picker
        case relationshipPicker
    }
    
    static func analyzeModel<T: PersistentModel>(_ modelType: T.Type) -> [PropertyInfo] {
        // SwiftDataのPersistentModelは直接init()できないため、基本的なプロパティ情報を返す
        var properties: [PropertyInfo] = []
        
        // 共通プロパティの基本セット
        properties.append(PropertyInfo(
            name: "id",
            type: .string,
            isOptional: false,
            isRequired: true,
            displayName: "ID"
        ))
        
        return properties.sorted { $0.name < $1.name }
    }
    
    private static func analyzeProperty<T: PersistentModel>(
        name: String,
        value: Any,
        modelType: T.Type
    ) -> PropertyInfo {
        let propertyType = type(of: value)
        let typeString = String(describing: propertyType)
        
        let isOptional = typeString.contains("Optional")
        let displayName = formatDisplayName(name)
        
        let baseType = extractBaseType(from: value, typeString: typeString)
        let isRequired = determineIfRequired(propertyName: name, modelType: modelType)
        
        return PropertyInfo(
            name: name,
            type: baseType,
            isOptional: isOptional,
            isRequired: isRequired,
            displayName: displayName
        )
    }
    
    private static func extractBaseType(from value: Any, typeString: String) -> PropertyType {
        if typeString.contains("String") {
            return .string
        } else if typeString.contains("Int") {
            return .int
        } else if typeString.contains("Double") {
            return .double
        } else if typeString.contains("Bool") {
            return .bool
        } else if typeString.contains("Date") {
            return .date
        } else if let enumType = value as? any CaseIterable {
            return .enumeration(typeName: String(describing: type(of: enumType)))
        } else if typeString.contains("Relationship") {
            return .relationship
        }
        
        return .unknown
    }
    
    private static func formatDisplayName(_ propertyName: String) -> String {
        let formatted = propertyName
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
        
        return formatted
    }
    
    private static func determineIfRequired<T: PersistentModel>(
        propertyName: String,
        modelType: T.Type
    ) -> Bool {
        let requiredFields = ["id", "date", "title", "name"]
        return requiredFields.contains(propertyName.lowercased())
    }
}

extension PropertyAnalyzer.PropertyInfo {
    var validationRules: [ValidationRule] {
        var rules: [ValidationRule] = []
        
        if isRequired {
            rules.append(.required)
        }
        
        switch type {
        case .string:
            rules.append(.minLength(1))
            rules.append(.maxLength(500))
        case .int:
            rules.append(.numberRange(min: -999999, max: 999999))
        case .double:
            rules.append(.numberRange(min: -999999.99, max: 999999.99))
        case .date:
            rules.append(.dateRange(earliest: Date.distantPast, latest: Date.distantFuture))
        default:
            break
        }
        
        return rules
    }
}

enum ValidationRule {
    case required
    case minLength(Int)
    case maxLength(Int)
    case numberRange(min: Double, max: Double)
    case dateRange(earliest: Date, latest: Date)
    case custom((Any) -> ValidationResult)
    
    func validate(_ value: Any?) -> ValidationResult {
        switch self {
        case .required:
            if value == nil { return .failure("This field is required") }
            if let str = value as? String, str.isEmpty { return .failure("This field is required") }
            return .success
            
        case .minLength(let min):
            guard let str = value as? String else { return .success }
            return str.count >= min ? .success : .failure("Minimum length is \(min)")
            
        case .maxLength(let max):
            guard let str = value as? String else { return .success }
            return str.count <= max ? .success : .failure("Maximum length is \(max)")
            
        case .numberRange(let min, let max):
            if let num = value as? Double {
                return (num >= min && num <= max) ? .success : .failure("Value must be between \(min) and \(max)")
            }
            if let num = value as? Int {
                let doubleNum = Double(num)
                return (doubleNum >= min && doubleNum <= max) ? .success : .failure("Value must be between \(Int(min)) and \(Int(max))")
            }
            return .success
            
        case .dateRange(let earliest, let latest):
            guard let date = value as? Date else { return .success }
            return (date >= earliest && date <= latest) ? .success : .failure("Date must be between \(earliest) and \(latest)")
            
        case .custom(let validator):
            return validator(value)
        }
    }
}