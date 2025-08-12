import SwiftUI

// MARK: - Interaction State Management

@MainActor
class InteractionStateManager: ObservableObject {
    @Published var isPressed = false
    @Published var isHovered = false
    @Published var isDragging = false
    @Published var dragOffset: CGSize = .zero
    
    func startPress() {
        guard !isPressed else { return }
        isPressed = true
        InteractionFeedback.cardTap()
    }
    
    func endPress() {
        isPressed = false
    }
    
    func startHover() {
        isHovered = true
    }
    
    func endHover() {
        isHovered = false
    }
    
    func startDrag() {
        isDragging = true
    }
    
    func updateDrag(offset: CGSize) {
        dragOffset = offset
    }
    
    func endDrag() {
        isDragging = false
        withAnimation(AnimationStandards.adaptive(.spring(response: 0.3, dampingFraction: 0.7))) {
            dragOffset = .zero
        }
    }
    
    func reset() {
        isPressed = false
        isHovered = false
        isDragging = false
        dragOffset = .zero
    }
}

// MARK: - Interactive View Modifier

struct InteractiveViewModifier: ViewModifier {
    @StateObject private var stateManager = InteractionStateManager()
    
    let onTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    let pressScale: CGFloat
    
    init(
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        pressScale: CGFloat = 0.96
    ) {
        self.onTap = onTap
        self.onLongPress = onLongPress
        self.pressScale = pressScale
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(stateManager.isPressed ? pressScale : 1.0)
            .offset(stateManager.dragOffset)
            .onTapGesture {
                onTap?()
            }
            .onLongPressGesture(minimumDuration: GestureConfiguration.shared.adjustedLongPressDuration) {
                onLongPress?()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        stateManager.startPress()
                    }
                    .onEnded { _ in
                        stateManager.endPress()
                    }
            )
            .cardPressAnimation(value: stateManager.isPressed)
            .cardSwipeAnimation(value: stateManager.dragOffset)
    }
}

// MARK: - View Extensions

extension View {
    func interactive(
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        pressScale: CGFloat = 0.96
    ) -> some View {
        modifier(InteractiveViewModifier(
            onTap: onTap,
            onLongPress: onLongPress,
            pressScale: pressScale
        ))
    }
}