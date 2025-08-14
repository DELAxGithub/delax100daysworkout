import SwiftData
import Foundation

// MARK: - Model Operations Protocol

protocol ModelOperations {
    func validateModel<T: PersistentModel>(_ model: T) -> ValidationResult
    func beforeCreateModel<T: PersistentModel>(_ model: T) -> T
    func beforeUpdateModel<T: PersistentModel>(_ model: T) -> T
    func beforeDeleteModel<T: PersistentModel>(_ model: T) -> Bool
    func afterCreateModel<T: PersistentModel>(_ model: T)
    func afterUpdateModel<T: PersistentModel>(_ model: T)
    func afterDeleteModel<T: PersistentModel>(_ model: T)
}

extension ModelOperations {
    func validateModel<T: PersistentModel>(_ model: T) -> ValidationResult { .success }
    func beforeCreateModel<T: PersistentModel>(_ model: T) -> T { model }
    func beforeUpdateModel<T: PersistentModel>(_ model: T) -> T { model }
    func beforeDeleteModel<T: PersistentModel>(_ model: T) -> Bool { true }
    func afterCreateModel<T: PersistentModel>(_ model: T) {}
    func afterUpdateModel<T: PersistentModel>(_ model: T) {}
    func afterDeleteModel<T: PersistentModel>(_ model: T) {}
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