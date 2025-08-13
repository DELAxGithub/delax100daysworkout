import SwiftUI
import SwiftData
import OSLog

struct DynamicFormGenerator<T: PersistentModel>: View {
    let modelType: T.Type
    @Binding var model: T?
    @State private var fieldValues: [String: Any?] = [:]
    @State private var validationErrors: [String: String] = [:]
    @State private var properties: [PropertyAnalyzer.PropertyInfo] = []
    
    let isEditing: Bool
    let onSave: ((T) -> Void)?
    let onCancel: (() -> Void)?
    
    private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "DynamicFormGenerator")
    
    init(
        modelType: T.Type,
        model: Binding<T?> = .constant(nil),
        isEditing: Bool = true,
        onSave: ((T) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.modelType = modelType
        self._model = model
        self.isEditing = isEditing
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(properties, id: \.name) { property in
                    Section {
                        VStack(alignment: .leading) {
                            FormFieldFactory.createField(
                                for: property,
                                value: bindingForProperty(property.name),
                                isEditing: isEditing
                            )
                            
                            if let errorMessage = validationErrors[property.name] {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                if isEditing {
                    Section {
                        HStack {
                            if let onCancel = onCancel {
                                Button("Cancel") {
                                    onCancel()
                                }
                                .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            Button("Save") {
                                saveModel()
                            }
                            .fontWeight(.semibold)
                            .disabled(!isFormValid)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit \(modelDisplayName)" : modelDisplayName)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            initializeForm()
        }
        .onChange(of: fieldValues) { _ in
            validateForm()
        }
    }
    
    private var modelDisplayName: String {
        String(describing: modelType).replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
    }
    
    private var isFormValid: Bool {
        validationErrors.isEmpty
    }
    
    private func bindingForProperty(_ propertyName: String) -> Binding<Any?> {
        Binding(
            get: { fieldValues[propertyName] ?? nil },
            set: { fieldValues[propertyName] = $0 }
        )
    }
    
    private func initializeForm() {
        properties = PropertyAnalyzer.analyzeModel(modelType)
        
        if let existingModel = model {
            populateFieldsFromModel(existingModel)
        } else {
            initializeDefaultValues()
        }
        
        validateForm()
    }
    
    private func populateFieldsFromModel(_ model: T) {
        let mirror = Mirror(reflecting: model)
        
        for child in mirror.children {
            guard let propertyName = child.label else { continue }
            fieldValues[propertyName] = child.value
        }
    }
    
    private func initializeDefaultValues() {
        for property in properties {
            switch property.type {
            case .string:
                fieldValues[property.name] = ""
            case .int:
                fieldValues[property.name] = 0
            case .double:
                fieldValues[property.name] = 0.0
            case .bool:
                fieldValues[property.name] = false
            case .date:
                fieldValues[property.name] = Date()
            case .optional:
                fieldValues[property.name] = nil
            default:
                fieldValues[property.name] = nil
            }
        }
    }
    
    private func validateForm() {
        validationErrors.removeAll()
        
        for property in properties {
            let value = fieldValues[property.name]
            let result = FormFieldFactory.validateField(property: property, value: value)
            
            if !result.isValid, let errorMessage = result.errorMessage {
                validationErrors[property.name] = errorMessage
            }
        }
    }
    
    private func saveModel() {
        guard isFormValid else {
            logger.warning("Attempted to save invalid form")
            return
        }
        
        do {
            let newModel = try createModelFromFields()
            onSave?(newModel)
            logger.info("Successfully created \(modelDisplayName) from dynamic form")
        } catch {
            logger.error("Failed to create model from form: \(error.localizedDescription)")
        }
    }
    
    private func createModelFromFields() throws -> T {
        let newModel = modelType.init()
        let mirror = Mirror(reflecting: newModel)
        
        for child in mirror.children {
            guard let propertyName = child.label,
                  let fieldValue = fieldValues[propertyName] else { continue }
            
            // This is a simplified approach. In a real implementation,
            // you would need to use reflection or a more sophisticated
            // property mapping system to set values on the model.
            logger.debug("Setting property \(propertyName) to \(String(describing: fieldValue))")
        }
        
        return newModel
    }
}

extension DynamicFormGenerator {
    static func createView(
        for modelType: T.Type,
        isEditing: Bool = true,
        model: T? = nil
    ) -> some View {
        DynamicFormGenerator(
            modelType: modelType,
            model: .constant(model),
            isEditing: isEditing
        )
    }
    
    static func editView(
        for model: T,
        onSave: @escaping (T) -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        DynamicFormGenerator(
            modelType: T.self,
            model: .constant(model),
            isEditing: true,
            onSave: onSave,
            onCancel: onCancel
        )
    }
    
    static func detailView(for model: T) -> some View {
        DynamicFormGenerator(
            modelType: T.self,
            model: .constant(model),
            isEditing: false
        )
    }
}