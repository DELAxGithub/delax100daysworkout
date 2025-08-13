import SwiftUI
import SwiftData
import OSLog

// MARK: - Generic Edit Sheet Core Component

struct GenericEditSheet<T: PersistentModel>: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var errorHandler = ErrorHandler()
    
    let modelType: T.Type
    @State private var workingModel: T?
    @State private var fieldValues: [String: Any] = [:]
    @State private var validationErrors: [String: String] = [:]
    @State private var detectedFields: [FieldTypeDetector.FieldInfo] = []
    
    private let isEditing: Bool
    private let onSave: ((T) -> Void)?
    private let customizations: EditableModelProtocol?
    private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "GenericEditSheet")
    
    // MARK: - Initializers
    
    init(
        modelType: T.Type,
        existingModel: T? = nil,
        isEditing: Bool = true,
        onSave: ((T) -> Void)? = nil,
        customizations: EditableModelProtocol? = nil
    ) {
        self.modelType = modelType
        self.isEditing = isEditing
        self.onSave = onSave
        self.customizations = customizations
        
        // Initialize working model
        if let existing = existingModel {
            self._workingModel = State(initialValue: existing)
        } else {
            // SwiftData PersistentModelは直接初期化できないため、nilで初期化
            self._workingModel = State(initialValue: nil)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg.value) {
                    ForEach(groupedFields, id: \.key) { group in
                        fieldGroupCard(group: group)
                    }
                    
                    if isEditing {
                        actionButtonsCard
                    }
                }
                .padding(.horizontal)
            }
            .background(SemanticColor.primaryBackground.color)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            saveModel()
                        }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                    }
                }
            }
        }
        .onAppear {
            initializeForm()
        }
        .unifiedErrorHandling(errorHandler)
    }
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        let modelName = String(describing: modelType)
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
        return isEditing ? "\(modelName)編集" : modelName
    }
    
    private var isFormValid: Bool {
        validationErrors.isEmpty && hasRequiredFields
    }
    
    private var hasRequiredFields: Bool {
        let requiredFields = detectedFields.filter { $0.isRequired }
        return requiredFields.allSatisfy { field in
            if let value = fieldValues[field.name] {
                return !FieldRenderer.isEmpty(value, for: field.type)
            }
            return false
        }
    }
    
    private var groupedFields: [(key: String, value: [FieldTypeDetector.FieldInfo])] {
        let groups = customizations?.fieldGroups ?? ["基本情報": detectedFields.map(\.name)]
        
        return groups.compactMap { groupName, fieldNames in
            let groupFields = detectedFields.filter { fieldNames.contains($0.name) }
            return groupFields.isEmpty ? nil : (key: groupName, value: groupFields)
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func fieldGroupCard(group: (key: String, value: [FieldTypeDetector.FieldInfo])) -> some View {
        BaseCard(style: ElevatedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                HStack {
                    Text(group.key)
                        .font(Typography.headlineSmall.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    Spacer()
                }
                
                ForEach(Array(group.value.enumerated()), id: \.offset) { index, field in
                    if index > 0 {
                        Divider()
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.xs.value) {
                        FieldRenderer.createField(
                            for: field,
                            value: bindingForField(field),
                            isEditing: isEditing
                        )
                        
                        if let error = validationErrors[field.name] {
                            Text(error)
                                .font(Typography.captionMedium.font)
                                .foregroundColor(SemanticColor.errorAction.color)
                        }
                    }
                }
            }
            .padding(Spacing.md.value)
        }
    }
    
    private var actionButtonsCard: some View {
        BaseCard(style: OutlinedCardStyle()) {
            HStack(spacing: Spacing.lg.value) {
                Button("リセット") {
                    resetForm()
                }
                .foregroundColor(SemanticColor.secondaryAction.color)
                
                Spacer()
                
                Button("保存") {
                    saveModel()
                }
                .fontWeight(.semibold)
                .foregroundColor(isFormValid ? SemanticColor.primaryAction.color : SemanticColor.tertiaryText.color)
                .disabled(!isFormValid)
            }
            .padding(Spacing.md.value)
        }
    }
    
    // MARK: - Helper Methods
    
    private func bindingForField(_ field: FieldTypeDetector.FieldInfo) -> Binding<Any> {
        Binding(
            get: { fieldValues[field.name] ?? field.defaultValue },
            set: { newValue in
                fieldValues[field.name] = newValue
                validateField(field)
            }
        )
    }
    
    private func initializeForm() {
        detectedFields = FieldTypeDetector.analyzeModel(workingModel)
        populateFieldValues()
        validateAllFields()
        logger.info("Initialized form for \(String(describing: modelType)) with \(detectedFields.count) fields")
    }
    
    private func populateFieldValues() {
        let mirror = Mirror(reflecting: workingModel)
        
        for field in detectedFields {
            if let child = mirror.children.first(where: { $0.label == field.name }) {
                fieldValues[field.name] = child.value
            } else {
                fieldValues[field.name] = field.defaultValue
            }
        }
    }
    
    private func validateField(_ field: FieldTypeDetector.FieldInfo) {
        let value = fieldValues[field.name]
        let result = FieldValidationEngine.validate(value: value, for: field)
        
        if result.isValid {
            validationErrors.removeValue(forKey: field.name)
        } else if let errorMessage = result.errorMessage {
            validationErrors[field.name] = errorMessage
        }
    }
    
    private func validateAllFields() {
        for field in detectedFields {
            validateField(field)
        }
    }
    
    private func resetForm() {
        fieldValues.removeAll()
        validationErrors.removeAll()
        populateFieldValues()
        validateAllFields()
    }
    
    private func saveModel() {
        guard isFormValid else {
            errorHandler.handle(AppError.invalidInput("入力内容を確認してください"), style: .inline)
            return
        }
        
        do {
            try applyFieldValuesToModel()
            
            if let customValidation = customizations?.customValidation {
                let result = customValidation(workingModel)
                if !result.isValid {
                    errorHandler.handle(AppError.invalidInput(result.errorMessage ?? "カスタムバリデーションエラー"), style: .inline)
                    return
                }
            }
            
            modelContext.insert(workingModel)
            try modelContext.save()
            
            onSave?(workingModel)
            logger.info("Successfully saved \(String(describing: modelType))")
            
            HapticManager.shared.trigger(.notification(.success))
            dismiss()
            
        } catch {
            logger.error("Failed to save model: \(error.localizedDescription)")
            errorHandler.handleSwiftDataError(error, context: "モデル保存")
        }
    }
    
    private func applyFieldValuesToModel() throws {
        // This is a simplified approach - in production, you'd need proper reflection
        // or code generation to handle property setting safely
        for field in detectedFields {
            if let value = fieldValues[field.name] {
                // Custom field application logic would go here
                // For now, this is a placeholder that demonstrates the concept
                logger.debug("Applying field \(field.name) with value \(String(describing: value))")
            }
        }
    }
}

// MARK: - Static Factory Methods

extension GenericEditSheet {
    static func create(
        modelType: T.Type,
        customizations: EditableModelProtocol? = nil
    ) -> GenericEditSheet<T> {
        return GenericEditSheet(
            modelType: modelType,
            customizations: customizations
        )
    }
    
    static func edit(
        existingModel: T,
        onSave: @escaping (T) -> Void,
        customizations: EditableModelProtocol? = nil
    ) -> GenericEditSheet<T> {
        return GenericEditSheet(
            modelType: T.self,
            existingModel: existingModel,
            onSave: onSave,
            customizations: customizations
        )
    }
    
    static func view(
        model: T,
        customizations: EditableModelProtocol? = nil
    ) -> GenericEditSheet<T> {
        return GenericEditSheet(
            modelType: T.self,
            existingModel: model,
            isEditing: false,
            customizations: customizations
        )
    }
}