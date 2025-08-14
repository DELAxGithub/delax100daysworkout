import SwiftUI

// MARK: - Data Management List View

struct DataManagementListView: View {
    let queries: DataManagementQueries
    let viewModel: DataManagementViewModel
    let onEdit: (EditableModel) -> Void
    let onDelete: (EditableModel) -> Void
    let onDeleteAll: () -> Void
    let onGenerateDemo: () -> Void
    
    var body: some View {
        List {
            DatabaseOverviewSection(totalCount: viewModel.getTotalDataCount(queries: queries))
            
            DataTypesSection(
                queries: queries,
                viewModel: viewModel,
                onEdit: onEdit,
                onDelete: onDelete
            )
            
            DataManagementDemoSection(onGenerateDemo: onGenerateDemo)
            
            DangerousOperationsSection(
                totalCount: viewModel.getTotalDataCount(queries: queries),
                onDeleteAll: onDeleteAll
            )
        }
    }
}

// MARK: - Database Overview Section

struct DatabaseOverviewSection: View {
    let totalCount: Int
    
    var body: some View {
        Section {
            BaseCard(style: ElevatedCardStyle()) {
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    Text("データベース概要")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Text("総データ数: \(totalCount) 件")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.secondaryText)
                    
                    if totalCount > 0 {
                        Text("全てのデータを削除すると、アプリの状態が初期化されます。")
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.warningAction)
                    }
                }
            }
            .padding(.vertical, Spacing.xs.value)
        }
    }
}

// MARK: - Data Types Section

struct DataTypesSection: View {
    let queries: DataManagementQueries
    let viewModel: DataManagementViewModel
    let onEdit: (EditableModel) -> Void
    let onDelete: (EditableModel) -> Void
    
    var body: some View {
        Section("データ種別") {
            ForEach(EditableModel.allCases, id: \.rawValue) { model in
                CRUDDataTypeRow(
                    model: model,
                    count: viewModel.getModelCount(model, queries: queries),
                    editAction: { onEdit(model) },
                    deleteAction: { onDelete(model) }
                )
            }
        }
    }
}

// MARK: - Data Management Demo Section

struct DataManagementDemoSection: View {
    let onGenerateDemo: () -> Void
    
    var body: some View {
        Section("デモデータ管理") {
            BaseCard(style: DefaultCardStyle()) {
                Button(action: onGenerateDemo) {
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
    }
}

// MARK: - Dangerous Operations Section

struct DangerousOperationsSection: View {
    let totalCount: Int
    let onDeleteAll: () -> Void
    
    var body: some View {
        Section("危険な操作") {
            Button(action: onDeleteAll) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("全データを削除")
                    Spacer()
                    Text("\(totalCount) 件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.red)
            .disabled(totalCount == 0)
        }
    }
}