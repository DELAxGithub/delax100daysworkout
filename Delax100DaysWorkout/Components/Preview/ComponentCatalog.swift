import SwiftUI

// MARK: - Component Catalog (Main Navigation)

struct ComponentCatalog: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Cards") {
                    NavigationLink("BaseCard Examples", destination: BaseCardCatalog())
                    NavigationLink("Card Styles", destination: CardStyleCatalog())
                    NavigationLink("Card States", destination: CardStateCatalog())
                }
                
                Section("Tokens") {
                    NavigationLink("Colors", destination: ColorTokenCatalog())
                    NavigationLink("Typography", destination: TypographyCatalog())
                    NavigationLink("Spacing", destination: SpacingCatalog())
                }
                
                Section("Interactions") {
                    NavigationLink("Gestures", destination: GestureCatalog())
                    NavigationLink("Animations", destination: AnimationCatalog())
                    NavigationLink("Haptics", destination: HapticCatalog())
                }
                
                Section("Accessibility") {
                    NavigationLink("Dynamic Type", destination: DynamicTypeCatalog())
                    NavigationLink("VoiceOver", destination: VoiceOverCatalog())
                    NavigationLink("Reduce Motion", destination: ReduceMotionCatalog())
                }
            }
            .navigationTitle("Component Catalog")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - BaseCard Catalog

struct BaseCardCatalog: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md.value) {
                CatalogSection("Default Cards") {
                    BaseCard {
                        SampleCardContent(title: "Default Card", subtitle: "Standard styling")
                    }
                    
                    BaseCard.summary {
                        SampleCardContent(title: "Summary Card", subtitle: "Elevated styling")
                    }
                }
                
                CatalogSection("Interactive Cards") {
                    BaseCard.workout(onTap: {}) {
                        SampleCardContent(title: "Workout Card", subtitle: "Tap to interact")
                    }
                    
                    BaseCard.task(onTap: {}, onLongPress: {}) {
                        SampleCardContent(title: "Task Card", subtitle: "Tap or long press")
                    }
                }
                
                CatalogSection("Selectable Cards") {
                    BaseCard.selectable(isSelected: false, onTap: {}) {
                        SampleCardContent(title: "Unselected", subtitle: "Tap to select")
                    }
                    
                    BaseCard.selectable(isSelected: true, onTap: {}) {
                        SampleCardContent(title: "Selected", subtitle: "Currently selected")
                    }
                }
                
                CatalogSection("Loading States") {
                    BaseCard(configuration: .loading) {
                        SampleCardContent(title: "Hidden", subtitle: "Content is hidden")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("BaseCard Examples")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Components

struct CatalogSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.value) {
            Text(title)
                .font(Typography.headlineSmall.font)
                .foregroundColor(SemanticColor.primaryText)
                .padding(.horizontal, Spacing.xs.value)
            
            content
        }
    }
}

struct SampleCardContent: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.value) {
            Text(title)
                .font(Typography.headlineMedium.font)
                .foregroundColor(SemanticColor.primaryText)
            
            Text(subtitle)
                .font(Typography.bodySmall.font)
                .foregroundColor(SemanticColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Component Catalog") {
    ComponentCatalog()
}