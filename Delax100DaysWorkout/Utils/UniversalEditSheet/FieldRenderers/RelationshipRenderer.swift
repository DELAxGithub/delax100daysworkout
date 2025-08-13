import SwiftUI

// MARK: - Relationship Field Renderer

struct RelationshipRenderer {
    
    @ViewBuilder
    static func createRelationshipPicker(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        if case .relationship(let type, let isCollection) = field.type {
            if isCollection {
                createCollectionPicker(type: type, value: value, isEditing: isEditing, field: field)
            } else {
                createSinglePicker(type: type, value: value, isEditing: isEditing, field: field)
            }
        } else {
            Text("Relationship configuration error")
                .foregroundColor(SemanticColor.errorAction.color)
        }
    }
    
    @ViewBuilder
    private static func createSinglePicker(
        type: String,
        value: Binding<Any>,
        isEditing: Bool,
        field: FieldTypeDetector.FieldInfo
    ) -> some View {
        Button(action: {
            if isEditing {
                // TODO: Show relationship picker sheet
                print("Show picker for \(type)")
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    Text(getRelationshipDisplayText(type: type, isCollection: false))
                        .foregroundColor(isEditing ? SemanticColor.primaryAction.color : SemanticColor.tertiaryText.color)
                        .font(Typography.bodyMedium.font)
                    
                    if let description = getRelationshipDescription(type: type) {
                        Text(description)
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(SemanticColor.secondaryText.color)
                    .font(.caption)
            }
            .padding(.vertical, Spacing.sm.value)
            .padding(.horizontal, Spacing.md.value)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium.value)
                    .fill(SemanticColor.surfaceBackground.color)
                    .stroke(SemanticColor.primaryBorder.color, lineWidth: 1)
            )
        }
        .disabled(!isEditing)
    }
    
    @ViewBuilder
    private static func createCollectionPicker(
        type: String,
        value: Binding<Any>,
        isEditing: Bool,
        field: FieldTypeDetector.FieldInfo
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm.value) {
            HStack {
                Text(getRelationshipDisplayText(type: type, isCollection: true))
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
                
                Spacer()
                
                if isEditing {
                    Button("追加") {
                        // TODO: Show collection item picker
                        print("Add item to \(type) collection")
                    }
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.primaryAction.color)
                }
            }
            
            // Show current items (placeholder)
            RelationshipItemsList(type: type, value: value, isEditing: isEditing)
        }
    }
    
    // MARK: - Helper Methods
    
    private static func getRelationshipDisplayText(type: String, isCollection: Bool) -> String {
        let cleanType = type.replacingOccurrences(of: "Detail", with: "")
        
        if isCollection {
            return "\(cleanType)を選択"
        } else {
            return "\(cleanType)を選択"
        }
    }
    
    private static func getRelationshipDescription(type: String) -> String? {
        switch type {
        case let t where t.contains("Cycling"):
            return "サイクリング詳細データ"
        case let t where t.contains("Strength"):
            return "筋トレエクササイズ"
        case let t where t.contains("Task"):
            return "関連タスク"
        case let t where t.contains("User"):
            return "ユーザー情報"
        default:
            return nil
        }
    }
    
    static func validateRelationship(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        if field.isRequired && (value is NSNull || value == nil) {
            return .failure("\(field.displayName)を選択してください")
        }
        
        return .success
    }
}

// MARK: - Relationship Items List

private struct RelationshipItemsList: View {
    let type: String
    let value: Binding<Any>
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.value) {
            // Placeholder for relationship items
            if let items = getRelationshipItems() {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    RelationshipItemRow(
                        item: item,
                        index: index,
                        isEditing: isEditing
                    ) {
                        // Remove item action
                        removeItem(at: index)
                    }
                }
            } else {
                Text("関連項目がありません")
                    .font(Typography.bodySmall.font)
                    .foregroundColor(SemanticColor.tertiaryText.color)
                    .padding(.vertical, Spacing.sm.value)
            }
        }
    }
    
    private func getRelationshipItems() -> [String]? {
        // Placeholder implementation
        return []
    }
    
    private func removeItem(at index: Int) {
        // TODO: Implement item removal
        print("Remove item at index \(index)")
    }
}

// MARK: - Relationship Item Row

private struct RelationshipItemRow: View {
    let item: String
    let index: Int
    let isEditing: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text("項目 \(index + 1)")
                .font(Typography.bodySmall.font)
                .foregroundColor(SemanticColor.primaryText.color)
            
            Spacer()
            
            if isEditing {
                Button("削除") {
                    onRemove()
                }
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.errorAction.color)
            }
        }
        .padding(.vertical, Spacing.xs.value)
        .padding(.horizontal, Spacing.sm.value)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .fill(SemanticColor.surfaceBackground.color.opacity(0.5))
        )
    }
}