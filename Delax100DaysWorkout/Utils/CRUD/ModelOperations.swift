import SwiftData
import Foundation

// MARK: - Model Operations Protocol

protocol ModelOperations {
    associatedtype Model: PersistentModel
    
    func validate(_ model: Model) -> ValidationResult
    func beforeCreate(_ model: Model) -> Model
    func beforeUpdate(_ model: Model) -> Model
    func beforeDelete(_ model: Model) -> Bool
    func afterCreate(_ model: Model)
    func afterUpdate(_ model: Model)
    func afterDelete(_ model: Model)
}

extension ModelOperations {
    func validate(_ model: Model) -> ValidationResult { .success }
    func beforeCreate(_ model: Model) -> Model { model }
    func beforeUpdate(_ model: Model) -> Model { model }
    func beforeDelete(_ model: Model) -> Bool { true }
    func afterCreate(_ model: Model) {}
    func afterUpdate(_ model: Model) {}
    func afterDelete(_ model: Model) {}
}

// MARK: - Validation Result

enum ValidationResult {
    case success
    case failure(String)
    
    var isValid: Bool {
        if case .success = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}