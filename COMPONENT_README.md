# 🎯 UI Component Library - README

## Overview

This is a comprehensive SwiftUI component library designed for enterprise-level consistency, accessibility, and performance. Built on protocol-based architecture with design tokens, it provides a unified foundation for all UI elements.

## 🚀 Quick Start

### Basic Usage

```swift
import SwiftUI

// Simple card
BaseCard {
    Text("Hello World")
        .font(Typography.headlineMedium.font)
        .foregroundColor(SemanticColor.primaryText)
}

// Interactive card
BaseCard.workout(onTap: { print("Tapped!") }) {
    HStack {
        Image(systemName: "figure.strengthtraining.traditional")
            .foregroundColor(SemanticColor.primaryAction)
        Text("Workout Card")
            .font(Typography.headlineMedium.font)
    }
}
```

## 📐 Design System

### Design Tokens

All styling uses semantic tokens instead of direct values:

```swift
// ❌ Don't do this
.foregroundColor(.blue)
.font(.headline)
.padding(16)
.cornerRadius(12)

// ✅ Do this
.foregroundColor(SemanticColor.primaryAction)
.font(Typography.headlineMedium.font)
.padding(Spacing.md.value)
.cornerRadius(CornerRadius.large)
```

### Available Token Categories

- **Colors**: `SemanticColor` (19 tokens)
- **Typography**: `Typography` (14 font styles)
- **Spacing**: `Spacing` (11 spacing values)
- **Corner Radius**: `CornerRadius` (6 radius values)

## 🎴 Component Guide

### BaseCard

The foundation of all card components. Supports multiple configurations:

```swift
// Default card
BaseCard {
    // Your content
}

// Pre-configured variants
BaseCard.workout(onTap: action) { content }
BaseCard.task(onTap: tap, onLongPress: longPress) { content }
BaseCard.summary { content }
BaseCard.selectable(isSelected: true, onTap: action) { content }
```

### Card Configurations

```swift
// Custom configuration
let config = CardConfiguration(
    style: ElevatedCardStyle(),
    interaction: CardInteraction(onTap: {}, onLongPress: {}),
    accessibility: CardAccessibility(label: "Custom card"),
    animation: CardAnimation(pressScale: 0.95),
    loading: CardLoading(isLoading: false)
)

BaseCard(configuration: config) {
    // Your content
}
```

### Predefined Styles

- `DefaultCardStyle` - Standard card with medium shadow
- `ElevatedCardStyle` - Large shadow for emphasis
- `OutlinedCardStyle` - Border instead of shadow
- `SelectableCardStyle` - Highlights when selected

## 🎮 Interactions

### Standard Gestures

```swift
// Basic interactions
Text("Tap me")
    .standardTap { print("Tapped") }
    .standardLongPress { print("Long pressed") }
    .standardSwipe(.left) { print("Swiped left") }

// Touch target enforcement
Button("Small Button") {}
    .minimumTouchTarget() // Ensures 44pt minimum
```

### Haptic Feedback

```swift
// Using HapticManager
HapticManager.shared.trigger(.impact(.light))
HapticManager.shared.trigger(.selection)
HapticManager.shared.trigger(.notification(.success))

// Convenience methods
InteractionFeedback.cardTap()
InteractionFeedback.success()
InteractionFeedback.error()
```

### Animations

```swift
// Standard animations with reduce motion support
Text("Animated")
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .adaptiveAnimation(AnimationStandards.standard, value: isPressed)

// Predefined animation types
.cardPressAnimation(value: isPressed)
.cardSwipeAnimation(value: dragOffset)
```

## ♿ Accessibility

### Built-in Support

All components include accessibility features:

```swift
BaseCard {
    Text("Accessible content")
}
.accessibilityCardButton(
    label: "Workout card",
    hint: "Double tap to open details"
)
```

### Accessibility Features

- **VoiceOver**: Semantic labels and hints
- **Dynamic Type**: All fonts scale automatically
- **Reduce Motion**: Animations respect accessibility settings
- **High Contrast**: Color differentiation support
- **Voice Control**: Touch targets and labels

### Testing Accessibility

Use the preview catalog to test different accessibility settings:

```swift
// In Xcode Preview
NavigationStack {
    AccessibilityCatalog()
}
```

## 📊 Performance

### Monitoring

Enable performance tracking in your app:

```swift
// In your App file
init() {
    PerformanceMonitor.shared.startMonitoring()
    UsageTracker.shared.startTracking()
}

// Track specific operations
.performanceTracked("MainDashboard")
.trackCardUsage("WorkoutCard", action: .appeared)
```

### Performance Goals

- Card interactions: P95 < 150ms
- View rendering: P95 < 100ms
- Animation smoothness: 60fps maintained
- Memory usage: < 50MB for component library

## 🧪 Testing

### Preview Catalog

Access the complete component catalog:

```swift
// Add to your app for development
#if DEBUG
ComponentCatalog()
#endif
```

### Categories Available

- **Cards**: All card variations and states
- **Tokens**: Visual representation of design tokens
- **Interactions**: Gesture and animation demos
- **Accessibility**: Accessibility feature testing

## 🔄 Migration

### From Legacy Components

Use the migration wrapper for gradual updates:

```swift
// Legacy wrapper (temporary)
LegacyCardWrapper.workoutCard {
    // Your existing content
}

// Target (final)
BaseCard.workout {
    // Your migrated content
}
```

### Migration Tools

Run the migration script:

```bash
# Complete migration
./Scripts/migration_tools.sh migrate-all

# Individual steps
./Scripts/migration_tools.sh migrate-colors
./Scripts/migration_tools.sh migrate-fonts
./Scripts/migration_tools.sh migrate-spacing
```

## 📏 Quality Gates

### Code Quality

```bash
# Linting (enforces design token usage)
swiftlint

# Formatting
swiftformat .

# Validation
./Scripts/migration_tools.sh validate
```

### Definition of Done

- ✅ Direct color usage = 0
- ✅ Direct font usage = 0
- ✅ Direct spacing usage = 0
- ✅ Accessibility compliance = 100%
- ✅ Performance benchmarks met
- ✅ All file sizes < 300 lines

## 🛠 Development Workflow

### 1. Design Token First

Always start with tokens:

```swift
// Define your values in DesignTokens.swift first
enum SemanticColor {
    case customAction
    // Implementation...
}
```

### 2. Component Development

Create components using BaseCard:

```swift
struct MyCustomCard: View {
    var body: some View {
        BaseCard.workout {
            // Use tokens exclusively
            Text("Content")
                .font(Typography.headlineMedium.font)
                .foregroundColor(SemanticColor.primaryText)
        }
    }
}
```

### 3. Add to Catalog

Include in preview catalog for testing:

```swift
// Add to ComponentCatalog.swift
NavigationLink("My Custom Card", destination: MyCustomCardCatalog())
```

### 4. Performance Check

Monitor performance impact:

```swift
MyCustomCard()
    .performanceTracked("MyCustomCard")
    .trackCardUsage("MyCustomCard", action: .appeared)
```

## 🐛 Troubleshooting

### Common Issues

1. **Import Errors**: Ensure all component files are in your target
2. **Token Not Found**: Check DesignTokens.swift for available tokens
3. **Performance Issues**: Use PerformanceMonitor to identify bottlenecks
4. **Accessibility Issues**: Test with VoiceOver enabled

### Debug Mode Features

- Migration notices on legacy components
- Performance overlay
- Accessibility hints
- Token usage validation

## 📚 Advanced Usage

### Custom Card Styles

```swift
struct MyCustomCardStyle: CardStyling {
    let backgroundColor = SemanticColor.customBackground
    let cornerRadius = CornerRadius.large
    let padding = Spacing.md
    let shadow = ShadowStyle.large
    let borderColor: SemanticColor? = nil
    let borderWidth: CGFloat = 0
}
```

### Custom Interactions

```swift
struct MyInteractiveCard: View {
    @StateObject private var stateManager = InteractionStateManager()
    
    var body: some View {
        BaseCard {
            // Content
        }
        .interactive(
            onTap: { /* tap action */ },
            onLongPress: { /* long press action */ }
        )
    }
}
```

### Performance Optimization

```swift
// Measure custom operations
let operationId = PerformanceMonitor.shared.startOperation("custom_operation")
// ... perform operation
PerformanceMonitor.shared.endOperation(operationId, name: "custom_operation")
```

## 🎯 Best Practices

### Do's

- ✅ Use semantic tokens exclusively
- ✅ Follow 300-line file limit
- ✅ Add accessibility labels
- ✅ Test with all accessibility settings
- ✅ Monitor performance
- ✅ Use BaseCard for consistency

### Don'ts

- ❌ Use direct Color/Font/Spacing values
- ❌ Create monolithic components
- ❌ Ignore accessibility requirements
- ❌ Skip performance testing
- ❌ Hardcode interaction patterns

## 📝 Contributing

1. Follow the design token system
2. Keep files under 300 lines
3. Add accessibility support
4. Include in preview catalog
5. Monitor performance impact
6. Update documentation

---

**🎉 Ready to build amazing, consistent UIs with enterprise-level quality!**