import SwiftUI

// MARK: - Dynamic Type Catalog

struct DynamicTypeCatalog: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg.value) {
                CatalogSection("Current Dynamic Type") {
                    BaseCard {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            Text("Current Size: \(dynamicTypeSize.description)")
                                .font(Typography.headlineMedium.font)
                            
                            Text("This text adapts to your system text size setting.")
                                .font(Typography.bodyMedium.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                }
                
                CatalogSection("Typography Scaling") {
                    VStack(spacing: Spacing.sm.value) {
                        DynamicTypeExample(name: "Display", typography: .displayMedium)
                        DynamicTypeExample(name: "Headline", typography: .headlineMedium)
                        DynamicTypeExample(name: "Body", typography: .bodyMedium)
                        DynamicTypeExample(name: "Caption", typography: .captionMedium)
                    }
                }
                
                CatalogSection("Accessibility Tips") {
                    BaseCard {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            Text("Best Practices")
                                .font(Typography.headlineMedium.font)
                            
                            Text("• Use semantic font styles")
                                .font(Typography.bodySmall.font)
                            Text("• Test with largest accessibility sizes")
                                .font(Typography.bodySmall.font)
                            Text("• Avoid fixed heights with text")
                                .font(Typography.bodySmall.font)
                            Text("• Provide alternative layouts for XL sizes")
                                .font(Typography.bodySmall.font)
                        }
                        .foregroundColor(SemanticColor.primaryText)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dynamic Type")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DynamicTypeExample: View {
    let name: String
    let typography: Typography
    
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                Text("Sample \(name) Text")
                    .font(typography.font)
                    .foregroundColor(SemanticColor.primaryText)
                
                Text("\(name) - Scales with Dynamic Type")
                    .font(Typography.captionSmall.font)
                    .foregroundColor(SemanticColor.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - VoiceOver Catalog

struct VoiceOverCatalog: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg.value) {
                CatalogSection("VoiceOver Status") {
                    BaseCard {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            Text("VoiceOver: \(voiceOverEnabled ? "Enabled" : "Disabled")")
                                .font(Typography.headlineMedium.font)
                                .foregroundColor(voiceOverEnabled ? SemanticColor.successAction : SemanticColor.secondaryText)
                            
                            Text("This demo shows accessibility-friendly components")
                                .font(Typography.bodySmall.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                }
                
                CatalogSection("Accessible Cards") {
                    BaseCard {
                        SampleCardContent(title: "Workout Card", subtitle: "Cycling workout")
                    }
                    .accessibilityCardButton(
                        label: "Cycling workout card",
                        hint: "Double tap to open workout details"
                    )
                    
                    BaseCard {
                        SampleCardContent(title: "Task Card", subtitle: "Daily task")
                    }
                    .accessibilityCardButton(
                        label: "Daily task card",
                        hint: "Double tap to complete, or use rotor for more actions"
                    )
                }
                
                CatalogSection("Accessibility Guidelines") {
                    BaseCard {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            Text("VoiceOver Best Practices")
                                .font(Typography.headlineMedium.font)
                                .accessibilityAddTraits(.isHeader)
                            
                            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                                AccessibilityTip(text: "Provide meaningful labels")
                                AccessibilityTip(text: "Include action hints")
                                AccessibilityTip(text: "Group related elements")
                                AccessibilityTip(text: "Test with VoiceOver enabled")
                            }
                        }
                        .foregroundColor(SemanticColor.primaryText)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("VoiceOver Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccessibilityTip: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs.value) {
            Text("•")
                .font(Typography.bodySmall.font)
            Text(text)
                .font(Typography.bodySmall.font)
        }
    }
}

// MARK: - Reduce Motion Catalog

struct ReduceMotionCatalog: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotionEnabled
    @State private var isAnimating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg.value) {
                CatalogSection("Reduce Motion Status") {
                    BaseCard {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            Text("Reduce Motion: \(reduceMotionEnabled ? "Enabled" : "Disabled")")
                                .font(Typography.headlineMedium.font)
                                .foregroundColor(reduceMotionEnabled ? SemanticColor.warningAction : SemanticColor.successAction)
                            
                            Text("Animations respect this accessibility setting")
                                .font(Typography.bodySmall.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                }
                
                CatalogSection("Adaptive Animations") {
                    BaseCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Adaptive Animation")
                                    .font(Typography.headlineMedium.font)
                                Text(reduceMotionEnabled ? "Reduced animation" : "Full animation")
                                    .font(Typography.bodySmall.font)
                                    .foregroundColor(SemanticColor.secondaryText)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(SemanticColor.primaryAction.color)
                                .frame(width: 30, height: 30)
                                .scaleEffect(isAnimating ? 1.3 : 1.0)
                                .adaptiveAnimation(AnimationStandards.bounce, value: isAnimating)
                        }
                    }
                }
                
                Button(isAnimating ? "Stop Animation" : "Start Animation") {
                    isAnimating.toggle()
                }
                .buttonStyle(.borderedProminent)
                
                CatalogSection("Motion Guidelines") {
                    BaseCard {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            Text("Reduce Motion Guidelines")
                                .font(Typography.headlineMedium.font)
                            
                            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                                AccessibilityTip(text: "Always provide alternative static states")
                                AccessibilityTip(text: "Use AnimationStandards.adaptive() for animations")
                                AccessibilityTip(text: "Essential motion can be reduced but not removed")
                                AccessibilityTip(text: "Test with Reduce Motion enabled")
                            }
                        }
                        .foregroundColor(SemanticColor.primaryText)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Reduce Motion")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Extensions

extension DynamicTypeSize {
    var description: String {
        switch self {
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (Default)"
        case .xLarge: return "Extra Large"
        case .xxLarge: return "Extra Extra Large"
        case .xxxLarge: return "Extra Extra Extra Large"
        case .accessibility1: return "Accessibility Medium"
        case .accessibility2: return "Accessibility Large"
        case .accessibility3: return "Accessibility Extra Large"
        case .accessibility4: return "Accessibility Extra Extra Large"
        case .accessibility5: return "Accessibility Extra Extra Extra Large"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Preview

#Preview("Dynamic Type Catalog") {
    NavigationStack {
        DynamicTypeCatalog()
    }
}

#Preview("VoiceOver Catalog") {
    NavigationStack {
        VoiceOverCatalog()
    }
}

#Preview("Reduce Motion Catalog") {
    NavigationStack {
        ReduceMotionCatalog()
    }
}