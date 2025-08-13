import SwiftUI
import SwiftData
import Foundation
import OSLog

// MARK: - Field Type Detector (Coordinator)

struct FieldTypeDetector {
    private static let logger = Logger(subsystem: "Delax100DaysWorkout", category: "FieldTypeDetector")
    
    // MARK: - Main Analysis Method
    
    static func analyzeModel<T: PersistentModel>(_ model: T) -> [FieldInfo] {
        logger.info("Analyzing model: \(String(describing: type(of: model)))")
        
        let mirror = Mirror(reflecting: model)
        var fields: [FieldInfo] = []
        
        for child in mirror.children {
            guard let propertyName = child.label else { continue }
            
            // Skip system properties
            if FieldMetadataGenerator.shouldHideField(propertyName) {
                continue
            }
            
            let fieldInfo = analyzeProperty(
                name: propertyName,
                value: child.value,
                modelType: T.self
            )
            
            fields.append(fieldInfo)
        }
        
        // Sort fields by priority
        let sortedFields = fields.sorted { first, second in
            let firstPriority = FieldMetadataGenerator.getFieldPriority(first.name)
            let secondPriority = FieldMetadataGenerator.getFieldPriority(second.name)
            
            if firstPriority != secondPriority {
                return firstPriority < secondPriority
            }
            
            return first.displayName < second.displayName
        }
        
        logger.info("Analyzed \(sortedFields.count) fields for \(String(describing: T.self))")
        return sortedFields
    }
    
    // MARK: - Property Analysis
    
    private static func analyzeProperty<T: PersistentModel>(
        name: String,
        value: Any,
        modelType: T.Type
    ) -> FieldInfo {
        let propertyType = type(of: value)
        let typeString = String(describing: propertyType)
        
        logger.debug("Analyzing property: \(name) of type: \(typeString)")
        
        let fieldType = FieldTypeAnalysis.detectFieldType(from: value, typeString: typeString)
        let isOptional = typeString.contains("Optional") || typeString.contains("?")
        let isRequired = determineIfRequired(propertyName: name, modelType: modelType)
        let defaultValue = FieldTypeAnalysis.generateDefaultValue(for: fieldType, isOptional: isOptional)
        let metadata = FieldMetadataGenerator.generateMetadata(for: name, fieldType: fieldType)
        
        return FieldInfo(
            name: name,
            type: fieldType,
            isOptional: isOptional,
            isRequired: isRequired,
            defaultValue: defaultValue,
            metadata: metadata
        )
    }
    
    // MARK: - Required Field Determination
    
    private static func determineIfRequired<T: PersistentModel>(
        propertyName: String,
        modelType: T.Type
    ) -> Bool {
        let commonRequiredFields = [
            "date", "title", "name", "summary",
            "workoutType", "type", "category"
        ]
        
        return commonRequiredFields.contains(propertyName.lowercased()) ||
               !propertyName.contains("Optional") ||
               propertyName == "isCompleted" // Business logic requirement
    }
}

// MARK: - Field Information Structure

extension FieldTypeDetector {
    
    struct FieldInfo {
        let name: String
        let displayName: String
        let type: FieldType
        let isOptional: Bool
        let isRequired: Bool
        let defaultValue: Any
        let metadata: FieldMetadata
        
        init(
            name: String,
            displayName: String? = nil,
            type: FieldType,
            isOptional: Bool = false,
            isRequired: Bool = false,
            defaultValue: Any = NSNull(),
            metadata: FieldMetadata = FieldMetadata()
        ) {
            self.name = name
            self.displayName = displayName ?? Self.formatDisplayName(name)
            self.type = type
            self.isOptional = isOptional
            self.isRequired = isRequired
            self.defaultValue = defaultValue
            self.metadata = metadata
        }
        
        private static func formatDisplayName(_ name: String) -> String {
            return name
                .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }
    
    // MARK: - Field Types
    
    enum FieldType: Equatable {
        case string
        case int
        case double
        case bool
        case date
        case enumeration(type: String, cases: [String])
        case relationship(type: String, isCollection: Bool)
        case optional(wrapped: FieldType)
        case array(element: FieldType)
        case unknown(typeString: String)
        
        var rendererType: FieldRendererType {
            switch self {
            case .string:
                return .textField
            case .int, .double:
                return .numberField
            case .bool:
                return .toggle
            case .date:
                return .datePicker
            case .enumeration:
                return .enumPicker
            case .relationship:
                return .relationshipPicker
            case .optional(let wrapped):
                return wrapped.rendererType
            case .array:
                return .arrayField
            case .unknown:
                return .textField
            }
        }
    }
    
    enum FieldRendererType {
        case textField
        case numberField
        case toggle
        case datePicker
        case enumPicker
        case relationshipPicker
        case arrayField
    }
    
    // MARK: - Field Metadata
    
    struct FieldMetadata {
        let placeholder: String?
        let unit: String?
        let minValue: Double?
        let maxValue: Double?
        let characterLimit: Int?
        let multiline: Bool
        let isSecure: Bool
        
        init(
            placeholder: String? = nil,
            unit: String? = nil,
            minValue: Double? = nil,
            maxValue: Double? = nil,
            characterLimit: Int? = nil,
            multiline: Bool = false,
            isSecure: Bool = false
        ) {
            self.placeholder = placeholder
            self.unit = unit
            self.minValue = minValue
            self.maxValue = maxValue
            self.characterLimit = characterLimit
            self.multiline = multiline
            self.isSecure = isSecure
        }
    }
}