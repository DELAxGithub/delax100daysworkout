import Foundation
import SwiftUI
import OSLog

@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var isShowingError = false
    @Published var isShowingInlineError = false
    @Published var errorDisplayStyle: ErrorDisplayStyle = .alert
    
    enum ErrorDisplayStyle {
        case alert
        case inline
        case toast
    }
    
    func handle(_ error: Error, style: ErrorDisplayStyle = .alert) {
        Logger.error.error("Error handled: \(error.localizedDescription)")
        
        let appError = convertToAppError(error)
        self.currentError = appError
        self.errorDisplayStyle = style
        
        // Trigger haptic feedback
        InteractionFeedback.error()
        
        switch style {
        case .alert:
            self.isShowingError = true
        case .inline, .toast:
            self.isShowingInlineError = true
        }
    }
    
    func handleSwiftDataError(_ error: Error, context: String = "") {
        Logger.database.error("SwiftData error in \(context): \(error.localizedDescription)")
        let appError = AppError.swiftDataOperationFailed(context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)")
        handle(appError, style: .inline)
    }
    
    func handleNetworkError(_ error: Error) {
        Logger.network.error("Network error: \(error.localizedDescription)")
        handle(error, style: .alert)
    }
    
    func dismiss() {
        currentError = nil
        isShowingError = false
        isShowingInlineError = false
    }
    
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // URLError handling
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .userCancelledAuthentication:
                return .authenticationFailed
            case .cancelled:
                return .userCancelled
            default:
                return .unknown(error)
            }
        }
        
        // SwiftData errors
        if error.localizedDescription.contains("SwiftData") || 
           error.localizedDescription.contains("CoreData") {
            return .swiftDataOperationFailed(error.localizedDescription)
        }
        
        return .unknown(error)
    }
}

// MARK: - Error Display Components

// Traditional Error Alert Modifier
struct ErrorAlert: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert("エラーが発生しました", isPresented: $errorHandler.isShowingError) {
                Button("OK") {
                    errorHandler.dismiss()
                }
            } message: {
                if let error = errorHandler.currentError {
                    VStack(alignment: .leading) {
                        Text(error.localizedDescription)
                        if let recovery = error.recoverySuggestion {
                            Text(recovery)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
    }
}

// BaseCard Error Display Component
struct ErrorCard: View {
    let error: AppError
    let onDismiss: () -> Void
    let style: ErrorHandler.ErrorDisplayStyle
    
    var body: some View {
        BaseCard(
            style: errorCardStyle(),
            onTap: onDismiss
        ) {
            HStack(spacing: Spacing.sm.value) {
                Image(systemName: errorIcon())
                    .foregroundColor(errorColor())
                    .font(.title3)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    Text(error.localizedDescription)
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                        .multilineTextAlignment(.leading)
                    
                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                            .font(Typography.bodySmall.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SemanticColor.tertiaryText.color)
                        .font(.title3)
                }
                .accessibilityLabel("エラーを閉じる")
            }
            .padding(Spacing.md.value)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("エラー: \(error.localizedDescription)")
        .accessibilityHint("タップしてエラーを閉じる")
    }
    
    private func errorCardStyle() -> any CardStyling {
        switch style {
        case .toast:
            return ToastErrorCardStyle()
        default:
            return ErrorCardStyle()
        }
    }
    
    private func errorIcon() -> String {
        switch error {
        case .networkUnavailable:
            return "wifi.slash"
        case .databaseError, .swiftDataOperationFailed:
            return "externaldrive.badge.xmark"
        case .authenticationFailed:
            return "lock.slash"
        case .dataCorrupted:
            return "doc.badge.exclamationmark"
        case .fileOperationFailed:
            return "folder.badge.minus"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    private func errorColor() -> Color {
        .red
    }
}

// Error Card Styles
struct ErrorCardStyle: CardStyling {
    let backgroundColor: SemanticColor = .secondaryBackground
    let cornerRadius: CornerRadius = .large
    let padding: Spacing = .md
    let shadow: ShadowStyle = .medium
    let borderColor: SemanticColor? = .errorAction
    let borderWidth: CGFloat = 1.0
}

struct ToastErrorCardStyle: CardStyling {
    let backgroundColor: SemanticColor = .cardBackground
    let cornerRadius: CornerRadius = .medium
    let padding: Spacing = .md
    let shadow: ShadowStyle = .large
    let borderColor: SemanticColor? = .errorAction
    let borderWidth: CGFloat = 1.0
}

// Inline Error Display Modifier
struct InlineErrorDisplay: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        VStack(spacing: Spacing.sm.value) {
            if errorHandler.isShowingInlineError, 
               let error = errorHandler.currentError {
                ErrorCard(
                    error: error,
                    onDismiss: { errorHandler.dismiss() },
                    style: errorHandler.errorDisplayStyle
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.3), value: errorHandler.isShowingInlineError)
            }
            
            content
        }
    }
}

// Toast Error Display Modifier
struct ToastErrorDisplay: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if errorHandler.isShowingInlineError && errorHandler.errorDisplayStyle == .toast,
               let error = errorHandler.currentError {
                VStack {
                    ErrorCard(
                        error: error,
                        onDismiss: { errorHandler.dismiss() },
                        style: .toast
                    )
                    .padding(.horizontal)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: errorHandler.isShowingInlineError)
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func errorAlert(_ errorHandler: ErrorHandler) -> some View {
        modifier(ErrorAlert(errorHandler: errorHandler))
    }
    
    func inlineErrorDisplay(_ errorHandler: ErrorHandler) -> some View {
        modifier(InlineErrorDisplay(errorHandler: errorHandler))
    }
    
    func toastErrorDisplay(_ errorHandler: ErrorHandler) -> some View {
        modifier(ToastErrorDisplay(errorHandler: errorHandler))
    }
    
    func unifiedErrorHandling(_ errorHandler: ErrorHandler) -> some View {
        self
            .errorAlert(errorHandler)
            .inlineErrorDisplay(errorHandler)
            .toastErrorDisplay(errorHandler)
    }
}