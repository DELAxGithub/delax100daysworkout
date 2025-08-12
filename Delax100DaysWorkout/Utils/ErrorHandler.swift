import Foundation
import SwiftUI
import OSLog

@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    func handle(_ error: Error) {
        Logger.error.error("Error handled: \(error.localizedDescription)")
        
        let appError = convertToAppError(error)
        self.currentError = appError
        self.isShowingError = true
    }
    
    func dismiss() {
        currentError = nil
        isShowingError = false
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
            return .databaseError(error.localizedDescription)
        }
        
        return .unknown(error)
    }
}

// Error Alert Modifier
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

extension View {
    func errorAlert(_ errorHandler: ErrorHandler) -> some View {
        modifier(ErrorAlert(errorHandler: errorHandler))
    }
}