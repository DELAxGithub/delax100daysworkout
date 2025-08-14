import SwiftUI

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

// MARK: - Legacy Data Type Row

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