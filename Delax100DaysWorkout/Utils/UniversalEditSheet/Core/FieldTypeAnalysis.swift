import Foundation
import SwiftData

// MARK: - Field Type Analysis Engine

struct FieldTypeAnalysis {
    
    // MARK: - Type Detection
    
    static func detectFieldType(from value: Any, typeString: String) -> FieldTypeDetector.FieldType {
        // Handle Optional types first
        if typeString.contains("Optional<") {
            let wrappedTypeString = extractOptionalWrappedType(typeString)
            let wrappedType = detectBaseFieldType(typeString: wrappedTypeString, value: value)
            return .optional(wrapped: wrappedType)
        }
        
        // Handle Array types
        if typeString.contains("Array<") || typeString.contains("[") {
            let elementTypeString = extractArrayElementType(typeString)
            let elementType = detectBaseFieldType(typeString: elementTypeString, value: value)
            return .array(element: elementType)
        }
        
        return detectBaseFieldType(typeString: typeString, value: value)
    }
    
    static func detectBaseFieldType(typeString: String, value: Any) -> FieldTypeDetector.FieldType {
        if typeString.contains("String") {
            return .string
        } else if typeString.contains("Int") && !typeString.contains("Double") {
            return .int
        } else if typeString.contains("Double") || typeString.contains("Float") {
            return .double
        } else if typeString.contains("Bool") {
            return .bool
        } else if typeString.contains("Date") {
            return .date
        } else if isEnumeration(value) {
            return extractEnumerationType(from: value)
        } else if isRelationship(typeString) {
            return extractRelationshipType(from: typeString)
        }
        
        return .unknown(typeString: typeString)
    }
    
    // MARK: - Enumeration Detection
    
    static func isEnumeration(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)
        return mirror.displayStyle == .enum
    }
    
    static func extractEnumerationType(from value: Any) -> FieldTypeDetector.FieldType {
        let valueType = type(of: value)
        let typeName = String(describing: valueType)
        
        // For CaseIterable enums, extract all cases
        if let caseIterable = value as? any CaseIterable {
            let cases = Array(caseIterable.allCases).map { String(describing: $0) }
            return .enumeration(type: typeName, cases: cases)
        }
        
        return .enumeration(type: typeName, cases: [])
    }
    
    // MARK: - Relationship Detection
    
    static func isRelationship(_ typeString: String) -> Bool {
        return typeString.contains("Relationship") || 
               typeString.contains("@Relationship") ||
               typeString.contains("ToMany") ||
               typeString.contains("ToOne")
    }
    
    static func extractRelationshipType(from typeString: String) -> FieldTypeDetector.FieldType {
        let isCollection = typeString.contains("[") || typeString.contains("Array")
        let cleanType = typeString
            .replacingOccurrences(of: "Relationship<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        
        return .relationship(type: cleanType, isCollection: isCollection)
    }
    
    // MARK: - Type String Parsing
    
    static func extractOptionalWrappedType(_ typeString: String) -> String {
        if let range = typeString.range(of: "Optional<") {
            let startIndex = typeString.index(range.upperBound, offsetBy: 0)
            if let endIndex = typeString.lastIndex(of: ">") {
                return String(typeString[startIndex..<endIndex])
            }
        }
        return typeString
    }
    
    static func extractArrayElementType(_ typeString: String) -> String {
        if typeString.contains("Array<") {
            if let range = typeString.range(of: "Array<") {
                let startIndex = typeString.index(range.upperBound, offsetBy: 0)
                if let endIndex = typeString.lastIndex(of: ">") {
                    return String(typeString[startIndex..<endIndex])
                }
            }
        } else if typeString.contains("[") && typeString.contains("]") {
            return typeString.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
        }
        return "Unknown"
    }
    
    // MARK: - Default Value Generation
    
    static func generateDefaultValue(for fieldType: FieldTypeDetector.FieldType, isOptional: Bool) -> Any {
        if isOptional {
            return NSNull()
        }
        
        switch fieldType {
        case .string:
            return ""
        case .int:
            return 0
        case .double:
            return 0.0
        case .bool:
            return false
        case .date:
            return Date()
        case .optional:
            return NSNull()
        case .enumeration(_, let cases):
            return cases.first ?? ""
        case .relationship:
            return NSNull()
        case .array:
            return []
        case .unknown:
            return NSNull()
        }
    }
}