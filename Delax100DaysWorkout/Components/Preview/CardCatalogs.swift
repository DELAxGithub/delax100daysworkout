import SwiftUI

// MARK: - Card Style Catalog

struct CardStyleCatalog: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md.value) {
                CatalogSection("Basic Styles") {
                    BaseCard(style: DefaultCardStyle()) {
                        SampleCardContent(title: "Default", subtitle: "Standard card styling")
                    }
                    
                    BaseCard(style: ElevatedCardStyle()) {
                        SampleCardContent(title: "Elevated", subtitle: "Large shadow styling")
                    }
                    
                    BaseCard(style: OutlinedCardStyle()) {
                        SampleCardContent(title: "Outlined", subtitle: "Border instead of shadow")
                    }
                }
                
                CatalogSection("Selectable Styles") {
                    BaseCard(style: SelectableCardStyle(isSelected: false)) {
                        SampleCardContent(title: "Unselected", subtitle: "Default selectable state")
                    }
                    
                    BaseCard(style: SelectableCardStyle(isSelected: true)) {
                        SampleCardContent(title: "Selected", subtitle: "Highlighted with border")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Card Styles")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Card State Catalog

struct CardStateCatalog: View {
    @State private var isPressed = false
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md.value) {
                CatalogSection("Interaction States") {
                    BaseCard {
                        SampleCardContent(title: "Normal", subtitle: "Default state")
                    }
                    
                    BaseCard {
                        SampleCardContent(title: "Pressed", subtitle: "Simulated press state")
                    }
                    .scaleEffect(0.96)
                }
                
                CatalogSection("Loading States") {
                    VStack(spacing: Spacing.sm.value) {
                        BaseCard(configuration: CardConfiguration(
                            loading: CardLoading(isLoading: true, loadingText: "読み込み中...")
                        )) {
                            SampleCardContent(title: "Hidden", subtitle: "Content hidden during loading")
                        }
                        
                        BaseCard(configuration: CardConfiguration(
                            loading: CardLoading(isLoading: true, shimmerEnabled: false)
                        )) {
                            SampleCardContent(title: "Hidden", subtitle: "Loading without shimmer")
                        }
                    }
                }
                
                CatalogSection("Interactive Demo") {
                    Button("Toggle Loading") {
                        withAnimation {
                            isLoading.toggle()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    BaseCard(configuration: CardConfiguration(
                        loading: CardLoading(isLoading: isLoading)
                    )) {
                        SampleCardContent(title: "Interactive", subtitle: "Toggle loading state above")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Card States")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Card Style Catalog") {
    NavigationStack {
        CardStyleCatalog()
    }
}

#Preview("Card State Catalog") {
    NavigationStack {
        CardStateCatalog()
    }
}