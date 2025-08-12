import SwiftUI

// MARK: - Gesture Catalog

struct GestureCatalog: View {
    @State private var tapCount = 0
    @State private var longPressCount = 0
    @State private var swipeDirection = "None"
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg.value) {
                CatalogSection("Tap Gestures") {
                    BaseCard {
                        VStack {
                            Text("Tap Me")
                                .font(Typography.headlineMedium.font)
                            Text("Tapped: \(tapCount) times")
                                .font(Typography.bodySmall.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                    .standardTap {
                        tapCount += 1
                    }
                }
                
                CatalogSection("Long Press Gestures") {
                    BaseCard {
                        VStack {
                            Text("Long Press Me")
                                .font(Typography.headlineMedium.font)
                            Text("Long Pressed: \(longPressCount) times")
                                .font(Typography.bodySmall.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                    .standardLongPress {
                        longPressCount += 1
                    }
                }
                
                CatalogSection("Swipe Gestures") {
                    BaseCard {
                        VStack {
                            Text("Swipe Me")
                                .font(Typography.headlineMedium.font)
                            Text("Last Swipe: \(swipeDirection)")
                                .font(Typography.bodySmall.font)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                    .standardSwipe(.left) { swipeDirection = "Left" }
                    .standardSwipe(.right) { swipeDirection = "Right" }
                    .standardSwipe(.up) { swipeDirection = "Up" }
                    .standardSwipe(.down) { swipeDirection = "Down" }
                }
                
                Button("Reset Counters") {
                    tapCount = 0
                    longPressCount = 0
                    swipeDirection = "None"
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Gesture Examples")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Animation Catalog

struct AnimationCatalog: View {
    @State private var isAnimating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg.value) {
                CatalogSection("Basic Animations") {
                    AnimationDemo("Quick", animation: AnimationStandards.quick, isAnimating: $isAnimating)
                    AnimationDemo("Standard", animation: AnimationStandards.standard, isAnimating: $isAnimating)
                    AnimationDemo("Smooth", animation: AnimationStandards.smooth, isAnimating: $isAnimating)
                }
                
                CatalogSection("Spring Animations") {
                    AnimationDemo("Bounce", animation: AnimationStandards.bounce, isAnimating: $isAnimating)
                    AnimationDemo("Gentle", animation: AnimationStandards.gentle, isAnimating: $isAnimating)
                    AnimationDemo("Snappy", animation: AnimationStandards.snappy, isAnimating: $isAnimating)
                }
                
                Button(isAnimating ? "Stop Animations" : "Start Animations") {
                    isAnimating.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Animation Examples")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnimationDemo: View {
    let name: String
    let animation: Animation
    @Binding var isAnimating: Bool
    
    var body: some View {
        BaseCard {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(Typography.headlineMedium.font)
                    Text("Animation example")
                        .font(Typography.bodySmall.font)
                        .foregroundColor(SemanticColor.secondaryText)
                }
                
                Spacer()
                
                Circle()
                    .fill(SemanticColor.primaryAction.color)
                    .frame(width: 20, height: 20)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .animation(isAnimating ? animation.repeatForever() : .default, value: isAnimating)
            }
        }
    }
}

// MARK: - Haptic Catalog

struct HapticCatalog: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg.value) {
                CatalogSection("Impact Feedback") {
                    HapticButton("Light Impact", haptic: .impact(.light))
                    HapticButton("Medium Impact", haptic: .impact(.medium))
                    HapticButton("Heavy Impact", haptic: .impact(.heavy))
                }
                
                CatalogSection("Selection Feedback") {
                    HapticButton("Selection", haptic: .selection)
                }
                
                CatalogSection("Notification Feedback") {
                    HapticButton("Success", haptic: .notification(.success))
                    HapticButton("Warning", haptic: .notification(.warning))
                    HapticButton("Error", haptic: .notification(.error))
                }
                
                CatalogSection("Common Interactions") {
                    Button("Card Tap") { InteractionFeedback.cardTap() }
                        .buttonStyle(.bordered)
                    
                    Button("Card Long Press") { InteractionFeedback.cardLongPress() }
                        .buttonStyle(.bordered)
                    
                    Button("Card Swipe") { InteractionFeedback.cardSwipe() }
                        .buttonStyle(.bordered)
                    
                    Button("Selection Change") { InteractionFeedback.selectionChange() }
                        .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Haptic Examples")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HapticButton: View {
    let title: String
    let haptic: HapticType
    
    var body: some View {
        Button(title) {
            HapticManager.shared.trigger(haptic)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Gesture Catalog") {
    NavigationStack {
        GestureCatalog()
    }
}

#Preview("Animation Catalog") {
    NavigationStack {
        AnimationCatalog()
    }
}

#Preview("Haptic Catalog") {
    NavigationStack {
        HapticCatalog()
    }
}