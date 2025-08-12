import SwiftUI

// MARK: - Card Styling Protocol

protocol CardStyling {
    var backgroundColor: SemanticColor { get }
    var cornerRadius: CornerRadius { get }
    var padding: Spacing { get }
    var shadow: ShadowStyle { get }
    var borderColor: SemanticColor? { get }
    var borderWidth: CGFloat { get }
}

// MARK: - Default Card Styles

struct DefaultCardStyle: CardStyling {
    let backgroundColor: SemanticColor = .cardBackground
    let cornerRadius: CornerRadius = .large
    let padding: Spacing = .cardPadding
    let shadow: ShadowStyle = .medium
    let borderColor: SemanticColor? = nil
    let borderWidth: CGFloat = 0
}

struct ElevatedCardStyle: CardStyling {
    let backgroundColor: SemanticColor = .cardBackground
    let cornerRadius: CornerRadius = .large
    let padding: Spacing = .cardPadding
    let shadow: ShadowStyle = .large
    let borderColor: SemanticColor? = nil
    let borderWidth: CGFloat = 0
}

struct OutlinedCardStyle: CardStyling {
    let backgroundColor: SemanticColor = .primaryBackground
    let cornerRadius: CornerRadius = .large
    let padding: Spacing = .cardPadding
    let shadow: ShadowStyle = .none
    let borderColor: SemanticColor? = .primaryBorder
    let borderWidth: CGFloat = 1
}

struct SelectableCardStyle: CardStyling {
    let isSelected: Bool
    
    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }
    
    var backgroundColor: SemanticColor {
        isSelected ? .selectedBackground : .cardBackground
    }
    
    let cornerRadius: CornerRadius = .large
    let padding: Spacing = .cardPadding
    
    var shadow: ShadowStyle {
        isSelected ? .large : .medium
    }
    
    var borderColor: SemanticColor? {
        isSelected ? .focusBorder : nil
    }
    
    var borderWidth: CGFloat {
        isSelected ? 2 : 0
    }
}

// MARK: - Interaction Protocol

protocol CardInteractionHandling {
    var onTap: (() -> Void)? { get }
    var onLongPress: (() -> Void)? { get }
    var onSwipeLeft: (() -> Void)? { get }
    var onSwipeRight: (() -> Void)? { get }
    var isDisabled: Bool { get }
}

struct CardInteraction: CardInteractionHandling {
    let onTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    let onSwipeLeft: (() -> Void)?
    let onSwipeRight: (() -> Void)?
    let isDisabled: Bool
    
    init(
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        isDisabled: Bool = false
    ) {
        self.onTap = onTap
        self.onLongPress = onLongPress
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.isDisabled = isDisabled
    }
}

// MARK: - Accessibility Protocol

protocol CardAccessibilityConfiguration {
    var label: String? { get }
    var hint: String? { get }
    var value: String? { get }
    var traits: AccessibilityTraits { get }
    var isAccessibilityElement: Bool { get }
}

struct CardAccessibility: CardAccessibilityConfiguration {
    let label: String?
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits
    let isAccessibilityElement: Bool
    
    init(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [.isButton],
        isAccessibilityElement: Bool = true
    ) {
        self.label = label
        self.hint = hint
        self.value = value
        self.traits = traits
        self.isAccessibilityElement = isAccessibilityElement
    }
}

// MARK: - Animation Protocol

protocol CardAnimationConfiguration {
    var pressedScale: CGFloat { get }
    var animationDuration: Double { get }
    var hapticFeedback: HapticFeedbackType? { get }
}

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
}

struct CardAnimation: CardAnimationConfiguration {
    let pressedScale: CGFloat
    let animationDuration: Double
    let hapticFeedback: HapticFeedbackType?
    
    init(
        pressedScale: CGFloat = 0.96,
        animationDuration: Double = 0.15,
        hapticFeedback: HapticFeedbackType? = .light
    ) {
        self.pressedScale = pressedScale
        self.animationDuration = animationDuration
        self.hapticFeedback = hapticFeedback
    }
}

// MARK: - Loading State Protocol

protocol CardLoadingState {
    var isLoading: Bool { get }
    var loadingText: String? { get }
    var shimmerEnabled: Bool { get }
}

struct CardLoading: CardLoadingState {
    let isLoading: Bool
    let loadingText: String?
    let shimmerEnabled: Bool
    
    init(
        isLoading: Bool = false,
        loadingText: String? = nil,
        shimmerEnabled: Bool = true
    ) {
        self.isLoading = isLoading
        self.loadingText = loadingText
        self.shimmerEnabled = shimmerEnabled
    }
}

// MARK: - Card Configuration (Complete)

struct CardConfiguration {
    let style: CardStyling
    let interaction: CardInteractionHandling
    let accessibility: CardAccessibilityConfiguration
    let animation: CardAnimationConfiguration
    let loading: CardLoadingState
    
    init(
        style: CardStyling = DefaultCardStyle(),
        interaction: CardInteractionHandling = CardInteraction(),
        accessibility: CardAccessibilityConfiguration = CardAccessibility(),
        animation: CardAnimationConfiguration = CardAnimation(),
        loading: CardLoadingState = CardLoading()
    ) {
        self.style = style
        self.interaction = interaction
        self.accessibility = accessibility
        self.animation = animation
        self.loading = loading
    }
}

// MARK: - Predefined Configurations

extension CardConfiguration {
    static let `default` = CardConfiguration()
    
    static let elevated = CardConfiguration(
        style: ElevatedCardStyle()
    )
    
    static let outlined = CardConfiguration(
        style: OutlinedCardStyle()
    )
    
    static func selectable(isSelected: Bool) -> CardConfiguration {
        CardConfiguration(
            style: SelectableCardStyle(isSelected: isSelected),
            interaction: CardInteraction(onTap: {}),
            animation: CardAnimation(hapticFeedback: .selection)
        )
    }
    
    static func tappable(action: @escaping () -> Void) -> CardConfiguration {
        CardConfiguration(
            interaction: CardInteraction(onTap: action),
            accessibility: CardAccessibility(traits: [.isButton])
        )
    }
    
    static func editable(
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) -> CardConfiguration {
        CardConfiguration(
            interaction: CardInteraction(
                onTap: onTap,
                onLongPress: onLongPress
            ),
            accessibility: CardAccessibility(
                hint: "长按编辑",
                traits: [.isButton]
            ),
            animation: CardAnimation(hapticFeedback: .medium)
        )
    }
    
    static let loading = CardConfiguration(
        loading: CardLoading(isLoading: true)
    )
}