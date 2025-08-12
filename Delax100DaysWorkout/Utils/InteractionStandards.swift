import SwiftUI

// MARK: - Interaction Standards (Main Entry Point)

/// This file serves as the main entry point for interaction standards.
/// Individual components are organized in separate files:
/// - HapticManager.swift: Haptic feedback management
/// - GestureConfiguration.swift: Gesture settings and configuration
/// - StandardGestures.swift: Standard gesture modifiers
/// - AnimationStandards.swift: Animation presets and utilities
/// - InteractionStateManager.swift: State management for interactive components

// Re-export commonly used types for convenience
typealias GestureConfig = GestureConfiguration
typealias Haptics = HapticManager
typealias Animations = AnimationStandards
typealias Feedback = InteractionFeedback