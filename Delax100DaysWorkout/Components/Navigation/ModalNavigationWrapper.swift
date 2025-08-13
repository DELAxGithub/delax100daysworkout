import SwiftUI

// MARK: - Modal Navigation Wrapper
/// 統一モーダルナビゲーションコンポーネント
/// 一貫性のあるナビゲーション体験を提供し、コード重複を削減

struct ModalNavigationWrapper<Content: View>: View {
    let title: String
    let onDismiss: () -> Void
    let content: Content
    let showingCloseButton: Bool
    
    init(
        title: String,
        showingCloseButton: Bool = true,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showingCloseButton = showingCloseButton
        self.onDismiss = onDismiss
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if showingCloseButton {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("閉じる") {
                                HapticManager.shared.trigger(.impact(.light))
                                onDismiss()
                            }
                            .font(Typography.bodyMedium.font)
                            .foregroundColor(SemanticColor.primaryAction)
                        }
                    }
                }
                .interactiveDismissDisabled(false)
        }
        .accessibilityLabel("\(title)画面")
        .accessibilityHint("下にスワイプして閉じることができます")
    }
}

// MARK: - Modal Presentation Style

enum ModalPresentationStyle {
    case sheet
    case fullScreenCover
    case detent([UISheetPresentationController.Detent])
    
    var isFullScreen: Bool {
        switch self {
        case .fullScreenCover:
            return true
        default:
            return false
        }
    }
}

// MARK: - Enhanced Modal Navigation

struct EnhancedModalPresentation<ContentType: View>: ViewModifier {
    @Binding var isPresented: Bool
    let style: ModalPresentationStyle
    let onDismiss: (() -> Void)?
    let modalContent: ContentType
    
    init(
        isPresented: Binding<Bool>,
        style: ModalPresentationStyle = .sheet,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> ContentType
    ) {
        self._isPresented = isPresented
        self.style = style
        self.onDismiss = onDismiss
        self.modalContent = content()
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                modalContent
            }
    }
}

// MARK: - View Extension

extension View {
    func modalNavigation<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        style: ModalPresentationStyle = .sheet,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
            ModalNavigationWrapper(
                title: title,
                onDismiss: { isPresented.wrappedValue = false }
            ) {
                content()
            }
        }
    }
}

// MARK: - Navigation Performance Monitoring

extension ModalNavigationWrapper {
    func performanceTracked(_ screenName: String) -> some View {
        self.onAppear {
            let _ = PerformanceMonitor.shared.startOperation("modal_\(screenName)")
        }
        .onDisappear {
            PerformanceMonitor.shared.endOperation("modal_\(screenName)", name: "Modal Navigation")
        }
    }
}

#Preview {
    @Previewable @State var showingModal = true
    
    return Color.clear
        .modalNavigation(
            isPresented: $showingModal,
            title: "サンプル画面"
        ) {
            VStack {
                Text("モーダル画面の内容")
                    .font(Typography.headlineMedium.font)
                
                Button("閉じる") {
                    showingModal = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
}