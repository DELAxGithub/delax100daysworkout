import SwiftUI

// MARK: - Header Configuration

struct UnifiedHeaderConfiguration {
    let title: String
    let subtitle: String?
    let backAction: (() -> Void)?
    let primaryAction: HeaderAction?
    let secondaryAction: HeaderAction?
    let style: HeaderStyle
    let accessibility: HeaderAccessibility
    
    init(
        title: String,
        subtitle: String? = nil,
        backAction: (() -> Void)? = nil,
        primaryAction: HeaderAction? = nil,
        secondaryAction: HeaderAction? = nil,
        style: HeaderStyle = .default,
        accessibility: HeaderAccessibility = .default
    ) {
        self.title = title
        self.subtitle = subtitle
        self.backAction = backAction
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.style = style
        self.accessibility = accessibility
    }
}

// MARK: - Header Action

struct HeaderAction {
    let icon: String
    let label: String
    let action: () -> Void
    let style: HeaderActionStyle
    let isEnabled: Bool
    
    init(
        icon: String,
        label: String,
        action: @escaping () -> Void,
        style: HeaderActionStyle = .primary,
        isEnabled: Bool = true
    ) {
        self.icon = icon
        self.label = label
        self.action = action
        self.style = style
        self.isEnabled = isEnabled
    }
}

enum HeaderActionStyle {
    case primary
    case secondary
    case destructive
    
    var foregroundColor: SemanticColor {
        switch self {
        case .primary:
            return .primaryAction
        case .secondary:
            return .secondaryText
        case .destructive:
            return .destructiveAction
        }
    }
}

// MARK: - Header Style

enum HeaderStyle {
    case `default`
    case prominent
    case compact
    
    var titleFont: Typography {
        switch self {
        case .default:
            return .headlineLarge
        case .prominent:
            return .displaySmall
        case .compact:
            return .headlineMedium
        }
    }
    
    var subtitleFont: Typography {
        return .captionMedium
    }
    
    var padding: Spacing {
        switch self {
        case .default:
            return .md
        case .prominent:
            return .lg
        case .compact:
            return .sm
        }
    }
}

// MARK: - Header Accessibility

struct HeaderAccessibility {
    let titleHint: String?
    let backButtonLabel: String
    let customTraits: AccessibilityTraits?
    
    init(
        titleHint: String? = nil,
        backButtonLabel: String = "戻る",
        customTraits: AccessibilityTraits? = nil
    ) {
        self.titleHint = titleHint
        self.backButtonLabel = backButtonLabel
        self.customTraits = customTraits
    }
    
    static let `default` = HeaderAccessibility()
}

// MARK: - Unified Header Component

struct UnifiedHeaderComponent: View {
    let configuration: UnifiedHeaderConfiguration
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss
    
    init(configuration: UnifiedHeaderConfiguration) {
        self.configuration = configuration
    }
    
    // Convenience initializer
    init(
        title: String,
        subtitle: String? = nil,
        onBack: (() -> Void)? = nil,
        primaryAction: HeaderAction? = nil,
        secondaryAction: HeaderAction? = nil,
        style: HeaderStyle = .default
    ) {
        self.configuration = UnifiedHeaderConfiguration(
            title: title,
            subtitle: subtitle,
            backAction: onBack,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            style: style
        )
    }
    
    var body: some View {
        BaseCard(style: OutlinedCardStyle()) {
            HStack(spacing: Spacing.md.value) {
                // Back Button
                if let backAction = configuration.backAction {
                    Button(action: {
                        HapticManager.shared.trigger(.impact(.light))
                        backAction()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(SemanticColor.primaryAction)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(SemanticColor.surfaceBackground.color))
                    }
                    .accessibilityLabel(configuration.accessibility.backButtonLabel)
                    .accessibilityHint("前の画面に戻ります")
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Placeholder for alignment
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                
                // Title Section
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    Text(configuration.title)
                        .font(configuration.style.titleFont)
                        .foregroundColor(SemanticColor.primaryText)
                        .lineLimit(1)
                        .accessibilityLabel(configuration.title)
                        .accessibilityHint(configuration.accessibility.titleHint ?? "")
                        .accessibilityAddTraits(configuration.accessibility.customTraits ?? [])
                    
                    if let subtitle = configuration.subtitle {
                        Text(subtitle)
                            .font(configuration.style.subtitleFont)
                            .foregroundColor(SemanticColor.secondaryText)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Action Buttons
                HStack(spacing: Spacing.sm.value) {
                    // Secondary Action
                    if let secondaryAction = configuration.secondaryAction {
                        HeaderActionButton(action: secondaryAction)
                    }
                    
                    // Primary Action
                    if let primaryAction = configuration.primaryAction {
                        HeaderActionButton(action: primaryAction)
                    }
                    
                    // Placeholder if no actions
                    if configuration.primaryAction == nil && configuration.secondaryAction == nil {
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(configuration.style.padding)
        }
    }
}

// MARK: - Header Action Button

private struct HeaderActionButton: View {
    let action: HeaderAction
    
    var body: some View {
        Button(action: {
            HapticManager.shared.trigger(.impact(.light))
            action.action()
        }) {
            Image(systemName: action.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(action.isEnabled ? action.style.foregroundColor : SemanticColor.disabledText)
                .frame(width: 44, height: 44)
                .background(Circle().fill(SemanticColor.surfaceBackground.color))
        }
        .disabled(!action.isEnabled)
        .accessibilityLabel(action.label)
        .accessibilityHint(action.isEnabled ? "\(action.label)を実行します" : "\(action.label)は現在利用できません")
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Predefined Header Configurations

extension UnifiedHeaderConfiguration {
    // History View Header
    static func history(
        title: String,
        onAdd: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
        isEditMode: Bool = false
    ) -> UnifiedHeaderConfiguration {
        let editAction = onEdit.map { editAction in
            HeaderAction(
                icon: isEditMode ? "checkmark" : "pencil",
                label: isEditMode ? "完了" : "編集",
                action: editAction
            )
        }
        
        let addAction = HeaderAction(
            icon: "plus",
            label: "追加",
            action: onAdd
        )
        
        return UnifiedHeaderConfiguration(
            title: title,
            primaryAction: addAction,
            secondaryAction: editAction
        )
    }
    
    // Settings Header
    static func settings(
        title: String,
        onDone: @escaping () -> Void
    ) -> UnifiedHeaderConfiguration {
        UnifiedHeaderConfiguration(
            title: title,
            primaryAction: HeaderAction(
                icon: "checkmark",
                label: "完了",
                action: onDone
            )
        )
    }
    
    // Detail View Header
    static func detail(
        title: String,
        subtitle: String? = nil,
        onBack: @escaping () -> Void,
        onAction: (() -> Void)? = nil,
        actionIcon: String = "ellipsis.circle"
    ) -> UnifiedHeaderConfiguration {
        let action = onAction.map { actionHandler in
            HeaderAction(
                icon: actionIcon,
                label: "その他",
                action: actionHandler
            )
        }
        
        return UnifiedHeaderConfiguration(
            title: title,
            subtitle: subtitle,
            backAction: onBack,
            primaryAction: action
        )
    }
}

// MARK: - Preview

#Preview("UnifiedHeader Examples") {
    ScrollView {
        VStack(spacing: Spacing.lg.value) {
            // History Header
            UnifiedHeaderComponent(
                configuration: .history(
                    title: "FTP履歴",
                    onAdd: { print("Add tapped") },
                    onEdit: { print("Edit tapped") }
                )
            )
            
            // Settings Header
            UnifiedHeaderComponent(
                configuration: .settings(
                    title: "設定",
                    onDone: { print("Done tapped") }
                )
            )
            
            // Detail Header
            UnifiedHeaderComponent(
                configuration: .detail(
                    title: "ワークアウト詳細",
                    subtitle: "2025年8月13日",
                    onBack: { print("Back tapped") },
                    onAction: { print("Action tapped") }
                )
            )
            
            // Custom Header
            UnifiedHeaderComponent(
                title: "カスタムヘッダー",
                subtitle: "サブタイトル付き",
                primaryAction: HeaderAction(
                    icon: "heart",
                    label: "お気に入り",
                    action: { print("Favorite tapped") }
                ),
                style: .prominent
            )
        }
        .padding()
    }
    .background(SemanticColor.primaryBackground.color)
}