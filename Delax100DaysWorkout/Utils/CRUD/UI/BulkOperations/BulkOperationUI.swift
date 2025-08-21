import SwiftUI
import SwiftData
import OSLog

struct BulkOperationUI<T: PersistentModel>: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var crudEngine: CRUDEngine<T>
    @StateObject private var operationManager = BulkOperationManager<T>()
    
    let items: [T]
    let onComplete: () -> Void
    
    init(items: [T], modelContext: ModelContext, onComplete: @escaping () -> Void) {
        self.items = items
        self.onComplete = onComplete
        self._crudEngine = StateObject(wrappedValue: CRUDEngine<T>(
            modelContext: modelContext,
            errorHandler: ErrorHandler()
        ))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with selection count
            HStack {
                Text("\(operationManager.selectedItems.count) of \(items.count) selected")
                    .font(.headline)
                Spacer()
                Button(operationManager.isAllSelected ? "Deselect All" : "Select All") {
                    operationManager.toggleSelectAll(items)
                }
            }
            
            // Operation buttons
            BulkActionBar(
                selectedCount: operationManager.selectedItems.count,
                isProcessing: operationManager.isProcessing,
                onDelete: { performBulkDelete() },
                onExport: { performBulkExport() },
                onDuplicate: { performBulkDuplicate() }
            )
            
            // Progress indicator
            if operationManager.isProcessing {
                ProgressView(operationManager.progressMessage)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            // Items list with selection
            List(items, id: \.persistentModelID) { item in
                SelectableItemRow(
                    item: item,
                    isSelected: operationManager.selectedItems.contains(item.persistentModelID),
                    onToggle: { operationManager.toggleSelection(item) }
                )
            }
        }
        .onAppear { operationManager.setup(items: items) }
    }
    
    private func performBulkDelete() {
        Task {
            await operationManager.performBulkOperation(
                operation: .delete,
                crudEngine: crudEngine,
                onComplete: onComplete
            )
        }
    }
    
    private func performBulkExport() {
        operationManager.exportSelectedItems()
    }
    
    private func performBulkDuplicate() {
        Task {
            await operationManager.performBulkOperation(
                operation: .duplicate,
                crudEngine: crudEngine,
                onComplete: onComplete
            )
        }
    }
}

@MainActor
class BulkOperationManager<T: PersistentModel>: ObservableObject {
    @Published var selectedItems: Set<PersistentIdentifier> = []
    @Published var isProcessing = false
    @Published var progressMessage = ""
    
    private var allItems: [T] = []
    
    var isAllSelected: Bool {
        selectedItems.count == allItems.count
    }
    
    func setup(items: [T]) {
        allItems = items
    }
    
    func toggleSelection(_ item: T) {
        if selectedItems.contains(item.persistentModelID) {
            selectedItems.remove(item.persistentModelID)
        } else {
            selectedItems.insert(item.persistentModelID)
        }
    }
    
    func toggleSelectAll(_ items: [T]) {
        if isAllSelected {
            selectedItems.removeAll()
        } else {
            selectedItems = Set(items.map(\.persistentModelID))
        }
    }
    
    func performBulkOperation(
        operation: BulkOperation,
        crudEngine: CRUDEngine<T>,
        onComplete: @escaping () -> Void
    ) async {
        isProcessing = true
        let selectedModels = allItems.filter { selectedItems.contains($0.persistentModelID) }
        
        switch operation {
        case .delete:
            await performBulkDelete(selectedModels, crudEngine: crudEngine)
        case .duplicate:
            await performBulkDuplicate(selectedModels, crudEngine: crudEngine)
        }
        
        isProcessing = false
        selectedItems.removeAll()
        onComplete()
    }
    
    private func performBulkDelete(_ items: [T], crudEngine: CRUDEngine<T>) async {
        for (index, item) in items.enumerated() {
            progressMessage = "Deleting item \(index + 1) of \(items.count)"
            await crudEngine.delete(item)
        }
    }
    
    private func performBulkDuplicate(_ items: [T], crudEngine: CRUDEngine<T>) async {
        for (index, item) in items.enumerated() {
            progressMessage = "Duplicating item \(index + 1) of \(items.count)"
            // Note: Duplication would require model-specific logic
            // This is a simplified implementation
        }
    }
    
    func exportSelectedItems() {
        let selectedModels = allItems.filter { selectedItems.contains($0.persistentModelID) }
        ExportManager.shared.exportModels(selectedModels)
    }
}

enum BulkOperation {
    case delete, duplicate
}

struct BulkActionBar: View {
    let selectedCount: Int
    let isProcessing: Bool
    let onDelete: () -> Void
    let onExport: () -> Void
    let onDuplicate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: "Delete",
                icon: "trash",
                color: .red,
                disabled: selectedCount == 0 || isProcessing,
                action: onDelete
            )
            
            ActionButton(
                title: "Export",
                icon: "square.and.arrow.up",
                color: .blue,
                disabled: selectedCount == 0,
                action: onExport
            )
            
            ActionButton(
                title: "Duplicate",
                icon: "doc.on.doc",
                color: .green,
                disabled: selectedCount == 0 || isProcessing,
                action: onDuplicate
            )
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let disabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(color)
        .disabled(disabled)
    }
}

struct SelectableItemRow<T: PersistentModel>: View {
    let item: T
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            ModelRowContent(item: item)
            
            Spacer()
        }
    }
}

struct ModelRowContent<T: PersistentModel>: View {
    let item: T
    
    var body: some View {
        Text(String(describing: item))
            .font(.subheadline)
    }
}

class ExportManager {
    static let shared = ExportManager()
    
    func exportModels<T: PersistentModel>(_ models: [T]) {
        // Implementation would depend on export format (JSON, CSV, etc.)
        Logger.general.info("Exporting \(models.count) items")
    }
}