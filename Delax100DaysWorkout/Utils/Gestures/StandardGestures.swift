import SwiftUI

// MARK: - Standard Gesture Modifiers

struct StandardTapGesture: ViewModifier {
    let action: () -> Void
    let hapticFeedback: HapticType
    
    init(action: @escaping () -> Void, hapticFeedback: HapticType = .impact(.light)) {
        self.action = action
        self.hapticFeedback = hapticFeedback
    }
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                HapticManager.shared.trigger(hapticFeedback)
                action()
            }
    }
}

struct StandardLongPressGesture: ViewModifier {
    let action: () -> Void
    let duration: TimeInterval
    let hapticFeedback: HapticType
    
    init(
        action: @escaping () -> Void,
        duration: TimeInterval? = nil,
        hapticFeedback: HapticType = .impact(.medium)
    ) {
        self.action = action
        self.duration = duration ?? GestureConfiguration.shared.adjustedLongPressDuration
        self.hapticFeedback = hapticFeedback
    }
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: duration) {
                HapticManager.shared.trigger(hapticFeedback)
                action()
            }
    }
}

struct StandardSwipeGesture: ViewModifier {
    let direction: SwipeDirection
    let action: () -> Void
    let hapticFeedback: HapticType
    
    enum SwipeDirection {
        case left, right, up, down
    }
    
    init(
        direction: SwipeDirection,
        action: @escaping () -> Void,
        hapticFeedback: HapticType = .selection
    ) {
        self.direction = direction
        self.action = action
        self.hapticFeedback = hapticFeedback
    }
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: GestureConfiguration.shared.adjustedSwipeDistance)
                    .onEnded { value in
                        let translation = value.translation
                        let velocity = value.velocity
                        
                        if isSwipeInDirection(translation: translation, velocity: velocity) {
                            HapticManager.shared.trigger(hapticFeedback)
                            action()
                        }
                    }
            )
    }
    
    private func isSwipeInDirection(translation: CGSize, velocity: CGSize) -> Bool {
        let config = GestureConfiguration.shared
        
        switch direction {
        case .left:
            return translation.x < -config.adjustedSwipeDistance && abs(velocity.x) > config.minimumSwipeVelocity
        case .right:
            return translation.x > config.adjustedSwipeDistance && abs(velocity.x) > config.minimumSwipeVelocity
        case .up:
            return translation.y < -config.adjustedSwipeDistance && abs(velocity.y) > config.minimumSwipeVelocity
        case .down:
            return translation.y > config.adjustedSwipeDistance && abs(velocity.y) > config.minimumSwipeVelocity
        }
    }
}

// MARK: - View Extensions

extension View {
    func standardTap(action: @escaping () -> Void) -> some View {
        modifier(StandardTapGesture(action: action))
    }
    
    func standardLongPress(action: @escaping () -> Void) -> some View {
        modifier(StandardLongPressGesture(action: action))
    }
    
    func standardSwipe(
        _ direction: StandardSwipeGesture.SwipeDirection,
        action: @escaping () -> Void
    ) -> some View {
        modifier(StandardSwipeGesture(direction: direction, action: action))
    }
    
    func minimumTouchTarget() -> some View {
        frame(
            minWidth: GestureConfiguration.shared.adjustedTouchTarget,
            minHeight: GestureConfiguration.shared.adjustedTouchTarget
        )
    }
}