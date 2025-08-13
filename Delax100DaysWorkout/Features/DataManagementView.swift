import SwiftUI
import SwiftData

enum EditableModel: String, CaseIterable {
    case workoutRecords = "WorkoutRecords"
    case ftpHistory = "FTPHistory"
    case dailyMetrics = "DailyMetrics"
    case dailyTasks = "DailyTasks"
    case weeklyTemplates = "WeeklyTemplates"
    case userProfiles = "UserProfiles"
    
    var displayName: String {
        switch self {
        case .workoutRecords: return "ワークアウト記録"
        case .ftpHistory: return "FTP記録"
        case .dailyMetrics: return "体重・メトリクス"
        case .dailyTasks: return "タスク記録"
        case .weeklyTemplates: return "週間テンプレート"
        case .userProfiles: return "ユーザープロファイル"
        }
    }
    
    var iconName: String {
        switch self {
        case .workoutRecords: return "figure.run"
        case .ftpHistory: return "bolt.fill"
        case .dailyMetrics: return "scalemass.fill"
        case .dailyTasks: return "checkmark.circle.fill"
        case .weeklyTemplates: return "calendar"
        case .userProfiles: return "person.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .workoutRecords: return .green
        case .ftpHistory: return .blue
        case .dailyMetrics: return .orange
        case .dailyTasks: return .purple
        case .weeklyTemplates: return .indigo
        case .userProfiles: return .pink
        }
    }
}

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var workoutRecords: [WorkoutRecord]
    @Query private var ftpHistory: [FTPHistory]
    @Query private var dailyMetrics: [DailyMetric]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyTemplates: [WeeklyTemplate]
    @Query private var userProfiles: [UserProfile]
    
    @State private var showingResetAlert = false
    @State private var showingWorkoutDeleteAlert = false
    @State private var showingFTPDeleteAlert = false
    @State private var showingMetricsDeleteAlert = false
    @State private var showingTasksDeleteAlert = false
    @State private var showingTemplatesDeleteAlert = false
    @State private var showingProfileDeleteAlert = false
    
    @State private var showingDemoDataOptions = false
    @State private var selectedEditModel: EditableModel?
    
    var totalDataCount: Int {
        workoutRecords.count + ftpHistory.count + validDailyMetrics.count + dailyTasks.count + weeklyTemplates.count + userProfiles.count
    }
    
    var validDailyMetrics: [DailyMetric] {
        dailyMetrics.filter { $0.hasAnyData }
    }
    
    // MARK: - CRUD Engine Helper Methods
    
    private func getModelCount(_ model: EditableModel) -> Int {
        switch model {
        case .workoutRecords: return workoutRecords.count
        case .ftpHistory: return ftpHistory.count
        case .dailyMetrics: return validDailyMetrics.count
        case .dailyTasks: return dailyTasks.count
        case .weeklyTemplates: return weeklyTemplates.count
        case .userProfiles: return userProfiles.count
        }
    }
    
    private func showDeleteAlert(for model: EditableModel) {
        switch model {
        case .workoutRecords: showingWorkoutDeleteAlert = true
        case .ftpHistory: showingFTPDeleteAlert = true
        case .dailyMetrics: showingMetricsDeleteAlert = true
        case .dailyTasks: showingTasksDeleteAlert = true
        case .weeklyTemplates: showingTemplatesDeleteAlert = true
        case .userProfiles: showingProfileDeleteAlert = true
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    BaseCard(style: ElevatedCardStyle()) {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            Text("データベース概要")
                                .font(Typography.headlineMedium.font)
                                .foregroundColor(SemanticColor.primaryText)
                            
                            Text("総データ数: \(totalDataCount) 件")
                                .font(Typography.bodyMedium.font)
                                .foregroundColor(SemanticColor.secondaryText)
                            
                            if totalDataCount > 0 {
                                Text("全てのデータを削除すると、アプリの状態が初期化されます。")
                                    .font(Typography.captionMedium.font)
                                    .foregroundColor(SemanticColor.warningAction)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs.value)
                }
                
                Section("データ種別") {
                    // Enhanced CRUD Engine Integration
                    ForEach(EditableModel.allCases, id: \.rawValue) { model in
                        CRUDDataTypeRow(
                            model: model,
                            count: getModelCount(model),
                            editAction: { selectedEditModel = model },
                            deleteAction: { showDeleteAlert(for: model) }
                        )
                    }
                }
                
                Section("デモデータ管理") {
                    BaseCard(style: DefaultCardStyle()) {
                        Button(action: {
                            showingDemoDataOptions = true
                        }) {
                            HStack {
                                Image(systemName: "theatermasks")
                                    .foregroundColor(.blue)
                                    .font(Typography.headlineMedium.font)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                                    Text("デモデータ管理")
                                        .font(Typography.bodyMedium.font)
                                        .foregroundColor(SemanticColor.primaryText)
                                    
                                    Text("デモデータの生成・削除・リセット")
                                        .font(Typography.captionMedium.font)
                                        .foregroundColor(SemanticColor.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(SemanticColor.secondaryText)
                                    .font(Typography.captionMedium.font)
                            }
                        }
                    }
                }
                
                Section("危険な操作") {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("全データを削除")
                            Spacer()
                            Text("\(totalDataCount) 件")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.red)
                    .disabled(totalDataCount == 0)
                }
            }
            .navigationTitle("データ管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("全データ削除", isPresented: $showingResetAlert) {
                TextField("削除を確認するために「削除」と入力", text: .constant(""))
                Button("削除", role: .destructive) {
                    deleteAllData()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての記録データ（\(totalDataCount)件）が完全に削除されます。この操作は取り消せません。\n\n本当に実行しますか？")
            }
            .alert("ワークアウト記録削除", isPresented: $showingWorkoutDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteWorkoutRecords()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのワークアウト記録（\(workoutRecords.count)件）を削除してもよろしいですか？")
            }
            .alert("FTP記録削除", isPresented: $showingFTPDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteFTPHistory()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのFTP記録（\(ftpHistory.count)件）を削除してもよろしいですか？")
            }
            .alert("メトリクス削除", isPresented: $showingMetricsDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteDailyMetrics()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての体重・メトリクス記録（\(validDailyMetrics.count)件）を削除してもよろしいですか？")
            }
            .alert("タスク記録削除", isPresented: $showingTasksDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteDailyTasks()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのタスク記録（\(dailyTasks.count)件）を削除してもよろしいですか？")
            }
            .alert("テンプレート削除", isPresented: $showingTemplatesDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteWeeklyTemplates()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての週間テンプレート（\(weeklyTemplates.count)件）を削除してもよろしいですか？")
            }
            .alert("プロファイル削除", isPresented: $showingProfileDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteUserProfiles()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全てのユーザープロファイル（\(userProfiles.count)件）を削除してもよろしいですか？")
            }
            .sheet(item: $selectedEditModel) { model in
                NavigationStack {
                    GenericCRUDModelView(editableModel: model)
                        .environment(\.modelContext, modelContext)
                }
            }
            .alert("デモデータ生成", isPresented: $showingDemoDataOptions) {
                Button("生成") {
                    DemoDataManager.generateJuly2025DemoData(modelContext: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("July 2025のリアルなデモデータを生成しますか？")
            }
        }
    }
    
    // MARK: - Delete Methods
    
    private func deleteAllData() {
        withAnimation {
            // 全てのデータタイプを削除
            for record in workoutRecords {
                modelContext.delete(record)
            }
            for record in ftpHistory {
                modelContext.delete(record)
            }
            for record in dailyMetrics {
                modelContext.delete(record)
            }
            for record in dailyTasks {
                modelContext.delete(record)
            }
            for record in weeklyTemplates {
                modelContext.delete(record)
            }
            for record in userProfiles {
                modelContext.delete(record)
            }
            
            try? modelContext.save()
        }
    }
    
    private func deleteWorkoutRecords() {
        withAnimation {
            for record in workoutRecords {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteFTPHistory() {
        withAnimation {
            for record in ftpHistory {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteDailyMetrics() {
        withAnimation {
            // 実際にデータがあるメトリクスのみを削除
            for record in validDailyMetrics {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteDailyTasks() {
        withAnimation {
            for record in dailyTasks {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteWeeklyTemplates() {
        withAnimation {
            for record in weeklyTemplates {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func deleteUserProfiles() {
        withAnimation {
            for record in userProfiles {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
}

struct DataTypeRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            BaseCard(style: DefaultCardStyle()) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(Typography.headlineMedium.font)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs.value) {
                        Text(title)
                            .font(Typography.bodyMedium.font)
                            .foregroundColor(SemanticColor.primaryText)
                        
                        Text("\(count) 件")
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    if count > 0 {
                        Image(systemName: "trash")
                            .foregroundColor(SemanticColor.errorAction)
                            .font(Typography.captionMedium.font)
                    } else {
                        Text("データなし")
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText)
                    }
                }
            }
        }
        .disabled(count == 0)
    }
}

// MARK: - CRUD Data Type Row

struct CRUDDataTypeRow: View {
    let model: EditableModel
    let count: Int
    let editAction: () -> Void
    let deleteAction: () -> Void
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            HStack {
                Image(systemName: model.iconName)
                    .foregroundColor(model.color)
                    .font(Typography.headlineMedium.font)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    Text(model.displayName)
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Text("\(count) 件")
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                }
                
                Spacer()
                
                if count > 0 {
                    Button(action: editAction) {
                        Image(systemName: "pencil")
                            .foregroundColor(SemanticColor.primaryAction)
                            .font(Typography.bodyMedium.font)
                    }
                    .padding(.trailing, Spacing.sm.value)
                    
                    Button(action: deleteAction) {
                        Image(systemName: "trash")
                            .foregroundColor(SemanticColor.errorAction)
                            .font(Typography.bodyMedium.font)
                    }
                } else {
                    Text("データなし")
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                }
            }
            .padding(Spacing.md.value)
        }
    }
}

// MARK: - Enhanced Data Type Row (Legacy)

struct EnhancedDataTypeRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let editAction: () -> Void
    let deleteAction: () -> Void
    
    var body: some View {
        BaseCard(style: DefaultCardStyle()) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(Typography.headlineMedium.font)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    Text(title)
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Text("\(count) 件")
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                }
                
                Spacer()
                
                if count > 0 {
                    Button(action: editAction) {
                        Image(systemName: "pencil")
                            .foregroundColor(SemanticColor.primaryAction)
                            .font(Typography.bodyMedium.font)
                    }
                    .padding(.trailing, Spacing.sm.value)
                    
                    Button(action: deleteAction) {
                        Image(systemName: "trash")
                            .foregroundColor(SemanticColor.errorAction)
                            .font(Typography.bodyMedium.font)
                    }
                } else {
                    Text("データなし")
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                }
            }
            .padding(Spacing.md.value)
        }
    }
}

// MARK: - Simple Record List View

struct SimpleRecordListView: View {
    let modelType: EditableModel
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecord: Any?
    
    var body: some View {
        List {
            switch modelType {
            case .ftpHistory:
                let records = (try? modelContext.fetch(FetchDescriptor<FTPHistory>())) ?? []
                ForEach(records, id: \.id) { record in
                    NavigationLink(destination: FTPEditSheet(ftpRecord: record)) {
                        VStack(alignment: .leading) {
                            Text("\(record.ftpValue) W")
                            Text(record.formattedDate).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            case .dailyMetrics:
                let records = (try? modelContext.fetch(FetchDescriptor<DailyMetric>())) ?? []
                ForEach(records.filter { $0.hasAnyData }, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text(record.formattedWeight ?? "No weight")
                        Text(record.formattedDate).font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    let validRecords = records.filter { $0.hasAnyData }
                    for index in indexSet {
                        modelContext.delete(validRecords[index])
                    }
                    try? modelContext.save()
                }
            case .workoutRecords:
                let records = (try? modelContext.fetch(FetchDescriptor<WorkoutRecord>())) ?? []
                ForEach(records, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text(record.summary)
                        Text(record.workoutType.rawValue).font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            case .dailyTasks:
                let records = (try? modelContext.fetch(FetchDescriptor<DailyTask>())) ?? []
                ForEach(records, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text(record.title)
                        Text(record.dayName).font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            case .weeklyTemplates:
                let records = (try? modelContext.fetch(FetchDescriptor<WeeklyTemplate>())) ?? []
                ForEach(records, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text(record.name)
                        Text("\(record.dailyTasks.count) tasks").font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            case .userProfiles:
                let records = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
                ForEach(records, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text("Profile")
                        Text("Goal: \(record.goalWeightKg)kg").font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            }
        }
        .navigationTitle(modelType.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
    }
}

extension EditableModel: Identifiable {
    var id: String { rawValue }
}

// MARK: - Generic CRUD Model View Wrapper

struct GenericCRUDModelView: View {
    let editableModel: EditableModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            switch editableModel {
            case .workoutRecords:
                GenericCRUDView(
                    modelType: WorkoutRecord.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .ftpHistory:
                GenericCRUDView(
                    modelType: FTPHistory.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .dailyMetrics:
                GenericCRUDView(
                    modelType: DailyMetric.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .dailyTasks:
                GenericCRUDView(
                    modelType: DailyTask.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .weeklyTemplates:
                GenericCRUDView(
                    modelType: WeeklyTemplate.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            case .userProfiles:
                GenericCRUDView(
                    modelType: UserProfile.self,
                    displayName: editableModel.displayName,
                    icon: editableModel.iconName,
                    color: editableModel.color
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
    }
}

#Preview {
    DataManagementView()
        .modelContainer(for: [WorkoutRecord.self, FTPHistory.self, DailyMetric.self, DailyTask.self, WeeklyTemplate.self, UserProfile.self])
}