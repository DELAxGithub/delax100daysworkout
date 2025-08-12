import SwiftUI
import UIKit

// MARK: - Accessibility Utilities

struct AccessibilityUtils {
    
    // MARK: - System Accessibility Checks
    
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    static var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }
    
    static var isDifferentiateWithoutColorEnabled: Bool {
        UIAccessibility.isDifferentiateWithoutColorEnabled
    }
    
    static var isAssistiveTouchRunning: Bool {
        UIAccessibility.isAssistiveTouchRunning
    }
    
    // MARK: - Dynamic Type Support
    
    static var preferredContentSizeCategory: ContentSizeCategory {
        ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
    }
    
    static var isAccessibilitySize: Bool {
        preferredContentSizeCategory.isAccessibilityCategory
    }
    
    static func scaledValue(_ value: CGFloat, maximum: CGFloat? = nil) -> CGFloat {
        let scaleFactor = preferredContentSizeCategory.scaleFactor
        let scaledValue = value * scaleFactor
        return maximum.map { min(scaledValue, $0) } ?? scaledValue
    }
    
    // MARK: - Notification Helpers
    
    static func postLayoutChangedNotification() {
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
    
    static func postScreenChangedNotification() {
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    static func postAnnouncement(_ text: String) {
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}

// MARK: - Content Size Category Extensions

extension ContentSizeCategory {
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.9
        case .accessibilityExtraLarge: return 2.3
        case .accessibilityExtraExtraLarge: return 2.8
        case .accessibilityExtraExtraExtraLarge: return 3.5
        @unknown default: return 1.0
        }
    }
}

// MARK: - Accessibility Modifier

struct AccessibilityConfiguration {
    let label: String?
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits
    let isElement: Bool
    let sortPriority: Double
    
    init(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        isElement: Bool = true,
        sortPriority: Double = 0
    ) {
        self.label = label
        self.hint = hint
        self.value = value
        self.traits = traits
        self.isElement = isElement
        self.sortPriority = sortPriority
    }
}

struct AccessibilityModifier: ViewModifier {
    let configuration: AccessibilityConfiguration
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: configuration.isElement ? .contain : .ignore)
            .accessibilityLabel(configuration.label ?? "")
            .accessibilityHint(configuration.hint ?? "")
            .accessibilityValue(configuration.value ?? "")
            .accessibilityAddTraits(configuration.traits)
            .accessibilitySortPriority(configuration.sortPriority)
    }
}

extension View {
    func accessibility(_ configuration: AccessibilityConfiguration) -> some View {
        modifier(AccessibilityModifier(configuration: configuration))
    }
    
    func accessibilityCardButton(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        accessibility(AccessibilityConfiguration(
            label: label,
            hint: hint,
            value: value,
            traits: [.isButton]
        ))
    }
    
    func accessibilityCardHeader(
        label: String,
        value: String? = nil
    ) -> some View {
        accessibility(AccessibilityConfiguration(
            label: label,
            value: value,
            traits: [.isHeader]
        ))
    }
}

// MARK: - Motion Reduction Support

struct MotionManager {
    static var shouldReduceMotion: Bool {
        AccessibilityUtils.isReduceMotionEnabled
    }
    
    static func animation<V>(_ animation: Animation?, value: V) -> Animation? where V: Equatable {
        shouldReduceMotion ? nil : animation
    }
    
    static func conditionalAnimation<V>(_ animation: Animation, value: V) -> Animation where V: Equatable {
        shouldReduceMotion ? .linear(duration: 0.01) : animation
    }
}

struct ReduceMotionModifier: ViewModifier {
    let animation: Animation
    let reducedAnimation: Animation
    
    init(animation: Animation, reducedAnimation: Animation = .linear(duration: 0.01)) {
        self.animation = animation
        self.reducedAnimation = reducedAnimation
    }
    
    func body(content: Content) -> some View {
        content
            .animation(
                MotionManager.shouldReduceMotion ? reducedAnimation : animation,
                value: UUID() // This should be replaced with actual state value
            )
    }
}

extension View {
    func reduceMotionSensitive(
        animation: Animation,
        reducedAnimation: Animation = .linear(duration: 0.01)
    ) -> some View {
        modifier(ReduceMotionModifier(
            animation: animation,
            reducedAnimation: reducedAnimation
        ))
    }
}

// MARK: - Color Differentiation Support

struct ColorDifferentiationUtils {
    static var shouldDifferentiateWithoutColor: Bool {
        AccessibilityUtils.isDifferentiateWithoutColorEnabled
    }
    
    static func semanticColor(
        normal: SemanticColor,
        highContrast: SemanticColor
    ) -> SemanticColor {
        shouldDifferentiateWithoutColor ? highContrast : normal
    }
    
    static func iconForState(
        isSelected: Bool,
        selectedIcon: String = "checkmark.circle.fill",
        unselectedIcon: String = "circle"
    ) -> String {
        if shouldDifferentiateWithoutColor {
            return isSelected ? selectedIcon : unselectedIcon
        }
        return isSelected ? selectedIcon : unselectedIcon
    }
}

// MARK: - Haptic Feedback Manager

struct HapticsManager {
    
    static func cardAction(_ type: HapticFeedbackType) {
        // Only provide haptics if AssistiveTouch is not running
        guard !AccessibilityUtils.isAssistiveTouchRunning else { return }
        
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    static func prepare(_ type: HapticFeedbackType) {
        guard !AccessibilityUtils.isAssistiveTouchRunning else { return }
        
        switch type {
        case .light, .medium, .heavy:
            UIImpactFeedbackGenerator(style: .light).prepare()
        case .selection:
            UISelectionFeedbackGenerator().prepare()
        case .success, .warning, .error:
            UINotificationFeedbackGenerator().prepare()
        }
    }
}

// MARK: - Gesture Constants

enum GestureConstants {
    static let minimumLongPressDuration: Double = 0.4
    static let minimumSwipeDistance: CGFloat = 50
    static let maximumTapDuration: Double = 0.3
    
    // Adjusted for accessibility
    static var adjustedLongPressDuration: Double {
        AccessibilityUtils.isVoiceOverRunning ? 0.6 : minimumLongPressDuration
    }
    
    static var adjustedSwipeDistance: CGFloat {
        AccessibilityUtils.isVoiceOverRunning ? 75 : minimumSwipeDistance
    }
}

// MARK: - Voice Control Support

struct VoiceControlUtils {
    static func addVoiceControlLabel(_ label: String) -> some View {
        // This creates an invisible accessibility element for voice control
        Text("")
            .accessibilityLabel(label)
            .accessibilityHidden(true)
            .frame(width: 0, height: 0)
    }
}

// MARK: - Environment Values Extension

extension EnvironmentValues {
    private struct ReduceMotionKey: EnvironmentKey {
        static let defaultValue: Bool = AccessibilityUtils.isReduceMotionEnabled
    }
    
    private struct VoiceOverKey: EnvironmentKey {
        static let defaultValue: Bool = AccessibilityUtils.isVoiceOverRunning
    }
    
    var isReduceMotionEnabled: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
    
    var isVoiceOverRunning: Bool {
        get { self[VoiceOverKey.self] }
        set { self[VoiceOverKey.self] = newValue }
    }
}