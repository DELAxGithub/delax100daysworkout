import SwiftUI

// MARK: - Design Token Protocols

protocol ColorToken {
    var color: Color { get }
}

protocol SpacingToken {
    var value: CGFloat { get }
}

protocol TypographyToken {
    var font: Font { get }
}

protocol CornerRadiusToken {
    var radius: CGFloat { get }
}

// MARK: - Semantic Color System

enum SemanticColor: ColorToken {
    // Primary Colors
    case primaryBackground
    case secondaryBackground
    case cardBackground
    case surfaceBackground
    
    // Text Colors
    case primaryText
    case secondaryText
    case tertiaryText
    case linkText
    
    // Action Colors
    case primaryAction
    case secondaryAction
    case destructiveAction
    case successAction
    case warningAction
    case errorAction
    
    // State Colors
    case selectedBackground
    case hoveredBackground
    case disabledBackground
    case disabledText
    
    // Border Colors
    case primaryBorder
    case secondaryBorder
    case focusBorder
    
    var color: Color {
        switch self {
        // Primary Colors
        case .primaryBackground:
            return Color(.systemBackground)
        case .secondaryBackground:
            return Color(.secondarySystemBackground)
        case .cardBackground:
            return Color(.secondarySystemGroupedBackground)
        case .surfaceBackground:
            return Color(.systemGroupedBackground)
            
        // Text Colors
        case .primaryText:
            return Color(.label)
        case .secondaryText:
            return Color(.secondaryLabel)
        case .tertiaryText:
            return Color(.tertiaryLabel)
        case .linkText:
            return Color(.link)
            
        // Action Colors
        case .primaryAction:
            return Color(.systemBlue)
        case .secondaryAction:
            return Color(.systemGray)
        case .destructiveAction:
            return Color(.systemRed)
        case .successAction:
            return Color(.systemGreen)
        case .warningAction:
            return Color(.systemOrange)
        case .errorAction:
            return Color(.systemRed)
            
        // State Colors
        case .selectedBackground:
            return Color(.systemBlue).opacity(0.1)
        case .hoveredBackground:
            return Color(.systemGray6)
        case .disabledBackground:
            return Color(.systemGray5)
        case .disabledText:
            return Color(.systemGray3)
            
        // Border Colors
        case .primaryBorder:
            return Color(.separator)
        case .secondaryBorder:
            return Color(.systemGray5)
        case .focusBorder:
            return Color(.systemBlue)
        }
    }
}

// MARK: - Spacing System (8pt Grid)

enum Spacing: SpacingToken {
    case xs     // 4pt
    case sm     // 8pt
    case md     // 16pt
    case lg     // 24pt
    case xl     // 32pt
    case xxl    // 48pt
    case xxxl   // 64pt
    
    // Component-specific spacing
    case cardPadding        // 16pt
    case cardSpacing        // 20pt
    case sectionSpacing     // 32pt
    case listItemSpacing    // 12pt
    case buttonPadding      // 12pt
    
    var value: CGFloat {
        switch self {
        case .xs: return 4
        case .sm: return 8
        case .md: return 16
        case .lg: return 24
        case .xl: return 32
        case .xxl: return 48
        case .xxxl: return 64
        case .cardPadding: return 16
        case .cardSpacing: return 20
        case .sectionSpacing: return 32
        case .listItemSpacing: return 12
        case .buttonPadding: return 12
        }
    }
}

// MARK: - Typography System

enum Typography: TypographyToken {
    // Display Text (for important metrics, large numbers)
    case displayLarge
    case displayMedium
    case displaySmall
    
    // Headlines
    case headlineLarge
    case headlineMedium
    case headlineSmall
    
    // Body Text
    case bodyLarge
    case bodyMedium
    case bodySmall
    
    // Labels
    case labelLarge
    case labelMedium
    case labelSmall
    
    // Captions
    case captionLarge
    case captionMedium
    case captionSmall
    
    // Special purpose
    case monospace
    case numeric
    
    var font: Font {
        switch self {
        // Display Text
        case .displayLarge:
            return .system(size: 48, weight: .heavy, design: .rounded)
        case .displayMedium:
            return .system(size: 36, weight: .bold, design: .rounded)
        case .displaySmall:
            return .system(size: 24, weight: .semibold, design: .rounded)
            
        // Headlines
        case .headlineLarge:
            return .system(size: 22, weight: .bold, design: .default)
        case .headlineMedium:
            return .system(size: 18, weight: .semibold, design: .default)
        case .headlineSmall:
            return .system(size: 16, weight: .medium, design: .default)
            
        // Body Text
        case .bodyLarge:
            return .system(size: 18, weight: .regular, design: .default)
        case .bodyMedium:
            return .system(size: 16, weight: .regular, design: .default)
        case .bodySmall:
            return .system(size: 14, weight: .regular, design: .default)
            
        // Labels
        case .labelLarge:
            return .system(size: 16, weight: .medium, design: .default)
        case .labelMedium:
            return .system(size: 14, weight: .medium, design: .default)
        case .labelSmall:
            return .system(size: 12, weight: .medium, design: .default)
            
        // Captions
        case .captionLarge:
            return .system(size: 14, weight: .regular, design: .default)
        case .captionMedium:
            return .system(size: 12, weight: .regular, design: .default)
        case .captionSmall:
            return .system(size: 10, weight: .regular, design: .default)
            
        // Special purpose
        case .monospace:
            return .system(size: 14, weight: .regular, design: .monospaced)
        case .numeric:
            return .system(size: 32, weight: .bold, design: .rounded)
        }
    }
}

// MARK: - Corner Radius System

enum CornerRadius: CornerRadiusToken {
    case none
    case small
    case medium
    case large
    case xlarge
    case pill
    
    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .small: return 4
        case .medium: return 8
        case .large: return 12
        case .xlarge: return 16
        case .pill: return 1000 // Will create pill shape
        }
    }
}

// MARK: - Shadow System

enum ShadowStyle {
    case none
    case small
    case medium
    case large
    
    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .small: return 2
        case .medium: return 4
        case .large: return 8
        }
    }
    
    var offset: (x: CGFloat, y: CGFloat) {
        switch self {
        case .none: return (0, 0)
        case .small: return (0, 1)
        case .medium: return (0, 2)
        case .large: return (0, 4)
        }
    }
    
    var opacity: Double {
        switch self {
        case .none: return 0
        case .small: return 0.05
        case .medium: return 0.1
        case .large: return 0.15
        }
    }
}

// MARK: - Environment Integration

extension EnvironmentValues {
    private struct SemanticColorKey: EnvironmentKey {
        static let defaultValue: (SemanticColor) -> Color = { $0.color }
    }
    
    var semanticColor: (SemanticColor) -> Color {
        get { self[SemanticColorKey.self] }
        set { self[SemanticColorKey.self] = newValue }
    }
}

// MARK: - View Extensions for Easy Usage

extension View {
    func foregroundColor(_ semanticColor: SemanticColor) -> some View {
        self.foregroundColor(semanticColor.color)
    }
    
    func background(_ semanticColor: SemanticColor) -> some View {
        self.background(semanticColor.color)
    }
    
    func font(_ typography: Typography) -> some View {
        self.font(typography.font)
    }
    
    func padding(_ spacing: Spacing) -> some View {
        self.padding(spacing.value)
    }
    
    func cornerRadius(_ radius: CornerRadius) -> some View {
        self.cornerRadius(radius.radius)
    }
    
    func shadow(_ style: ShadowStyle) -> some View {
        let offset = style.offset
        return self.shadow(
            color: Color.black.opacity(style.opacity),
            radius: style.radius,
            x: offset.x,
            y: offset.y
        )
    }
}