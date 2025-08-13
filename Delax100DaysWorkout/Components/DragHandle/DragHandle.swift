import SwiftUI

// MARK: - Unified Drag Handle Component

struct DragHandle: View {
    let size: DragHandleSize
    let style: DragHandleStyle
    let isActive: Bool
    
    init(
        size: DragHandleSize = .medium,
        style: DragHandleStyle = .default,
        isActive: Bool = false
    ) {
        self.size = size
        self.style = style
        self.isActive = isActive
    }
    
    var body: some View {
        VStack(spacing: size.spacing) {
            ForEach(0..<3, id: \.self) { _ in
                Rectangle()
                    .fill(isActive ? style.activeColor : style.inactiveColor)
                    .frame(
                        width: size.width,
                        height: size.height
                    )
                    .cornerRadius(size.cornerRadius)
            }
        }
        .opacity(isActive ? 1.0 : 0.6)
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Configuration Types

enum DragHandleSize {
    case small
    case medium
    case large
    
    var width: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small: return 1.5
        case .medium: return 2
        case .large: return 2.5
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        }
    }
    
    var cornerRadius: CGFloat {
        height / 2
    }
}

enum DragHandleStyle {
    case `default`
    case subtle
    case prominent
    
    var inactiveColor: Color {
        switch self {
        case .default:
            return SemanticColor.secondaryText.color
        case .subtle:
            return SemanticColor.secondaryText.color.opacity(0.3)
        case .prominent:
            return SemanticColor.primaryAction.color
        }
    }
    
    var activeColor: Color {
        switch self {
        case .default:
            return SemanticColor.primaryAction.color
        case .subtle:
            return SemanticColor.secondaryText.color
        case .prominent:
            return SemanticColor.primaryAction.color
        }
    }
}

// MARK: - Draggable Container

struct DraggableContainer<Content: View>: View {
    let content: Content
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    let dragData: () -> NSItemProvider
    
    @State private var isDragging = false
    
    init(
        onDragStart: @escaping () -> Void = {},
        onDragEnd: @escaping () -> Void = {},
        dragData: @escaping () -> NSItemProvider,
        @ViewBuilder content: () -> Content
    ) {
        self.onDragStart = onDragStart
        self.onDragEnd = onDragEnd
        self.dragData = dragData
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm.value) {
            DragHandle(
                size: .medium,
                style: .default,
                isActive: isDragging
            )
            .accessibilityLabel("ドラッグハンドル")
            .accessibilityHint("このアイテムを移動するにはドラッグしてください")
            
            content
        }
        .opacity(isDragging ? 0.8 : 1.0)
        .scaleEffect(isDragging ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .onDrag {
            isDragging = true
            onDragStart()
            HapticManager.shared.trigger(.impact(.medium))
            return dragData()
        }
        .onAppear {
            if isDragging {
                isDragging = false
                onDragEnd()
            }
        }
    }
}

// MARK: - Drop Zone

struct DropZone<Content: View>: View {
    let content: Content
    let onDrop: ([NSItemProvider]) -> Bool
    let isTargeted: Binding<Bool>?
    
    @State private var isDropTarget = false
    
    init(
        isTargeted: Binding<Bool>? = nil,
        onDrop: @escaping ([NSItemProvider]) -> Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.isTargeted = isTargeted
        self.onDrop = onDrop
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium.radius)
                    .fill(SemanticColor.primaryAction.color.opacity(isDropTarget ? 0.1 : 0.0))
                    .stroke(
                        SemanticColor.primaryAction.color,
                        lineWidth: isDropTarget ? 2 : 0
                    )
            )
            .onDrop(
                of: [.text],
                isTargeted: isTargeted ?? Binding.constant(false)
            ) { providers in
                let result = onDrop(providers)
                if result {
                    HapticManager.shared.trigger(.impact(.light))
                }
                return result
            }
            .animation(.easeInOut(duration: 0.2), value: isDropTarget)
    }
}

// MARK: - Preview

#Preview("Drag Handle Components") {
    VStack(spacing: Spacing.lg.value) {
        // Drag Handle Sizes
        HStack(spacing: Spacing.md.value) {
            VStack {
                DragHandle(size: .small)
                Text("Small")
                    .font(.caption)
            }
            
            VStack {
                DragHandle(size: .medium)
                Text("Medium")
                    .font(.caption)
            }
            
            VStack {
                DragHandle(size: .large)
                Text("Large")
                    .font(.caption)
            }
        }
        
        Divider()
        
        // Drag Handle Styles
        HStack(spacing: Spacing.md.value) {
            VStack {
                DragHandle(style: .default)
                Text("Default")
                    .font(.caption)
            }
            
            VStack {
                DragHandle(style: .subtle)
                Text("Subtle")
                    .font(.caption)
            }
            
            VStack {
                DragHandle(style: .prominent)
                Text("Prominent")
                    .font(.caption)
            }
        }
        
        Divider()
        
        // Sample Draggable Item
        DraggableContainer(
            dragData: {
                NSItemProvider(object: "Sample Item" as NSString)
            }
        ) {
            BaseCard {
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    Text("サンプルタスク")
                        .font(Typography.headlineMedium.font)
                    Text("ドラッグして移動できます")
                        .font(Typography.bodySmall.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                }
            }
        }
    }
    .padding()
    .background(SemanticColor.primaryBackground.color)
}