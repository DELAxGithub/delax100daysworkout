import SwiftUI

// MARK: - Card Visual Components

struct CardBackground: View {
    let style: CardStyling
    
    var body: some View {
        RoundedRectangle(
            cornerRadius: style.cornerRadius.radius,
            style: .continuous
        )
        .fill(style.backgroundColor.color)
        .overlay(borderOverlay)
        .shadow(
            color: shadowConfiguration.color,
            radius: shadowConfiguration.radius,
            x: shadowConfiguration.x,
            y: shadowConfiguration.y
        )
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if let borderColor = style.borderColor,
           style.borderWidth > 0 {
            RoundedRectangle(
                cornerRadius: style.cornerRadius.radius,
                style: .continuous
            )
            .strokeBorder(
                borderColor.color,
                lineWidth: style.borderWidth
            )
        }
    }
    
    private var shadowConfiguration: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        let shadow = style.shadow
        let offset = shadow.offset
        return (
            color: Color.black.opacity(shadow.opacity),
            radius: shadow.radius,
            x: offset.x,
            y: offset.y
        )
    }
}

// MARK: - Loading Components

struct CardLoadingView: View {
    let configuration: CardLoadingState
    let style: CardStyling
    
    var body: some View {
        ZStack {
            if configuration.shimmerEnabled {
                ShimmerEffect()
            }
            
            VStack(spacing: Spacing.sm.value) {
                ProgressView()
                    .scaleEffect(0.8)
                
                if let loadingText = configuration.loadingText {
                    Text(loadingText)
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                }
            }
        }
        .frame(minHeight: 60)
        .padding(style.padding.value)
        .background(style.backgroundColor.color.opacity(0.6))
        .clipShape(RoundedRectangle(
            cornerRadius: style.cornerRadius.radius,
            style: .continuous
        ))
    }
}

struct ShimmerEffect: View {
    @State private var shimmerOffset: CGFloat = -1
    @Environment(\.isReduceMotionEnabled) private var isReduceMotionEnabled
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .offset(x: shimmerOffset * UIScreen.main.bounds.width)
            .onAppear {
                guard !isReduceMotionEnabled else { return }
                
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 1
                }
            }
    }
}

// MARK: - Card Container

struct CardContainer<Content: View>: View {
    let configuration: CardConfiguration
    @ViewBuilder let content: Content
    
    @State private var isPressed = false
    @Environment(\.isReduceMotionEnabled) private var isReduceMotionEnabled
    
    var body: some View {
        content
            .padding(configuration.style.padding.value)
            .background(CardBackground(style: configuration.style))
            .scaleEffect(isPressed ? configuration.animation.pressedScale : 1.0)
            .contentShape(Rectangle())
            .modifier(AccessibilityModifier(configuration: configuration.accessibility))
            .modifier(InteractionModifier(
                configuration: configuration,
                isPressed: $isPressed
            ))
            .animation(
                isReduceMotionEnabled ? 
                    .linear(duration: 0.01) : 
                    .easeInOut(duration: configuration.animation.animationDuration),
                value: isPressed
            )
    }
}