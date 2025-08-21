import SwiftUI
import SwiftData

// MARK: - Generic CRUD View Components

struct GenericCRUDView<T: PersistentModel & Identifiable>: View {
    let modelType: T.Type
    let displayName: String
    let icon: String
    let color: Color
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var crudEngine: CRUDEngine<T>
    @State private var models: [T] = []
    @State private var isLoading = false
    @State private var showingDeleteAllAlert = false
    @State private var showingCreateSheet = false
    
    init(
        modelType: T.Type,
        displayName: String,
        icon: String,
        color: Color
    ) {
        self.modelType = modelType
        self.displayName = displayName
        self.icon = icon
        self.color = color
        
        // Initialize StateObject with a closure
        self._crudEngine = StateObject(wrappedValue: {
            // This will be properly initialized in onAppear
            let mockContext = ModelContext(try! ModelContainer(for: modelType))
            return CRUDEngine<T>(
                modelContext: mockContext,
                errorHandler: ErrorHandler()
            )
        }())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md.value) {
                // Header Card
                headerCard
                
                // Content
                if isLoading {
                    loadingView
                } else if models.isEmpty {
                    emptyStateView
                } else {
                    modelsList
                }
                
                Spacer()
            }
            .padding(Spacing.md.value)
            .navigationTitle(displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
            }
            .onAppear {
                // Properly initialize the CRUD engine with the environment context
                crudEngine.modelContext = modelContext
                crudEngine.errorHandler = errorHandler
                loadModels()
            }
            .refreshable {
                loadModels()
            }
            .alert("全削除確認", isPresented: $showingDeleteAllAlert) {
                Button("削除", role: .destructive) {
                    deleteAllModels()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての\(displayName)（\(models.count)件）を削除しますか？この操作は取り消せません。")
            }
            .unifiedErrorHandling(errorHandler)
        }
    }
    
    // MARK: - View Components
    
    private var headerCard: some View {
        BaseCard(style: ElevatedCardStyle()) {
            HStack(spacing: Spacing.md.value) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(Typography.headlineLarge.font)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    Text(displayName)
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Text("\(models.count) 件のレコード")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                }
                
                Spacer()
                
                // Quick stats
                if !models.isEmpty {
                    VStack(alignment: .trailing, spacing: Spacing.xs.value) {
                        Text("最新")
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                        
                        if let latestModel = models.first {
                            Text(formatLatestModelInfo(latestModel))
                                .font(Typography.captionMedium.font)
                                .foregroundColor(SemanticColor.primaryText.color)
                        }
                    }
                }
            }
            .padding(Spacing.md.value)
        }
    }
    
    private var loadingView: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("データを読み込み中...")
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
            }
            .padding(Spacing.lg.value)
        }
    }
    
    private var emptyStateView: some View {
        BaseCard(style: DefaultCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                Image(systemName: icon)
                    .foregroundColor(color.opacity(0.5))
                    .font(.system(size: 48))
                
                Text("データがありません")
                    .font(Typography.headlineMedium.font)
                    .foregroundColor(SemanticColor.primaryText.color)
                
                Text("\(displayName)のデータがまだ作成されていません。")
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.xl.value)
        }
    }
    
    private var modelsList: some View {
        LazyVStack(spacing: Spacing.sm.value) {
            ForEach(models) { model in
                GenericModelRow(
                    model: model,
                    icon: icon,
                    color: color,
                    onEdit: { editModel(model) },
                    onDelete: { deleteModel(model) }
                )
            }
        }
    }
    
    private var toolbarMenu: some View {
        Menu {
            Button {
                showingCreateSheet = true
            } label: {
                Label("新規作成", systemImage: "plus")
            }
            
            Button {
                loadModels()
            } label: {
                Label("再読み込み", systemImage: "arrow.clockwise")
            }
            
            if !models.isEmpty {
                Divider()
                
                Button(role: .destructive) {
                    showingDeleteAllAlert = true
                } label: {
                    Label("全削除", systemImage: "trash.fill")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(SemanticColor.primaryAction.color)
        }
    }
    
    // MARK: - Data Operations
    
    private func loadModels() {
        isLoading = true
        Task {
            let fetchedModels = await crudEngine.fetch(
                sortBy: [] // Generic sort - specific implementations should override
            )
            
            await MainActor.run {
                self.models = fetchedModels
                self.isLoading = false
            }
        }
    }
    
    private func deleteModel(_ model: T) {
        Task {
            let success = await crudEngine.delete(model)
            if success {
                await MainActor.run {
                    models.removeAll { $0.id == model.id }
                }
            }
        }
    }
    
    private func deleteAllModels() {
        Task {
            let success = await crudEngine.deleteAll()
            if success {
                await MainActor.run {
                    models.removeAll()
                }
            }
        }
    }
    
    private func editModel(_ model: T) {
        // This would need to be customized per model type
        // For now, we'll just reload the data
        loadModels()
    }
    
    // MARK: - Helper Methods
    
    private func formatLatestModelInfo(_ model: T) -> String {
        // Generic implementation - specific models should override this
        if let workoutRecord = model as? WorkoutRecord {
            return DateFormatter.crudShortDate.string(from: workoutRecord.date)
        } else if let dailyMetric = model as? DailyMetric {
            return DateFormatter.crudShortDate.string(from: dailyMetric.date)
        } else if let ftpHistory = model as? FTPHistory {
            return DateFormatter.crudShortDate.string(from: ftpHistory.date)
        }
        return "最新データ"
    }
}

// MARK: - Generic Model Row Component

struct GenericModelRow<T: PersistentModel & Identifiable>: View {
    let model: T
    let icon: String
    let color: Color
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            HStack(spacing: Spacing.md.value) {
                // Model icon
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(Typography.headlineMedium.font)
                    .frame(width: 24)
                
                // Model info
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    Text(formatModelTitle(model))
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                        .lineLimit(2)
                    
                    Text(formatModelSubtitle(model))
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Action buttons
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(SemanticColor.primaryAction.color)
                        .font(Typography.bodyMedium.font)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, Spacing.sm.value)
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(SemanticColor.errorAction.color)
                        .font(Typography.bodyMedium.font)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(Spacing.md.value)
        }
        .alert("削除確認", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive, action: onDelete)
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("このレコードを削除しますか？この操作は取り消せません。")
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatModelTitle(_ model: T) -> String {
        if let workoutRecord = model as? WorkoutRecord {
            return workoutRecord.summary.isEmpty ? workoutRecord.workoutType.rawValue : workoutRecord.summary
        } else if let dailyMetric = model as? DailyMetric {
            return dailyMetric.formattedWeight ?? "体重記録"
        } else if let ftpHistory = model as? FTPHistory {
            return "\(ftpHistory.ftpValue) W"
        } else if let dailyTask = model as? DailyTask {
            return dailyTask.title
        } else if let weeklyTemplate = model as? WeeklyTemplate {
            return weeklyTemplate.name
        } else if model is UserProfile {
            return "ユーザープロファイル"
        }
        return "レコード"
    }
    
    private func formatModelSubtitle(_ model: T) -> String {
        if let workoutRecord = model as? WorkoutRecord {
            return DateFormatter.crudShortDateTime.string(from: workoutRecord.date)
        } else if let dailyMetric = model as? DailyMetric {
            return DateFormatter.crudShortDate.string(from: dailyMetric.date)
        } else if let ftpHistory = model as? FTPHistory {
            return DateFormatter.crudShortDate.string(from: ftpHistory.date)
        } else if let dailyTask = model as? DailyTask {
            return dailyTask.dayName
        } else if let weeklyTemplate = model as? WeeklyTemplate {
            return "\(weeklyTemplate.dailyTasks.count) タスク"
        } else if let userProfile = model as? UserProfile {
            return "目標体重: \(userProfile.goalWeightKg)kg"
        }
        return ""
    }
}

// MARK: - Date Formatter Extensions (CRUD Specific)
// Note: Using existing DateFormatter extensions from other files

private extension DateFormatter {
    static let crudShortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let crudShortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}