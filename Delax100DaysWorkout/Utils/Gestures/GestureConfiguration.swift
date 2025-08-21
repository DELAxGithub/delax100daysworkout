import SwiftUI
import UIKit

// MARK: - Gesture Configuration

struct GestureConfiguration {
    static let shared = GestureConfiguration()
    
    // Touch targets (Apple HIG recommendations)
    let minimumTouchTarget: CGFloat = 44
    let recommendedTouchTarget: CGFloat = 48
    
    // Timing
    let minimumTapDuration: TimeInterval = 0
    let maximumTapDuration: TimeInterval = 0.3
    let defaultLongPressDuration: TimeInterval = 0.4
    
    // Distance thresholds
    let minimumSwipeDistance: CGFloat = 50
    let dragThreshold: CGFloat = 10
    
    // Velocity thresholds (points per second)
    let minimumSwipeVelocity: CGFloat = 200
    let fastSwipeVelocity: CGFloat = 500
    
    // Accessibility adjustments
    var adjustedLongPressDuration: TimeInterval {
        AccessibilityUtils.isVoiceOverRunning ? 0.6 : defaultLongPressDuration
    }
    
    var adjustedSwipeDistance: CGFloat {
        AccessibilityUtils.isVoiceOverRunning ? 75 : minimumSwipeDistance
    }
    
    var adjustedTouchTarget: CGFloat {
        AccessibilityUtils.isVoiceOverRunning ? recommendedTouchTarget : minimumTouchTarget
    }
}

// MARK: - Interaction Patterns

enum InteractionPattern {
    case tap
    case longPress
    case swipeLeft
    case swipeRight
    case swipeUp
    case swipeDown
    case drag
    case pinch
    case rotate
}

extension InteractionPattern {
    var hapticFeedback: HapticType {
        switch self {
        case .tap:
            return .impact(.light)
        case .longPress:
            return .impact(.medium)
        case .swipeLeft, .swipeRight, .swipeUp, .swipeDown:
            return .selection
        case .drag:
            return .impact(.light)
        case .pinch, .rotate:
            return .impact(.medium)
        }
    }
    
    var accessibilityHint: String {
        switch self {
        case .tap:
            return "タップして詳細を表示"
        case .longPress:
            return "長押ししてオプションを表示"
        case .swipeLeft:
            return "左にスワイプしてアクション"
        case .swipeRight:
            return "右にスワイプしてアクション"
        case .swipeUp:
            return "上にスワイプしてアクション"
        case .swipeDown:
            return "下にスワイプしてアクション"
        case .drag:
            return "ドラッグして移動"
        case .pinch:
            return "ピンチしてズーム"
        case .rotate:
            return "回転させる"
        }
    }
}