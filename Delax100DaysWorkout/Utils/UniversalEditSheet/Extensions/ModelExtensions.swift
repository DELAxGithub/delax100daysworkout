import SwiftUI
import SwiftData

// MARK: - PersistentModel Extensions for Universal Edit Sheet

extension PersistentModel {
    
    /// Create a universal edit sheet for this model
    static func editSheet<T: PersistentModel>(
        for modelType: T.Type,
        existingModel: T? = nil,
        onSave: ((T) -> Void)? = nil
    ) -> GenericEditSheet<T> {
        let customization = getModelCustomization(for: modelType)
        
        return GenericEditSheet(
            modelType: modelType,
            existingModel: existingModel,
            onSave: onSave,
            customizations: customization
        )
    }
    
    /// Create a universal view sheet for this model (read-only)
    static func viewSheet<T: PersistentModel>(
        for model: T
    ) -> GenericEditSheet<T> {
        let customization = getModelCustomization(for: T.self)
        
        return GenericEditSheet(
            modelType: T.self,
            existingModel: model,
            isEditing: false,
            customizations: customization
        )
    }
    
    /// Get the appropriate customization for a model type
    private static func getModelCustomization<T: PersistentModel>(
        for modelType: T.Type
    ) -> EditableModelProtocol {
        switch String(describing: modelType) {
        case "WorkoutRecord":
            return WorkoutModelCustomization()
        case "DailyMetric":
            return MetricModelCustomization()
        case "UserProfile":
            return ProfileModelCustomization()
        case "DailyTask":
            return TaskModelCustomization()
        case "FTPHistory":
            return FTPModelCustomization()
        default:
            return SimpleModelCustomization()
        }
    }
}

// MARK: - Specific Model Customizations

/// Customization for DailyMetric models
struct MetricModelCustomization: EditableModelProtocol {
    
    var fieldGroups: [String: [String]] {
        return [
            "基本情報": ["date", "weight", "bodyFatPercentage"],
            "詳細測定値": ["muscleMass", "waterPercentage", "basalMetabolicRate"],
            "メモ": ["notes"]
        ]
    }
    
    var customFieldDisplayNames: [String: String] {
        return [
            "bodyFatPercentage": "体脂肪率",
            "muscleMass": "筋肉量",
            "waterPercentage": "水分率",
            "basalMetabolicRate": "基礎代謝"
        ]
    }
    
    var customFieldPlaceholders: [String: String] {
        return [
            "weight": "kg",
            "bodyFatPercentage": "%",
            "muscleMass": "kg",
            "waterPercentage": "%",
            "basalMetabolicRate": "kcal"
        ]
    }
    
    func customValidation(_ model: Any) -> FieldValidationEngine.ValidationResult {
        // Add metric-specific validation
        return .success
    }
    
    var customSections: [EditFormSection] {
        return [
            EditFormSection(title: "測定のコツ", priority: 1000) {
                BaseCard(style: OutlinedCardStyle()) {
                    VStack(alignment: .leading, spacing: Spacing.sm.value) {
                        HStack {
                            Image(systemName: "scalemass")
                                .foregroundColor(.blue)
                            Text("正確な測定のために")
                                .font(Typography.labelMedium.font)
                                .fontWeight(.semibold)
                        }
                        
                        Text("毎日同じ時間帯（朝起床時）に測定することで、より正確なデータが記録できます。")
                            .font(Typography.bodySmall.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                    }
                    .padding(Spacing.md.value)
                }
            }
        ]
    }
}

/// Customization for UserProfile models
struct ProfileModelCustomization: EditableModelProtocol {
    
    var fieldGroups: [String: [String]] {
        return [
            "基本情報": ["name", "age", "gender"],
            "身体測定": ["height", "targetWeight"],
            "目標設定": ["fitnessGoals", "trainingExperience"],
            "設定": ["preferredUnits", "notifications"]
        ]
    }
    
    var editFormStyle: EditFormStyle {
        return .detailed
    }
    
    var customFieldDisplayNames: [String: String] {
        return [
            "targetWeight": "目標体重",
            "fitnessGoals": "フィットネス目標",
            "trainingExperience": "トレーニング経験",
            "preferredUnits": "単位設定"
        ]
    }
    
    var customSections: [EditFormSection] {
        return [
            EditFormSection(title: "プロフィール情報について", priority: 0) {
                BaseCard(style: OutlinedCardStyle()) {
                    VStack(alignment: .leading, spacing: Spacing.sm.value) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.purple)
                            Text("プライバシー")
                                .font(Typography.labelMedium.font)
                                .fontWeight(.semibold)
                        }
                        
                        Text("入力された情報はデバイス内にのみ保存され、外部に送信されることはありません。")
                            .font(Typography.bodySmall.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                    }
                    .padding(Spacing.md.value)
                }
            }
        ]
    }
}

/// Customization for DailyTask models
struct TaskModelCustomization: EditableModelProtocol {
    
    var fieldGroups: [String: [String]] {
        return [
            "基本情報": ["title", "workoutType", "targetDate"],
            "詳細設定": ["priority", "estimatedDuration", "difficulty"],
            "進捗管理": ["isCompleted", "completionCount", "targetCount"]
        ]
    }
    
    var customFieldDisplayNames: [String: String] {
        return [
            "targetDate": "目標日",
            "estimatedDuration": "予想時間",
            "completionCount": "完了回数",
            "targetCount": "目標回数"
        ]
    }
    
    func customValidation(_ model: Any) -> FieldValidationEngine.ValidationResult {
        // Add task-specific validation
        return .success
    }
    
    var customSections: [EditFormSection] {
        return [
            EditFormSection(title: "タスク管理のヒント", priority: 1000) {
                BaseCard(style: OutlinedCardStyle()) {
                    VStack(alignment: .leading, spacing: Spacing.sm.value) {
                        HStack {
                            Image(systemName: "checklist")
                                .foregroundColor(.green)
                            Text("効果的なタスク設定")
                                .font(Typography.labelMedium.font)
                                .fontWeight(.semibold)
                        }
                        
                        Text("SMART目標（具体的、測定可能、達成可能、関連性、時間制限）を心がけましょう。")
                            .font(Typography.bodySmall.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                    }
                    .padding(Spacing.md.value)
                }
            }
        ]
    }
}

/// Customization for FTPHistory models
struct FTPModelCustomization: EditableModelProtocol {
    
    var fieldGroups: [String: [String]] {
        return [
            "FTPデータ": ["date", "ftpValue", "testType"],
            "測定条件": ["testDuration", "averagePower", "normalizedPower"],
            "環境・コメント": ["temperature", "humidity", "notes"]
        ]
    }
    
    var customFieldDisplayNames: [String: String] {
        return [
            "ftpValue": "FTP値",
            "testType": "テスト種類",
            "testDuration": "テスト時間",
            "normalizedPower": "ノーマライズドパワー"
        ]
    }
    
    var customFieldPlaceholders: [String: String] {
        return [
            "ftpValue": "W",
            "testDuration": "分",
            "averagePower": "W",
            "normalizedPower": "W",
            "temperature": "°C",
            "humidity": "%"
        ]
    }
    
    func customValidation(_ model: Any) -> FieldValidationEngine.ValidationResult {
        // Add FTP-specific validation
        return .success
    }
    
    var customSections: [EditFormSection] {
        return [
            EditFormSection(title: "FTPテストについて", priority: 0) {
                BaseCard(style: OutlinedCardStyle()) {
                    VStack(alignment: .leading, spacing: Spacing.sm.value) {
                        HStack {
                            Image(systemName: "bolt")
                                .foregroundColor(.orange)
                            Text("FTP（機能的作業閾値）")
                                .font(Typography.labelMedium.font)
                                .fontWeight(.semibold)
                        }
                        
                        Text("1時間持続可能な最大平均パワーの目安。トレーニングゾーン設定の基準となります。")
                            .font(Typography.bodySmall.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                    }
                    .padding(Spacing.md.value)
                }
            }
        ]
    }
}

// MARK: - Convenience View Extensions

extension View {
    
    /// Present a universal edit sheet for any PersistentModel
    func universalEditSheet<T: PersistentModel>(
        for modelType: T.Type,
        isPresented: Binding<Bool>,
        existingModel: T? = nil,
        onSave: ((T) -> Void)? = nil
    ) -> some View {
        sheet(isPresented: isPresented) {
            PersistentModel.editSheet(
                for: modelType,
                existingModel: existingModel,
                onSave: onSave
            )
        }
    }
    
    /// Present a universal view sheet for any PersistentModel (read-only)
    func universalViewSheet<T: PersistentModel>(
        for model: T,
        isPresented: Binding<Bool>
    ) -> some View {
        sheet(isPresented: isPresented) {
            PersistentModel.viewSheet(for: model)
        }
    }
}