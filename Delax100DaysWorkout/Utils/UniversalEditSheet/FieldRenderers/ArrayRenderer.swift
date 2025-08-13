import SwiftUI

// MARK: - Array Field Renderer

struct ArrayRenderer {
    
    @ViewBuilder
    static func createArrayField(
        field: FieldTypeDetector.FieldInfo,
        value: Binding<Any>,
        isEditing: Bool
    ) -> some View {
        if case .array(let elementType) = field.type {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                // Header with add button
                ArrayFieldHeader(
                    elementType: elementType,
                    isEditing: isEditing,
                    onAdd: {
                        addArrayItem(value: value, elementType: elementType)
                    }
                )
                
                // Items list
                ArrayItemsList(
                    elementType: elementType,
                    value: value,
                    isEditing: isEditing
                )
            }
        } else {
            Text("Array configuration error")
                .foregroundColor(SemanticColor.errorAction.color)
        }
    }
    
    // MARK: - Array Management
    
    private static func addArrayItem(value: Binding<Any>, elementType: FieldTypeDetector.FieldType) {
        let newItem = createDefaultValue(for: elementType)
        
        if var currentArray = value.wrappedValue as? [Any] {
            currentArray.append(newItem)
            value.wrappedValue = currentArray
        } else {
            value.wrappedValue = [newItem]
        }
    }
    
    private static func removeArrayItem(at index: Int, value: Binding<Any>) {
        if var currentArray = value.wrappedValue as? [Any] {
            currentArray.remove(at: index)
            value.wrappedValue = currentArray
        }
    }
    
    private static func createDefaultValue(for elementType: FieldTypeDetector.FieldType) -> Any {
        switch elementType {
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
        default:
            return NSNull()
        }
    }
    
    static func validateArray(
        _ value: Any?,
        for field: FieldTypeDetector.FieldInfo
    ) -> FieldValidationEngine.ValidationResult {
        if field.isRequired {
            if let arrayValue = value as? [Any] {
                return arrayValue.isEmpty ? .failure("\(field.displayName)に項目を追加してください") : .success
            } else {
                return .failure("\(field.displayName)が必要です")
            }
        }
        
        return .success
    }
}

// MARK: - Array Field Header

private struct ArrayFieldHeader: View {
    let elementType: FieldTypeDetector.FieldType
    let isEditing: Bool
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            Text(getArrayDisplayName(for: elementType))
                .font(Typography.bodyMedium.font)
                .foregroundColor(SemanticColor.secondaryText.color)
            
            Spacer()
            
            if isEditing {
                Button(action: onAdd) {
                    HStack(spacing: Spacing.xs.value) {
                        Image(systemName: "plus.circle.fill")
                        Text("追加")
                    }
                    .font(Typography.captionMedium.font)
                    .foregroundColor(SemanticColor.primaryAction.color)
                }
            }
        }
    }
    
    private func getArrayDisplayName(for elementType: FieldTypeDetector.FieldType) -> String {
        switch elementType {
        case .string:
            return "テキスト項目"
        case .int, .double:
            return "数値項目"
        case .date:
            return "日付項目"
        default:
            return "項目"
        }
    }
}

// MARK: - Array Items List

private struct ArrayItemsList: View {
    let elementType: FieldTypeDetector.FieldType
    let value: Binding<Any>
    let isEditing: Bool
    
    var body: some View {
        if let arrayValue = value.wrappedValue as? [Any], !arrayValue.isEmpty {
            ForEach(Array(arrayValue.enumerated()), id: \.offset) { index, item in
                ArrayItemRow(
                    item: item,
                    index: index,
                    elementType: elementType,
                    isEditing: isEditing,
                    onUpdate: { newValue in
                        updateArrayItem(at: index, with: newValue)
                    },
                    onRemove: {
                        removeArrayItem(at: index)
                    }
                )
            }
        } else {
            EmptyArrayView()
        }
    }
    
    private func updateArrayItem(at index: Int, with newValue: Any) {
        if var currentArray = value.wrappedValue as? [Any] {
            currentArray[index] = newValue
            value.wrappedValue = currentArray
        }
    }
    
    private func removeArrayItem(at index: Int) {
        if var currentArray = value.wrappedValue as? [Any] {
            currentArray.remove(at: index)
            value.wrappedValue = currentArray
        }
    }
}

// MARK: - Array Item Row

private struct ArrayItemRow: View {
    let item: Any
    let index: Int
    let elementType: FieldTypeDetector.FieldType
    let isEditing: Bool
    let onUpdate: (Any) -> Void
    let onRemove: () -> Void
    
    @State private var editingValue: String = ""
    
    var body: some View {
        HStack(spacing: Spacing.sm.value) {
            Text("\(index + 1).")
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.secondaryText.color)
                .frame(width: 20, alignment: .leading)
            
            createElementEditor()
            
            if isEditing {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(SemanticColor.errorAction.color)
                }
            }
        }
        .padding(.vertical, Spacing.xs.value)
        .padding(.horizontal, Spacing.sm.value)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .fill(SemanticColor.surfaceBackground.color.opacity(0.3))
        )
        .onAppear {
            editingValue = String(describing: item)
        }
    }
    
    @ViewBuilder
    private func createElementEditor() -> some View {
        switch elementType {
        case .string:
            TextField("項目を入力", text: $editingValue)
                .textFieldStyle(PlainTextFieldStyle())
                .disabled(!isEditing)
                .onChange(of: editingValue) { _, newValue in
                    onUpdate(newValue)
                }
                
        case .int:
            TextField("0", text: $editingValue)
                .keyboardType(.numberPad)
                .textFieldStyle(PlainTextFieldStyle())
                .disabled(!isEditing)
                .onChange(of: editingValue) { _, newValue in
                    if let intValue = Int(newValue) {
                        onUpdate(intValue)
                    }
                }
                
        case .double:
            TextField("0.0", text: $editingValue)
                .keyboardType(.decimalPad)
                .textFieldStyle(PlainTextFieldStyle())
                .disabled(!isEditing)
                .onChange(of: editingValue) { _, newValue in
                    if let doubleValue = Double(newValue) {
                        onUpdate(doubleValue)
                    }
                }
                
        default:
            Text(String(describing: item))
                .font(Typography.bodySmall.font)
                .foregroundColor(SemanticColor.primaryText.color)
        }
    }
}

// MARK: - Empty Array View

private struct EmptyArrayView: View {
    var body: some View {
        VStack(spacing: Spacing.sm.value) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundColor(SemanticColor.tertiaryText.color)
            
            Text("項目がありません")
                .font(Typography.bodySmall.font)
                .foregroundColor(SemanticColor.tertiaryText.color)
            
            Text("「追加」ボタンで項目を追加できます")
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.tertiaryText.color)
        }
        .padding(.vertical, Spacing.lg.value)
        .frame(maxWidth: .infinity)
    }
}