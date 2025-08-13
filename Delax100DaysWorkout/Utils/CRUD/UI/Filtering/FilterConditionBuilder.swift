import SwiftUI
import SwiftData

struct FilterConditionBuilder<T: PersistentModel>: View {
    let modelType: T.Type
    let availableProperties: [PropertyAnalyzer.PropertyInfo]
    
    @Binding var filterGroup: AdvancedFilteringEngine<T>.FilterGroup
    
    @State private var selectedProperty: PropertyAnalyzer.PropertyInfo?
    @State private var selectedOperation: Any?
    @State private var textValue = ""
    @State private var numberValue: Double = 0
    @State private var dateValue = Date()
    @State private var boolValue = false
    @State private var showingConditionSheet = false
    
    private let filterEngine: AdvancedFilteringEngine<T>
    
    init(
        modelType: T.Type,
        filterGroup: Binding<AdvancedFilteringEngine<T>.FilterGroup>
    ) {
        self.modelType = modelType
        self.filterEngine = AdvancedFilteringEngine(modelType: modelType)
        self.availableProperties = filterEngine.getAvailableProperties()
        self._filterGroup = filterGroup
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Filter Conditions")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu {
                    Button("Add Condition") {
                        showingConditionSheet = true
                    }
                    
                    Button("Clear All") {
                        filterGroup = AdvancedFilteringEngine<T>.FilterGroup()
                    }
                    
                    Menu("Load Preset") {
                        ForEach(getPresets(), id: \.id) { preset in
                            Button(preset.name) {
                                filterGroup = preset.filterGroup
                            }
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            
            // Logical Operator Selection
            if filterGroup.conditions.count > 1 || !filterGroup.nestedGroups.isEmpty {
                Picker("Operator", selection: $filterGroup.operator) {
                    ForEach(AdvancedFilteringEngine<T>.LogicalOperator.allCases, id: \.self) { op in
                        Text(op.displayName).tag(op)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Conditions List
            if !filterGroup.conditions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(filterGroup.conditions.enumerated()), id: \.offset) { index, condition in
                        ConditionRow(
                            condition: condition,
                            onDelete: {
                                filterGroup.conditions.remove(at: index)
                            }
                        )
                    }
                }
            }
            
            // Empty State
            if filterGroup.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No filters applied")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Add First Condition") {
                        showingConditionSheet = true
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .sheet(isPresented: $showingConditionSheet) {
            AddConditionSheet(
                availableProperties: availableProperties,
                filterEngine: filterEngine,
                onAdd: { condition in
                    filterGroup.conditions.append(condition)
                    showingConditionSheet = false
                },
                onCancel: {
                    showingConditionSheet = false
                }
            )
        }
    }
    
    private func getPresets() -> [AdvancedFilteringEngine<T>.FilterPreset] {
        // Return model-specific presets
        if T.self == WorkoutRecord.self {
            return AdvancedFilteringEngine<WorkoutRecord>.createWorkoutRecordPresets() as! [AdvancedFilteringEngine<T>.FilterPreset]
        } else if T.self == UserProfile.self {
            return AdvancedFilteringEngine<UserProfile>.createUserProfilePresets() as! [AdvancedFilteringEngine<T>.FilterPreset]
        }
        return []
    }
}

struct ConditionRow: View {
    let condition: AdvancedFilteringEngine<WorkoutRecord>.FilterCondition
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(conditionDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(conditionDetails)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private var conditionDescription: String {
        switch condition {
        case .text(let property, let operation, _):
            return "\(property.capitalized) \(operation.displayName)"
        case .number(let property, let operation, _):
            return "\(property.capitalized) \(operation.displayName)"
        case .date(let property, let operation, _):
            return "\(property.capitalized) \(operation.displayName)"
        case .bool(let property, let value):
            return "\(property.capitalized) is \(value ? "true" : "false")"
        case .enumeration(let property, _):
            return "\(property.capitalized) equals"
        case .isNull(let property):
            return "\(property.capitalized) is empty"
        case .isNotNull(let property):
            return "\(property.capitalized) is not empty"
        }
    }
    
    private var conditionDetails: String {
        switch condition {
        case .text(_, _, let value):
            return "'\(value)'"
        case .number(_, _, let value):
            return String(value)
        case .date(_, _, let value):
            return value.formatted(date: .abbreviated, time: .omitted)
        case .bool:
            return ""
        case .enumeration(_, let value):
            return String(describing: value)
        case .isNull, .isNotNull:
            return ""
        }
    }
}

struct AddConditionSheet<T: PersistentModel>: View {
    let availableProperties: [PropertyAnalyzer.PropertyInfo]
    let filterEngine: AdvancedFilteringEngine<T>
    let onAdd: (AdvancedFilteringEngine<T>.FilterCondition) -> Void
    let onCancel: () -> Void
    
    @State private var selectedProperty: PropertyAnalyzer.PropertyInfo?
    @State private var selectedOperation: Any?
    @State private var textValue = ""
    @State private var numberValue: Double = 0
    @State private var dateValue = Date()
    @State private var boolValue = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Property") {
                    Picker("Select Property", selection: $selectedProperty) {
                        Text("Choose property...").tag(nil as PropertyAnalyzer.PropertyInfo?)
                        ForEach(availableProperties, id: \.name) { property in
                            Text(property.displayName).tag(property as PropertyAnalyzer.PropertyInfo?)
                        }
                    }
                }
                
                if let property = selectedProperty {
                    Section("Operation") {
                        operationPicker(for: property)
                    }
                    
                    if shouldShowValueInput {
                        Section("Value") {
                            valueInput(for: property)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Button("Cancel", action: onCancel)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button("Add Condition") {
                            if let condition = buildCondition() {
                                onAdd(condition)
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(!canAddCondition)
                    }
                }
            }
            .navigationTitle("Add Filter Condition")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func operationPicker(for property: PropertyAnalyzer.PropertyInfo) -> some View {
        let operations = filterEngine.getSupportedOperations(for: property.type)
        
        Picker("Operation", selection: $selectedOperation) {
            Text("Choose operation...").tag(nil as Any?)
            ForEach(Array(operations.enumerated()), id: \.offset) { index, operation in
                if let textOp = operation as? AdvancedFilteringEngine<T>.FilterCondition.TextOperation {
                    Text(textOp.displayName).tag(textOp as Any?)
                } else if let numberOp = operation as? AdvancedFilteringEngine<T>.FilterCondition.NumberOperation {
                    Text(numberOp.displayName).tag(numberOp as Any?)
                } else if let dateOp = operation as? AdvancedFilteringEngine<T>.FilterCondition.DateOperation {
                    Text(dateOp.displayName).tag(dateOp as Any?)
                } else {
                    Text(String(describing: operation)).tag(operation as Any?)
                }
            }
        }
    }
    
    @ViewBuilder
    private func valueInput(for property: PropertyAnalyzer.PropertyInfo) -> some View {
        switch property.type {
        case .string:
            TextField("Enter text", text: $textValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
        case .int, .double:
            HStack {
                TextField("Enter number", value: $numberValue, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Stepper("", value: $numberValue, step: property.type == .int ? 1 : 0.1)
                    .labelsHidden()
            }
            
        case .date:
            DatePicker("Select date", selection: $dateValue, displayedComponents: [.date])
            
        case .bool:
            Toggle("Value", isOn: $boolValue)
            
        default:
            Text("Unsupported property type")
                .foregroundColor(.secondary)
        }
    }
    
    private var shouldShowValueInput: Bool {
        guard let property = selectedProperty, selectedOperation != nil else { return false }
        
        switch property.type {
        case .bool:
            return false // Bool operations don't need additional input
        default:
            return true
        }
    }
    
    private var canAddCondition: Bool {
        guard let property = selectedProperty, selectedOperation != nil else { return false }
        
        switch property.type {
        case .string:
            return !textValue.isEmpty
        case .int, .double:
            return true
        case .date:
            return true
        case .bool:
            return true
        default:
            return false
        }
    }
    
    private func buildCondition() -> AdvancedFilteringEngine<T>.FilterCondition? {
        guard let property = selectedProperty else { return nil }
        
        switch property.type {
        case .string:
            guard let operation = selectedOperation as? AdvancedFilteringEngine<T>.FilterCondition.TextOperation else { return nil }
            return .text(property: property.name, operation: operation, value: textValue)
            
        case .int, .double:
            guard let operation = selectedOperation as? AdvancedFilteringEngine<T>.FilterCondition.NumberOperation else { return nil }
            return .number(property: property.name, operation: operation, value: numberValue)
            
        case .date:
            guard let operation = selectedOperation as? AdvancedFilteringEngine<T>.FilterCondition.DateOperation else { return nil }
            return .date(property: property.name, operation: operation, value: dateValue)
            
        case .bool:
            return .bool(property: property.name, value: boolValue)
            
        default:
            return nil
        }
    }
}