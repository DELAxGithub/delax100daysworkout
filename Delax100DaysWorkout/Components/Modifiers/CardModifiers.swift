import SwiftUI

// MARK: - HapticFeedbackType Extension

extension HapticFeedbackType {
    func toHapticType() -> HapticType {
        switch self {
        case .light:
            return .impact(.light)
        case .medium:
            return .impact(.medium)
        case .heavy:
            return .impact(.heavy)
        case .selection:
            return .selection
        case .success:
            return .notification(.success)
        case .warning:
            return .notification(.warning)
        case .error:
            return .notification(.error)
        }
    }
}

// MARK: - Accessibility Modifier

struct AccessibilityModifier: ViewModifier {
    let configuration: CardAccessibilityConfiguration
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: configuration.isAccessibilityElement ? .contain : .ignore)
            .accessibilityLabel(configuration.label ?? "")
            .accessibilityHint(configuration.hint ?? "")
            .accessibilityValue(configuration.value ?? "")
            .accessibilityAddTraits(configuration.traits)
    }
}

// MARK: - Interaction Modifier

struct InteractionModifier: ViewModifier {
    let configuration: CardConfiguration
    @Binding var isPressed: Bool
    
    @State private var dragOffset: CGSize = .zero
    @Environment(\.isReduceMotionEnabled) private var isReduceMotionEnabled
    
    func body(content: Content) -> some View {
        content
            .offset(dragOffset)
            .gesture(tapAndDragGesture)
            .simultaneousGesture(longPressGesture)
            .animation(
                isReduceMotionEnabled ? 
                    .linear(duration: 0.01) : 
                    .spring(response: 0.3, dampingFraction: 0.7),
                value: dragOffset
            )
    }
    
    // MARK: - Gestures
    
    private var tapAndDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { value in
                handleDragEnded(value)
            }
    }
    
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: GestureConfiguration.shared.adjustedLongPressDuration)
            .onEnded { _ in
                handleLongPress()
            }
    }
    
    // MARK: - Gesture Handlers
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if !isPressed && !configuration.interaction.isDisabled {
            isPressed = true
            if let haptic = configuration.animation.hapticFeedback {
                HapticManager.shared.trigger(haptic.toHapticType())
            }
        }
        
        // Handle swipe preview
        let translation = value.translation
        if abs(translation.width) > GestureConfiguration.shared.minimumSwipeDistance {
            dragOffset = CGSize(
                width: translation.width * 0.3, // Reduced movement for preview
                height: 0
            )
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        isPressed = false
        
        guard !configuration.interaction.isDisabled else {
            resetDragOffset()
            return
        }
        
        let translation = value.translation
        let velocity = value.velocity
        
        // Determine action based on gesture
        if abs(translation.width) > GestureConfiguration.shared.minimumSwipeDistance ||
           abs(velocity.width) > 200 {
            handleSwipeAction(translation: translation)
        } else {
            handleTapAction()
        }
        
        resetDragOffset()
    }
    
    private func handleLongPress() {
        guard !configuration.interaction.isDisabled else { return }
        
        HapticManager.shared.trigger(.impact(.medium))
        configuration.interaction.onLongPress?()
    }
    
    private func handleSwipeAction(translation: CGSize) {
        if translation.width > 0 {
            configuration.interaction.onSwipeRight?()
        } else {
            configuration.interaction.onSwipeLeft?()
        }
    }
    
    private func handleTapAction() {
        configuration.interaction.onTap?()
    }
    
    private func resetDragOffset() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            dragOffset = .zero
        }
    }
}

// MARK: - Loading State Modifier

struct LoadingStateModifier: ViewModifier {
    let isLoading: Bool
    let loadingConfiguration: CardLoadingState
    let cardStyle: CardStyling
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isLoading ? 0 : 1)
            
            if isLoading {
                CardLoadingView(
                    configuration: loadingConfiguration,
                    style: cardStyle
                )
            }
        }
    }
}

// MARK: - Animation Modifier

struct CardAnimationModifier: ViewModifier {
    let configuration: CardAnimationConfiguration
    @Binding var isPressed: Bool
    
    @Environment(\.isReduceMotionEnabled) private var isReduceMotionEnabled
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? configuration.pressedScale : 1.0)
            .animation(
                isReduceMotionEnabled ? 
                    .linear(duration: 0.01) : 
                    .easeInOut(duration: configuration.animationDuration),
                value: isPressed
            )
    }
}