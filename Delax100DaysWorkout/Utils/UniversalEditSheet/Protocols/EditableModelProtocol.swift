import SwiftUI
import SwiftData
import Foundation

// MARK: - Editable Model Protocol

protocol EditableModelProtocol {
    
    // MARK: - Field Customization
    
    /// Define custom field groupings for the edit form
    var fieldGroups: [String: [String]] { get }
    
    /// Define fields that should be hidden from the edit form
    var hiddenFields: [String] { get }
    
    /// Define custom display names for fields
    var customFieldDisplayNames: [String: String] { get }
    
    /// Define custom placeholders for fields
    var customFieldPlaceholders: [String: String] { get }
    
    /// Define custom validation rules beyond standard validation
    func customValidation(_ model: Any) -> FieldValidationEngine.ValidationResult
    
    // MARK: - UI Customization
    
    /// Define custom field rendering for specific fields
    func customFieldRenderer(for fieldName: String) -> AnyView?
    
    /// Define custom sections or additional UI elements
    var customSections: [EditFormSection] { get }
    
    /// Define the preferred edit form style
    var editFormStyle: EditFormStyle { get }
    
    // MARK: - Business Logic Hooks
    
    /// Called before saving the model - allows for final modifications
    func beforeSave(_ model: Any) -> Bool
    
    /// Called after successful save
    func afterSave(_ model: Any)
    
    /// Define custom save behavior (optional - defaults to standard SwiftData save)
    func customSave(_ model: Any, context: ModelContext) throws -> Bool
}

// MARK: - Default Implementation

extension EditableModelProtocol {
    
    var fieldGroups: [String: [String]] {
        return ["基本情報": []] // Default: all fields in one group
    }
    
    var hiddenFields: [String] {
        return ["persistentModelID", "_$backingData", "_$observationRegistrar"]
    }
    
    var customFieldDisplayNames: [String: String] {
        return [:]
    }
    
    var customFieldPlaceholders: [String: String] {
        return [:]
    }
    
    func customValidation(_ model: Any) -> FieldValidationEngine.ValidationResult {
        return .success
    }
    
    func customFieldRenderer(for fieldName: String) -> AnyView? {
        return nil
    }
    
    var customSections: [EditFormSection] {
        return []
    }
    
    var editFormStyle: EditFormStyle {
        return .standard
    }
    
    func beforeSave(_ model: Any) -> Bool {
        return true // Allow save
    }
    
    func afterSave(_ model: Any) {
        // Default: no action
    }
    
    func customSave(_ model: Any, context: ModelContext) throws -> Bool {
        return false // Use standard save
    }
}

// MARK: - Supporting Types

struct EditFormSection {
    let title: String
    let content: AnyView
    let priority: Int // Lower values appear first
    
    init<Content: View>(title: String, priority: Int = 100, @ViewBuilder content: () -> Content) {
        self.title = title
        self.priority = priority
        self.content = AnyView(content())
    }
}

enum EditFormStyle {
    case standard        // Standard form with BaseCard sections
    case compact         // Minimal spacing and grouping
    case detailed        // Extra information and help text
    case wizard          // Step-by-step form (future enhancement)
}

// MARK: - Common Model Customizations

/// Standard customization for workout-related models
struct WorkoutModelCustomization: EditableModelProtocol {
    
    var fieldGroups: [String: [String]] {
        return [
            "基本情報": ["summary", "date", "workoutType", "isCompleted"],
            "詳細情報": ["duration", "distance", "averagePower", "intensity"],
            "メモ・その他": ["notes", "tags", "difficulty"]
        ]
    }
    
    var hiddenFields: [String] {
        return [
            "persistentModelID", "_$backingData", "_$observationRegistrar",
            "isQuickRecord", "templateTask" // Internal fields
        ]
    }
    
    var customFieldDisplayNames: [String: String] {
        return [
            "summary": "ワークアウト概要",
            "workoutType": "種目",
            "isCompleted": "完了状態",
            "averagePower": "平均パワー",
            "duration": "時間"
        ]
    }
    
    var customFieldPlaceholders: [String: String] {
        return [
            "summary": "例: 朝のライド、筋トレ、ヨガ",
            "duration": "分",
            "distance": "km",
            "averagePower": "W"
        ]
    }
    
    func customValidation(_ model: Any) -> FieldValidationEngine.ValidationResult {
        // Example: Validate that cycling workouts have distance
        guard let workoutRecord = model as? WorkoutRecord else {
            return .success
        }
        
        if workoutRecord.workoutType == .cycling {
            if workoutRecord.cyclingDetail == nil || workoutRecord.cyclingDetail?.distance == 0 {
                return FieldValidationEngine.ValidationResult.warning("サイクリングワークアウトには距離を記録することをお勧めします")
            }
        }
        
        return .success
    }
    
    var customSections: [EditFormSection] {
        return [
            EditFormSection(title: "ワークアウトのヒント", priority: 1000) {
                BaseCard(style: OutlinedCardStyle()) {
                    VStack(alignment: .leading, spacing: Spacing.sm.value) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.orange)
                            Text("記録のコツ")
                                .font(Typography.labelMedium.font)
                                .fontWeight(.semibold)
                        }
                        
                        Text("詳細な記録を付けることで、トレーニングの効果を最大化できます。")
                            .font(Typography.bodySmall.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                    }
                    .padding(Spacing.md.value)
                }
            }
        ]
    }
    
    func beforeSave(_ model: Any) -> Bool {
        guard let workoutRecord = model as? WorkoutRecord else { return true }
        
        // Auto-set completion status based on details
        if workoutRecord.workoutType == .cycling && workoutRecord.cyclingDetail?.distance ?? 0 > 0 {
            workoutRecord.isCompleted = true
        }
        
        return true
    }
    
    func afterSave(_ model: Any) {
        // Example: Trigger analytics or notifications
        guard let workoutRecord = model as? WorkoutRecord else { return }
        
        if workoutRecord.isCompleted {
            // Could trigger achievement checks, statistics updates, etc.
            print("Workout completed: \(workoutRecord.summary)")
        }
    }
}

/// Minimal customization for simple models
struct SimpleModelCustomization: EditableModelProtocol {
    
    var editFormStyle: EditFormStyle {
        return .compact
    }
    
    var fieldGroups: [String: [String]] {
        return ["情報": []] // All fields in one group
    }
}

/// Detailed customization for complex models
struct DetailedModelCustomization: EditableModelProtocol {
    
    var editFormStyle: EditFormStyle {
        return .detailed
    }
    
    var customSections: [EditFormSection] {
        return [
            EditFormSection(title: "フィールド説明", priority: 0) {
                BaseCard(style: OutlinedCardStyle()) {
                    Text("各フィールドの詳細な説明や使用方法がここに表示されます。")
                        .font(Typography.bodySmall.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                        .padding(Spacing.md.value)
                }
            }
        ]
    }
}

// MARK: - Model Extension Helper

extension EditableModelProtocol where Self: PersistentModel {
    
    /// Helper method to get the appropriate customization for a model
    static func getCustomization() -> EditableModelProtocol {
        switch String(describing: self) {
        case "WorkoutRecord":
            return WorkoutModelCustomization()
        case "DailyMetric", "UserProfile":
            return DetailedModelCustomization()
        default:
            return SimpleModelCustomization()
        }
    }
}