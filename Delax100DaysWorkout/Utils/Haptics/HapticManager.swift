import SwiftUI
import UIKit

// MARK: - Haptic Feedback System

enum HapticIntensity {
    case light
    case medium
    case heavy
}

enum HapticType {
    case impact(HapticIntensity)
    case selection
    case notification(UINotificationFeedbackGenerator.FeedbackType)
}

struct HapticManager {
    static let shared = HapticManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private init() {
        // Pre-prepare generators for better performance
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    func trigger(_ type: HapticType) {
        // Skip haptics if AssistiveTouch is running
        guard !AccessibilityUtils.isAssistiveTouchRunning else { return }
        
        switch type {
        case .impact(.light):
            lightImpact.impactOccurred()
        case .impact(.medium):
            mediumImpact.impactOccurred()
        case .impact(.heavy):
            heavyImpact.impactOccurred()
        case .selection:
            selectionFeedback.selectionChanged()
        case .notification(let feedbackType):
            notificationFeedback.notificationOccurred(feedbackType)
        }
    }
    
    func prepare(_ type: HapticType) {
        guard !AccessibilityUtils.isAssistiveTouchRunning else { return }
        
        switch type {
        case .impact(.light):
            lightImpact.prepare()
        case .impact(.medium):
            mediumImpact.prepare()
        case .impact(.heavy):
            heavyImpact.prepare()
        case .selection:
            selectionFeedback.prepare()
        case .notification:
            notificationFeedback.prepare()
        }
    }
}

// MARK: - Convenience Feedback Functions

struct InteractionFeedback {
    static func success() {
        HapticManager.shared.trigger(.notification(.success))
    }
    
    static func error() {
        HapticManager.shared.trigger(.notification(.error))
    }
    
    static func warning() {
        HapticManager.shared.trigger(.notification(.warning))
    }
    
    static func cardTap() {
        HapticManager.shared.trigger(.impact(.light))
    }
    
    static func cardLongPress() {
        HapticManager.shared.trigger(.impact(.medium))
    }
    
    static func cardSwipe() {
        HapticManager.shared.trigger(.selection)
    }
    
    static func buttonPress() {
        HapticManager.shared.trigger(.impact(.light))
    }
    
    static func selectionChange() {
        HapticManager.shared.trigger(.selection)
    }
}