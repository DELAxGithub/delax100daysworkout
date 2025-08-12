import SwiftUI

// MARK: - Animation Standards

struct AnimationStandards {
    // Basic timing
    static let quick = Animation.easeInOut(duration: 0.15)
    static let standard = Animation.easeInOut(duration: 0.25)
    static let smooth = Animation.easeInOut(duration: 0.35)
    static let slow = Animation.easeInOut(duration: 0.5)
    
    // Spring animations
    static let bounce = Animation.spring(response: 0.6, dampingFraction: 0.7)
    static let gentle = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.9)
    
    // Reduced motion alternatives
    static let reducedQuick = Animation.linear(duration: 0.01)
    static let reducedStandard = Animation.linear(duration: 0.05)
    
    // Adaptive animations (respects accessibility settings)
    static func adaptive(_ animation: Animation) -> Animation {
        MotionManager.shouldReduceMotion ? reducedStandard : animation
    }
    
    // Common animation presets
    static let cardPress = adaptive(Animation.easeInOut(duration: 0.15))
    static let cardSwipe = adaptive(bounce)
    static let pageTransition = adaptive(smooth)
    static let popIn = adaptive(snappy)
    static let fadeInOut = adaptive(standard)
}

// MARK: - Transition Standards

struct TransitionStandards {
    static let slideFromLeading = AnyTransition.asymmetric(
        insertion: .move(edge: .leading),
        removal: .move(edge: .trailing)
    ).combined(with: .opacity)
    
    static let slideFromTrailing = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    ).combined(with: .opacity)
    
    static let slideFromTop = AnyTransition.asymmetric(
        insertion: .move(edge: .top),
        removal: .move(edge: .bottom)
    ).combined(with: .opacity)
    
    static let slideFromBottom = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom),
        removal: .move(edge: .top)
    ).combined(with: .opacity)
    
    static let scale = AnyTransition.scale.combined(with: .opacity)
    static let fade = AnyTransition.opacity
    static let push = AnyTransition.push(from: .trailing)
}

// MARK: - View Extensions

extension View {
    func adaptiveAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(AnimationStandards.adaptive(animation), value: value)
    }
    
    func cardPressAnimation<V: Equatable>(value: V) -> some View {
        self.animation(AnimationStandards.cardPress, value: value)
    }
    
    func cardSwipeAnimation<V: Equatable>(value: V) -> some View {
        self.animation(AnimationStandards.cardSwipe, value: value)
    }
    
    func standardTransition(_ transition: AnyTransition = TransitionStandards.fade) -> some View {
        self.transition(transition)
    }
}