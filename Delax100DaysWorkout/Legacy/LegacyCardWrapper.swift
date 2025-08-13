import SwiftUI

// MARK: - Legacy Card Wrapper

struct LegacyCardWrapper<Content: View>: View {
    @ViewBuilder let content: Content
    let migrationMetadata: MigrationMetadata
    
    init(@ViewBuilder content: () -> Content, migrationMetadata: MigrationMetadata) {
        self.content = content()
        self.migrationMetadata = migrationMetadata
    }
    
    var body: some View {
        BaseCard(
            style: migrationMetadata.suggestedStyle,
            accessibility: migrationMetadata.accessibilityConfig
        ) {
            VStack(spacing: 0) {
                // Migration notice (only in debug)
                #if DEBUG
                if migrationMetadata.showMigrationNotice {
                    MigrationNotice(metadata: migrationMetadata)
                }
                #endif
                
                content
            }
        }
        .trackCardUsage(migrationMetadata.legacyCardType, action: .appeared)
    }
}

// MARK: - Migration Metadata

struct MigrationMetadata {
    let legacyCardType: String
    let suggestedStyle: CardStyling
    let accessibilityConfig: CardAccessibilityConfiguration
    let migrationStatus: MigrationStatus
    let showMigrationNotice: Bool
    
    init(
        legacyCardType: String,
        suggestedStyle: CardStyling = DefaultCardStyle(),
        accessibilityConfig: CardAccessibilityConfiguration = CardAccessibility(),
        migrationStatus: MigrationStatus = .pending,
        showMigrationNotice: Bool = false
    ) {
        self.legacyCardType = legacyCardType
        self.suggestedStyle = suggestedStyle
        self.accessibilityConfig = accessibilityConfig
        self.migrationStatus = migrationStatus
        self.showMigrationNotice = showMigrationNotice
    }
}

enum MigrationStatus {
    case pending
    case inProgress
    case completed
    case deprecated
}

// MARK: - Migration Notice

struct MigrationNotice: View {
    let metadata: MigrationMetadata
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.caption)
            
            Text("Legacy: \(metadata.legacyCardType)")
                .font(.caption2)
                .foregroundColor(statusColor)
            
            Spacer()
            
            Text(metadata.migrationStatus.displayName)
                .font(.caption2)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, Spacing.xs.value)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var statusIcon: String {
        switch metadata.migrationStatus {
        case .pending: return "clock"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle"
        case .deprecated: return "exclamationmark.triangle"
        }
    }
    
    private var statusColor: Color {
        switch metadata.migrationStatus {
        case .pending: return SemanticColor.warningAction.color
        case .inProgress: return SemanticColor.primaryAction.color
        case .completed: return SemanticColor.successAction.color
        case .deprecated: return SemanticColor.errorAction.color
        }
    }
}

extension MigrationStatus {
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "Migrating"
        case .completed: return "Migrated"
        case .deprecated: return "Deprecated"
        }
    }
}

// MARK: - Legacy Card Types

extension LegacyCardWrapper {
    // WorkoutCardView wrapper
    static func workoutCard<T: View>(
        @ViewBuilder content: @escaping () -> T
    ) -> LegacyCardWrapper<T> {
        LegacyCardWrapper<T>(
            content: content,
            migrationMetadata: MigrationMetadata(
                legacyCardType: "WorkoutCardView",
                suggestedStyle: DefaultCardStyle(),
                accessibilityConfig: CardAccessibility(
                    label: "Workout card",
                    hint: "Tap for workout details"
                ),
                migrationStatus: .completed
            )
        )
    }
    
    // TaskCardView wrapper
    static func taskCard<T: View>(
        @ViewBuilder content: @escaping () -> T
    ) -> LegacyCardWrapper<T> {
        LegacyCardWrapper<T>(
            content: content,
            migrationMetadata: MigrationMetadata(
                legacyCardType: "TaskCardView",
                suggestedStyle: DefaultCardStyle(),
                accessibilityConfig: CardAccessibility(
                    label: "Task card",
                    hint: "Tap to complete, long press for details"
                ),
                migrationStatus: .completed
            )
        )
    }
    
    // EditableWorkoutCardView wrapper
    static func editableWorkoutCard<T: View>(
        @ViewBuilder content: @escaping () -> T
    ) -> LegacyCardWrapper<T> {
        LegacyCardWrapper<T>(
            content: content,
            migrationMetadata: MigrationMetadata(
                legacyCardType: "EditableWorkoutCardView",
                suggestedStyle: DefaultCardStyle(),
                accessibilityConfig: CardAccessibility(
                    label: "Editable workout card",
                    hint: "Swipe left to delete, long press to edit"
                ),
                migrationStatus: .inProgress,
                showMigrationNotice: true
            )
        )
    }
}

// MARK: - Migration Extensions for Existing Cards

extension WorkoutCardView {
    @ViewBuilder
    static func migrated(
        workoutType: WorkoutType,
        title: String,
        summary: String
    ) -> some View {
        BaseCard(onTap: {}) {
            HStack(spacing: Spacing.md.value) {
                Image(systemName: workoutType.iconName)
                    .font(Typography.headlineLarge.font)
                    .foregroundColor(SemanticColor.primaryAction.color)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    Text(summary)
                        .font(Typography.bodySmall.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                }
                Spacer()
            }
        }
        .trackCardUsage("WorkoutCard", action: .appeared)
    }
}

// MARK: - Migration Utility

@MainActor
class MigrationManager: ObservableObject {
    static let shared = MigrationManager()
    
    @Published var migrationProgress: [String: MigrationStatus] = [:]
    @Published var showMigrationWarnings = false
    
    private init() {
        initializeMigrationStatus()
    }
    
    private func initializeMigrationStatus() {
        migrationProgress = [
            "WorkoutCardView": .completed,
            "TaskCardView": .completed,
            "EditableWorkoutCardView": .inProgress,
            "SummaryCard": .completed,
            "SectionCard": .completed,
            "StatView": .completed,
            "QuickActionButton": .completed
        ]
    }
    
    func markAsCompleted(_ cardType: String) {
        migrationProgress[cardType] = .completed
    }
    
    func markAsDeprecated(_ cardType: String) {
        migrationProgress[cardType] = .deprecated
    }
    
    func getMigrationReport() -> MigrationReport {
        let total = migrationProgress.count
        let completed = migrationProgress.values.filter { $0 == .completed }.count
        let inProgress = migrationProgress.values.filter { $0 == .inProgress }.count
        let pending = migrationProgress.values.filter { $0 == .pending }.count
        let deprecated = migrationProgress.values.filter { $0 == .deprecated }.count
        
        return MigrationReport(
            totalComponents: total,
            completed: completed,
            inProgress: inProgress,
            pending: pending,
            deprecated: deprecated,
            completionPercentage: Double(completed) / Double(total) * 100
        )
    }
}

struct MigrationReport {
    let totalComponents: Int
    let completed: Int
    let inProgress: Int
    let pending: Int
    let deprecated: Int
    let completionPercentage: Double
    
    var isComplete: Bool {
        pending == 0 && inProgress == 0
    }
}