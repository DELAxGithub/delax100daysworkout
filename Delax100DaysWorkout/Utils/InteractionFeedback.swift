import Foundation
import UIKit

// MARK: - Interaction Feedback

struct InteractionFeedback {
    static func error() {
        HapticManager.shared.trigger(.notification(.error))
    }
    
    static func success() {
        HapticManager.shared.trigger(.notification(.success))
    }
    
    static func warning() {
        HapticManager.shared.trigger(.notification(.warning))
    }
    
    static func selection() {
        HapticManager.shared.trigger(.selection)
    }
}