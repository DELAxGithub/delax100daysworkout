import SwiftUI
import SwiftData

struct CRUDMasterView<T: PersistentModel>: View {
    let modelType: T.Type
    @Environment(\.modelContext) private var modelContext
    
    @State private var items: [T] = []
    @State private var showingBulkOperations = false
    @State private var showingAnalytics = false
    @State private var showingCreateForm = false
    @State private var crudEngine: CRUDEngine<T>?
    @State private var filterEngine: FilterEngine<T>?
    
    init(modelType: T.Type) {
        self.modelType = modelType
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Bar
                if let filterEngine = filterEngine {
                    FilterConditionBuilder(modelType: modelType, filterGroup: Binding(
                        get: { filterEngine.activeFilter },
                        set: { filterEngine.activeFilter = $0 }
                    ))
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Items List or Bulk Operations
                if showingBulkOperations {
                    BulkOperationUI(
                        items: items,
                        modelContext: modelContext,
                        onComplete: {
                            showingBulkOperations = false
                            Task { await loadItems() }
                        }
                    )
                } else {
                    ItemsList(items: items, onItemTap: { _ in })
                }
            }
            .navigationTitle(modelDisplayName)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(false)
            .navigationBarItems(
                trailing: Menu {
                    Button("Bulk Operations") { showingBulkOperations.toggle() }
                    Button("Analytics") { showingAnalytics = true }
                    Button("Add Item") { showingCreateForm = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            )
        }
        .sheet(isPresented: $showingAnalytics) {
            CRUDAnalyticsDashboard()
        }
        .sheet(isPresented: $showingCreateForm) {
            DynamicFormGenerator(
                modelType: modelType,
                onSave: { item in
                    Task {
                        await crudEngine?.create(item)
                        await loadItems()
                    }
                    showingCreateForm = false
                }
            )
        }
        .onAppear {
            if crudEngine == nil {
                crudEngine = CRUDEngine<T>(
                    modelContext: modelContext,
                    errorHandler: ErrorHandler()
                )
            }
            if filterEngine == nil {
                filterEngine = FilterEngine<T>(modelType: modelType)
            }
        }
        .task { 
            if crudEngine != nil && filterEngine != nil {
                await loadItems() 
            }
        }
        .onChange(of: filterEngine?.activeFilter) { _ in
            if crudEngine != nil && filterEngine != nil {
                Task { await loadItems() }
            }
        }
    }
    
    private var modelDisplayName: String {
        String(describing: modelType).replacingOccurrences(
            of: "([a-z])([A-Z])", 
            with: "$1 $2", 
            options: .regularExpression
        )
    }
    
    @MainActor
    private func loadItems() async {
        guard let filterEngine = filterEngine,
              let crudEngine = crudEngine else { return }
        
        let predicate = AdvancedFilteringEngine(modelType: modelType)
            .buildPredicate(from: filterEngine.activeFilter)
        
        items = await crudEngine.fetch(predicate: predicate)
    }
}

@MainActor
class FilterEngine<T: PersistentModel>: ObservableObject {
    @Published var activeFilter = AdvancedFilteringEngine<T>.FilterGroup()
    
    private let filteringEngine: AdvancedFilteringEngine<T>
    
    init(modelType: T.Type) {
        self.filteringEngine = AdvancedFilteringEngine(modelType: modelType)
    }
}

struct ItemsList<T: PersistentModel>: View {
    let items: [T]
    let onItemTap: (T) -> Void
    
    var body: some View {
        List(items, id: \.persistentModelID) { item in
            ModelRowContent(item: item)
                .onTapGesture { onItemTap(item) }
        }
    }
}

// MARK: - Extension to CRUDEngine for Analytics Integration

extension CRUDEngine {
    
    func performOperationWithAnalytics<Result>(
        _ operationName: String,
        operation: @escaping () throws -> Result
    ) async -> Result? {
        let startTime = Date()
        
        // Perform original operation
        let result = await performOperation(operationName, operation: operation)
        
        // Track analytics
        let duration = Date().timeIntervalSince(startTime) * 1000 // ms
        let success = result != nil
        
        CRUDAnalytics.shared.trackOperation(
            mapOperationName(operationName),
            for: T.self,
            duration: duration,
            success: success
        )
        
        return result
    }
    
    private func mapOperationName(_ name: String) -> CRUDOperation {
        switch name.lowercased() {
        case let str where str.contains("create"): return .create
        case let str where str.contains("fetch"), let str where str.contains("read"): return .read
        case let str where str.contains("update"): return .update
        case let str where str.contains("delete"): return .delete
        case let str where str.contains("batch"): return .batch
        default: return .read
        }
    }
}

// MARK: - Model-Specific Master Views

extension CRUDMasterView where T == WorkoutRecord {
    static func workoutRecordView() -> CRUDMasterView<WorkoutRecord> {
        CRUDMasterView<WorkoutRecord>(modelType: WorkoutRecord.self)
    }
}

extension CRUDMasterView where T == UserProfile {
    static func userProfileView() -> CRUDMasterView<UserProfile> {
        CRUDMasterView<UserProfile>(modelType: UserProfile.self)
    }
}

extension CRUDMasterView where T == FTPHistory {
    static func ftpHistoryView() -> CRUDMasterView<FTPHistory> {
        CRUDMasterView<FTPHistory>(modelType: FTPHistory.self)
    }
}