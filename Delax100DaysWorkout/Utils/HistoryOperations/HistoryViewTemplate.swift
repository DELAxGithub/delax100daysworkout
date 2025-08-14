import SwiftUI
import SwiftData

// MARK: - History View Template Protocol

protocol HistoryViewTemplate {
    associatedtype DataModel: Searchable
    associatedtype EntryView: View
    associatedtype EditSheet: View
    
    var modelContext: ModelContext { get }
    var records: [DataModel] { get }
    var searchViewModel: HistorySearchViewModel<DataModel> { get }
    
    // Configuration
    var headerTitle: String { get }
    var emptyStateTitle: String { get }
    var emptyStateSystemImage: String { get }
    var emptyStateDescription: String { get }
    var searchConfiguration: SearchConfiguration { get }
    
    // Sheet states
    var showingEntrySheet: Bool { get set }
    var showingEditSheet: Bool { get set }
    var selectedRecord: DataModel? { get set }
    
    // Actions
    func createEntryView() -> EntryView
    func createEditSheet(for record: DataModel) -> EditSheet
    func deleteRecord(_ record: DataModel)
    func deleteAllRecords()
}

// MARK: - Default History View Implementation

struct UnifiedHistoryView<Template: HistoryViewTemplate>: View {
    @State private var template: Template
    @State private var showingChart = true
    @State private var showingBulkDeleteAlert = false
    @State private var isEditMode = false
    
    init(template: Template) {
        self._template = State(initialValue: template)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Unified Header
            UnifiedHeaderComponent(
                configuration: .history(
                    title: template.headerTitle,
                    onAdd: {
                        template.showingEntrySheet = true
                    },
                    onEdit: template.records.isEmpty ? nil : {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    },
                    isEditMode: isEditMode
                )
            )
            .padding(.horizontal)
            .padding(.top, Spacing.sm.value)
            
            // Search Bar
            UnifiedSearchBar(
                searchText: .init(
                    get: { template.searchViewModel.searchText },
                    set: { template.searchViewModel.searchText = $0 }
                ),
                selectedSort: .init(
                    get: { .dateNewest },
                    set: { _ in }
                ),
                isSearchActive: .init(
                    get: { template.searchViewModel.isSearchActive },
                    set: { template.searchViewModel.isSearchActive = $0 }
                ),
                configuration: template.searchConfiguration,
                onClear: {
                    template.searchViewModel.clearSearch()
                }
            )
            .padding(.horizontal)
            .onChange(of: template.searchViewModel.searchText) { _, _ in
                updateSearchResults()
            }
            .onChange(of: template.searchViewModel.selectedSort) { _, _ in
                updateSearchResults()
            }
            
            // Content
            if currentDisplayRecords.isEmpty {
                if template.searchViewModel.isSearchActive {
                    ContentUnavailableView(
                        "検索結果なし",
                        systemImage: "magnifyingglass",
                        description: Text("「\\(template.searchViewModel.searchText)」に一致する記録が見つかりませんでした")
                    )
                } else {
                    ContentUnavailableView(
                        template.emptyStateTitle,
                        systemImage: template.emptyStateSystemImage,
                        description: Text(template.emptyStateDescription)
                    )
                }
            } else {
                VStack(spacing: Spacing.lg.value) {
                    // Search Results Summary
                    if template.searchViewModel.isSearchActive {
                        BaseCard(style: DefaultCardStyle()) {
                            HStack {
                                Image(systemName: "magnifyingglass.circle.fill")
                                    .foregroundColor(SemanticColor.primaryAction.color)
                                Text("\\(template.searchViewModel.searchResultsCount)件の検索結果")
                                    .font(Typography.bodyMedium.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                Spacer()
                                Text(template.searchViewModel.selectedSort.displayName)
                                    .font(Typography.captionMedium.font)
                                    .foregroundColor(SemanticColor.secondaryText.color)
                            }
                            .padding(Spacing.md.value)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Records List (to be customized by each view)
                    RecordsList(
                        records: currentDisplayRecords,
                        onEdit: { record in
                            template.selectedRecord = record
                            template.showingEditSheet = true
                            HapticManager.shared.trigger(.selection)
                        },
                        onDelete: template.deleteRecord
                    )
                }
            }
            
            // Edit Mode Actions
            if isEditMode && !template.records.isEmpty {
                BaseCard(style: OutlinedCardStyle()) {
                    Button(action: {
                        showingBulkDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(SemanticColor.destructiveAction)
                            Text("一括削除")
                                .font(Typography.labelMedium)
                                .foregroundColor(SemanticColor.destructiveAction)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md.value)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, Spacing.md.value)
            }
        }
        .sheet(isPresented: .init(
            get: { template.showingEntrySheet },
            set: { template.showingEntrySheet = $0 }
        )) {
            template.createEntryView()
        }
        .sheet(isPresented: .init(
            get: { template.showingEditSheet },
            set: { template.showingEditSheet = $0 }
        )) {
            if let record = template.selectedRecord {
                template.createEditSheet(for: record)
            }
        }
        .alert("一括削除", isPresented: $showingBulkDeleteAlert) {
            Button("全て削除", role: .destructive) {
                template.deleteAllRecords()
                isEditMode = false
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("\\(template.records.count)件の記録を全て削除してもよろしいですか？この操作は取り消せません。")
        }
        .onAppear {
            updateSearchResults()
        }
    }
    
    private var currentDisplayRecords: [Template.DataModel] {
        if template.searchViewModel.isSearchActive {
            return template.searchViewModel.filteredRecords
        } else {
            return template.records
        }
    }
    
    private func updateSearchResults() {
        template.searchViewModel.updateRecords(template.records)
        template.searchViewModel.activateSearch()
    }
}

// MARK: - Generic Records List

struct RecordsList<DataModel: Searchable>: View {
    let records: [DataModel]
    let onEdit: (DataModel) -> Void
    let onDelete: (DataModel) -> Void
    
    var body: some View {
        Text("Customize this list for each data model")
            .font(Typography.bodyMedium.font)
            .foregroundColor(SemanticColor.secondaryText.color)
    }
}

// MARK: - Template Implementations

struct FTPHistoryTemplate: HistoryViewTemplate {
    let modelContext: ModelContext
    let records: [FTPHistory]
    let searchViewModel = HistorySearchViewModel<FTPHistory>()
    
    // Configuration
    let headerTitle = "FTP履歴"
    let emptyStateTitle = "FTP記録なし"
    let emptyStateSystemImage = "chart.bar.xaxis.ascending"
    let emptyStateDescription = "ヘッダーの「+」ボタンでFTPを記録しましょう"
    let searchConfiguration = SearchConfiguration.ftpHistory
    
    // Sheet states
    @State var showingEntrySheet = false
    @State var showingEditSheet = false
    @State var selectedRecord: FTPHistory?
    
    func createEntryView() -> some View {
        FTPEntryView()
    }
    
    func createEditSheet(for record: FTPHistory) -> some View {
        FTPEditSheet(ftpRecord: record)
    }
    
    func deleteRecord(_ record: FTPHistory) {
        withAnimation {
            modelContext.delete(record)
            try? modelContext.save()
        }
    }
    
    func deleteAllRecords() {
        withAnimation {
            for record in records {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Additional Template Implementations

struct DailyLogHistoryTemplate: HistoryViewTemplate {
    let modelContext: ModelContext
    let records: [DailyLog]
    let searchViewModel = HistorySearchViewModel<DailyLog>()
    
    // Configuration
    let headerTitle = "食事・体重履歴"
    let emptyStateTitle = "体重記録なし"
    let emptyStateSystemImage = "scalemass"
    let emptyStateDescription = "ヘッダーの「+」ボタンで体重・栄養を記録しましょう"
    let searchConfiguration = SearchConfiguration.dailyLogHistory
    
    // Sheet states
    @State var showingEntrySheet = false
    @State var showingEditSheet = false
    @State var selectedRecord: DailyLog?
    
    func createEntryView() -> some View {
        Text("DailyLog Entry View (to be implemented)")
    }
    
    func createEditSheet(for record: DailyLog) -> some View {
        Text("DailyLog Edit Sheet (to be implemented)")
    }
    
    func deleteRecord(_ record: DailyLog) {
        withAnimation {
            modelContext.delete(record)
            try? modelContext.save()
        }
    }
    
    func deleteAllRecords() {
        withAnimation {
            for record in records {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
}

struct AchievementHistoryTemplate: HistoryViewTemplate {
    let modelContext: ModelContext
    let records: [Achievement]
    let searchViewModel = HistorySearchViewModel<Achievement>()
    
    // Configuration
    let headerTitle = "達成履歴"
    let emptyStateTitle = "達成記録なし"
    let emptyStateSystemImage = "trophy"
    let emptyStateDescription = "達成した目標が表示されます"
    let searchConfiguration = SearchConfiguration.achievementHistory
    
    // Sheet states
    @State var showingEntrySheet = false
    @State var showingEditSheet = false
    @State var selectedRecord: Achievement?
    
    func createEntryView() -> some View {
        Text("Achievement Entry View (to be implemented)")
    }
    
    func createEditSheet(for record: Achievement) -> some View {
        Text("Achievement Edit Sheet (to be implemented)")
    }
    
    func deleteRecord(_ record: Achievement) {
        withAnimation {
            modelContext.delete(record)
            try? modelContext.save()
        }
    }
    
    func deleteAllRecords() {
        withAnimation {
            for record in records {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
}

struct WeeklyReportHistoryTemplate: HistoryViewTemplate {
    let modelContext: ModelContext
    let records: [WeeklyReport]
    let searchViewModel = HistorySearchViewModel<WeeklyReport>()
    
    // Configuration
    let headerTitle = "週次レポート履歴"
    let emptyStateTitle = "週次レポートなし"
    let emptyStateSystemImage = "calendar.badge.clock"
    let emptyStateDescription = "週次レポートが自動生成されます"
    let searchConfiguration = SearchConfiguration.weeklyReportHistory
    
    // Sheet states
    @State var showingEntrySheet = false
    @State var showingEditSheet = false
    @State var selectedRecord: WeeklyReport?
    
    func createEntryView() -> some View {
        Text("WeeklyReport Entry View (to be implemented)")
    }
    
    func createEditSheet(for record: WeeklyReport) -> some View {
        Text("WeeklyReport Edit Sheet (to be implemented)")
    }
    
    func deleteRecord(_ record: WeeklyReport) {
        withAnimation {
            modelContext.delete(record)
            try? modelContext.save()
        }
    }
    
    func deleteAllRecords() {
        withAnimation {
            for record in records {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
}

#Preview {
    Text("History View Template System")
        .font(Typography.headlineLarge.font)
        .foregroundColor(SemanticColor.primaryText.color)
}