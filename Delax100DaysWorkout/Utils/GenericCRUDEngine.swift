import SwiftUI
import SwiftData
import Foundation

// MARK: - CRUD Engine Module Re-export
// 
// This file has been refactored for maintainability:
// - Utils/CRUD/ModelOperations.swift: Protocol definitions
// - Utils/CRUD/CRUDEngine.swift: Core engine implementation  
// - Utils/CRUD/CRUDFactory.swift: Factory methods
// - Utils/ValidationEngine.swift: Validation logic
// - Components/CRUD/GenericCRUDView.swift: UI components

// Re-export core types for backward compatibility
typealias GenericCRUDEngine<T> = CRUDEngine<T> where T: PersistentModel