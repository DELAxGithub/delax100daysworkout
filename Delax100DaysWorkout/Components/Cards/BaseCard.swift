import SwiftUI
import OSLog

// MARK: - BaseCard (Simplified)

struct BaseCard<Content: View>: View {
    let configuration: CardConfiguration
    @ViewBuilder let content: Content
    
    // MARK: - Initializers
    
    init(
        configuration: CardConfiguration = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.configuration = configuration
        self.content = content()
    }
    
    // Convenience initializer
    init(
        style: CardStyling = DefaultCardStyle(),
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        accessibility: CardAccessibilityConfiguration = CardAccessibility(),
        @ViewBuilder content: () -> Content
    ) {
        self.configuration = CardConfiguration(
            style: style,
            interaction: CardInteraction(onTap: onTap, onLongPress: onLongPress),
            accessibility: accessibility
        )
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        CardContainer(configuration: configuration) {
            content
        }
        .modifier(LoadingStateModifier(
            isLoading: configuration.loading.isLoading,
            loadingConfiguration: configuration.loading,
            cardStyle: configuration.style
        ))
    }
}

// MARK: - Predefined Card Types

extension BaseCard {
    // Workout Card
    static func workout<T: View>(
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> T
    ) -> BaseCard<T> {
        BaseCard<T>(
            configuration: .tappable(action: onTap ?? {}),
            content: content
        )
    }
    
    // Task Card
    static func task<T: View>(
        isCompleted: Bool = false,
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> T
    ) -> BaseCard<T> {
        BaseCard<T>(
            configuration: .editable(
                onTap: onTap ?? {},
                onLongPress: onLongPress ?? {}
            ),
            content: content
        )
    }
    
    // Summary Card
    static func summary<T: View>(
        @ViewBuilder content: @escaping () -> T
    ) -> BaseCard<T> {
        BaseCard<T>(
            style: ElevatedCardStyle(),
            content: content
        )
    }
    
    // Selectable Card
    static func selectable<T: View>(
        isSelected: Bool,
        onTap: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> T
    ) -> BaseCard<T> {
        BaseCard<T>(
            configuration: .selectable(isSelected: isSelected),
            content: content
        )
    }
}

// MARK: - Preview

#Preview("BaseCard Examples") {
    ScrollView {
        VStack(spacing: Spacing.md.value) {
            // Default Card
            BaseCard {
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    Text("デフォルトカード")
                        .font(Typography.headlineMedium.font)
                    Text("標準的なカードスタイルです。")
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                }
            }
            
            // Tappable Card
            BaseCard(onTap: { Logger.debug.debug("Workout tapped") }) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("筋力トレーニング")
                            .font(Typography.headlineMedium.font)
                        Text("タップ可能なワークアウトカード")
                            .font(Typography.bodySmall.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                    }
                    
                    Spacer()
                }
            }
            
            // Loading Card
            BaseCard(configuration: .loading) {
                Text("読み込み中のコンテンツ")
            }
        }
        .padding()
    }
    .background(SemanticColor.primaryBackground.color)
}