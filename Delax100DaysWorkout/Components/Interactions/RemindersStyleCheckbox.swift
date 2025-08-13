import SwiftUI

// MARK: - Apple Reminders Style Checkbox Component

struct RemindersStyleCheckbox: View {
    let isCompleted: Bool
    let action: () -> Void
    
    // Customization options
    let size: CheckboxSize
    let style: CheckboxStyle
    
    // MARK: - Initializers
    
    init(
        isCompleted: Bool,
        action: @escaping () -> Void,
        size: CheckboxSize = .standard,
        style: CheckboxStyle = .default
    ) {
        self.isCompleted = isCompleted
        self.action = action
        self.size = size
        self.style = style
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            // Apple Reminders-style haptic feedback
            HapticManager.shared.trigger(isCompleted ? .impact(.light) : .impact(.medium))
            
            // Delay action slightly to allow haptic to fire first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                action()
            }
        }) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        isCompleted ? style.completedColor : style.incompleteColor,
                        lineWidth: style.borderWidth
                    )
                    .background(
                        Circle()
                            .fill(isCompleted ? style.completedColor : Color.clear)
                    )
                    .frame(width: size.dimension, height: size.dimension)
                
                // Checkmark
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(size.checkmarkFont)
                        .fontWeight(.semibold)
                        .foregroundColor(style.checkmarkColor)
                        .scaleEffect(isCompleted ? 1.0 : 0.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isCompleted ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isCompleted)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isCompleted ? "完了済み" : "未完了")
        .accessibilityHint("タップして状態を切り替え")
        .accessibilityValue(isCompleted ? "完了" : "未完了")
        .frame(minWidth: 44, minHeight: 44) // Apple HIG compliance
    }
}

// MARK: - Configuration Types

enum CheckboxSize {
    case small
    case standard
    case large
    
    var dimension: CGFloat {
        switch self {
        case .small: return 20
        case .standard: return 24
        case .large: return 28
        }
    }
    
    var checkmarkFont: Font {
        switch self {
        case .small: return .system(size: 10, weight: .semibold)
        case .standard: return .system(size: 12, weight: .semibold)
        case .large: return .system(size: 14, weight: .semibold)
        }
    }
}

struct CheckboxStyle {
    let completedColor: Color
    let incompleteColor: Color
    let checkmarkColor: Color
    let borderWidth: CGFloat
    
    static let `default` = CheckboxStyle(
        completedColor: SemanticColor.successAction.color,
        incompleteColor: SemanticColor.secondaryBorder.color,
        checkmarkColor: .white,
        borderWidth: 2.0
    )
    
    static let workout = CheckboxStyle(
        completedColor: SemanticColor.primaryAction.color,
        incompleteColor: SemanticColor.secondaryBorder.color,
        checkmarkColor: .white,
        borderWidth: 2.0
    )
    
    static let task = CheckboxStyle(
        completedColor: SemanticColor.successAction.color,
        incompleteColor: SemanticColor.primaryBorder.color,
        checkmarkColor: .white,
        borderWidth: 1.5
    )
}

// MARK: - Preview

#Preview("Checkbox States") {
    VStack(spacing: Spacing.lg.value) {
        // Different states
        HStack(spacing: Spacing.md.value) {
            VStack {
                Text("未完了")
                    .font(Typography.labelSmall.font)
                RemindersStyleCheckbox(isCompleted: false, action: {})
            }
            
            VStack {
                Text("完了")
                    .font(Typography.labelSmall.font)
                RemindersStyleCheckbox(isCompleted: true, action: {})
            }
        }
        
        Divider()
        
        // Different sizes
        HStack(spacing: Spacing.md.value) {
            VStack {
                Text("Small")
                    .font(Typography.labelSmall.font)
                RemindersStyleCheckbox(
                    isCompleted: true,
                    action: {},
                    size: .small
                )
            }
            
            VStack {
                Text("Standard")
                    .font(Typography.labelSmall.font)
                RemindersStyleCheckbox(
                    isCompleted: true,
                    action: {},
                    size: .standard
                )
            }
            
            VStack {
                Text("Large")
                    .font(Typography.labelSmall.font)
                RemindersStyleCheckbox(
                    isCompleted: true,
                    action: {},
                    size: .large
                )
            }
        }
        
        Divider()
        
        // Different styles
        VStack(spacing: Spacing.md.value) {
            HStack {
                Text("Default Style")
                Spacer()
                RemindersStyleCheckbox(
                    isCompleted: true,
                    action: {},
                    style: .default
                )
            }
            
            HStack {
                Text("Workout Style")
                Spacer()
                RemindersStyleCheckbox(
                    isCompleted: true,
                    action: {},
                    style: .workout
                )
            }
            
            HStack {
                Text("Task Style")
                Spacer()
                RemindersStyleCheckbox(
                    isCompleted: false,
                    action: {},
                    style: .task
                )
            }
        }
    }
    .padding()
    .background(SemanticColor.primaryBackground.color)
}