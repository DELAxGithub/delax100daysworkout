import SwiftUI
import os.log

/// Centralized error handler for the entire application
/// Manages error presentation, logging, and recovery
@MainActor
final class ErrorHandler: ObservableObject {
    // MARK: - Singleton
    static let shared = ErrorHandler()
    
    // MARK: - Published Properties
    @Published var currentError: AppError?
    @Published var isShowingError = false
    @Published var errorHistory: [ErrorRecord] = []
    
    // MARK: - Error Record
    struct ErrorRecord: Identifiable {
        let id = UUID()
        let error: AppError
        let timestamp: Date
        let context: String?
        let file: String
        let function: String
        let line: Int
    }
    
    // MARK: - Configuration
    struct Configuration {
        var enableLogging = true
        var enableCrashReporting = false
        var maxErrorHistory = 100
        var autoDismissDelay: TimeInterval? = nil
    }
    
    var configuration = Configuration()
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.delax100daysworkout", category: "ErrorHandler")
    
    // MARK: - Private Properties
    private var dismissTask: Task<Void, Never>?
    private var recoveryHandlers: [String: (AppError) async -> Bool] = [:]
    
    // MARK: - Initialization
    private init() {
        setupDefaultRecoveryHandlers()
    }
    
    // MARK: - Public Methods
    
    /// Handle an error with optional context information
    func handle(
        _ error: Error,
        context: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let appError = AppError.from(error)
        
        // Create error record
        let record = ErrorRecord(
            error: appError,
            timestamp: Date(),
            context: context,
            file: file,
            function: function,
            line: line
        )
        
        // Add to history
        errorHistory.append(record)
        if errorHistory.count > configuration.maxErrorHistory {
            errorHistory.removeFirst()
        }
        
        // Log error
        if configuration.enableLogging {
            logError(record)
        }
        
        // Update UI
        currentError = appError
        isShowingError = true
        
        // Auto-dismiss if configured
        if let delay = configuration.autoDismissDelay {
            dismissTask?.cancel()
            dismissTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                if !Task.isCancelled {
                    await MainActor.run {
                        self.dismiss()
                    }
                }
            }
        }
        
        // Attempt automatic recovery
        Task {
            await attemptRecovery(for: appError)
        }
    }
    
    /// Handle an error with async context
    func handleAsync(
        _ error: Error,
        context: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await MainActor.run {
            handle(error, context: context, file: file, function: function, line: line)
        }
    }
    
    /// Dismiss current error
    func dismiss() {
        currentError = nil
        isShowingError = false
        dismissTask?.cancel()
    }
    
    /// Clear error history
    func clearHistory() {
        errorHistory.removeAll()
    }
    
    /// Register a custom recovery handler for specific error codes
    func registerRecoveryHandler(
        for errorCode: String,
        handler: @escaping (AppError) async -> Bool
    ) {
        recoveryHandlers[errorCode] = handler
    }
    
    // MARK: - Private Methods
    
    private func logError(_ record: ErrorRecord) {
        let fileName = URL(fileURLWithPath: record.file).lastPathComponent
        let location = "\(fileName):\(record.line) in \(record.function)"
        
        switch record.error.severity {
        case .low:
            logger.info("Error [\(record.error.errorCode)]: \(record.error.localizedDescription) at \(location)")
        case .medium:
            logger.warning("Error [\(record.error.errorCode)]: \(record.error.localizedDescription) at \(location)")
        case .high:
            logger.error("Error [\(record.error.errorCode)]: \(record.error.localizedDescription) at \(location)")
        case .critical:
            logger.critical("Error [\(record.error.errorCode)]: \(record.error.localizedDescription) at \(location)")
        }
        
        if let context = record.context {
            logger.debug("Context: \(context)")
        }
        
        if let underlyingError = record.error.underlyingError {
            logger.debug("Underlying error: \(String(describing: underlyingError))")
        }
    }
    
    private func attemptRecovery(for error: AppError) async {
        // Check for registered recovery handler
        if let handler = recoveryHandlers[error.errorCode] {
            let recovered = await handler(error)
            if recovered {
                await MainActor.run {
                    dismiss()
                }
            }
        }
        
        // Default recovery attempts
        switch error {
        case .networkUnavailable:
            // Could implement network reachability monitoring
            break
        case .unauthorized:
            // Could trigger re-authentication flow
            break
        default:
            break
        }
    }
    
    private func setupDefaultRecoveryHandlers() {
        // Network recovery
        registerRecoveryHandler(for: "NET_001") { _ in
            // Check network connectivity
            // Return true if network is now available
            return false
        }
        
        // Add more default recovery handlers as needed
    }
}

// MARK: - View Modifier for Error Presentation
struct ErrorHandlerModifier: ViewModifier {
    @ObservedObject var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                "エラー",
                isPresented: $errorHandler.isShowingError,
                presenting: errorHandler.currentError
            ) { error in
                Button("OK") {
                    errorHandler.dismiss()
                }
                
                if let suggestion = error.recoverySuggestion {
                    Button("詳細") {
                        // Could show more detailed error information
                    }
                }
            } message: { error in
                VStack {
                    Text(error.localizedDescription)
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func withErrorHandling() -> some View {
        self.modifier(ErrorHandlerModifier())
    }
}

// MARK: - Error Reporting Extension
extension ErrorHandler {
    /// Generate error report for debugging
    func generateErrorReport() -> String {
        var report = "Error Report\n"
        report += "Generated: \(Date())\n"
        report += "Total Errors: \(errorHistory.count)\n\n"
        
        for record in errorHistory.suffix(10) {
            report += "[\(record.timestamp)] \(record.error.errorCode): \(record.error.localizedDescription)\n"
            if let context = record.context {
                report += "  Context: \(context)\n"
            }
            report += "  Location: \(URL(fileURLWithPath: record.file).lastPathComponent):\(record.line)\n"
            report += "\n"
        }
        
        return report
    }
    
    /// Export error history for analysis
    func exportErrorHistory() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = errorHistory.map { record in
            [
                "id": record.id.uuidString,
                "errorCode": record.error.errorCode,
                "description": record.error.localizedDescription,
                "timestamp": ISO8601DateFormatter().string(from: record.timestamp),
                "context": record.context ?? "",
                "file": URL(fileURLWithPath: record.file).lastPathComponent,
                "function": record.function,
                "line": "\(record.line)"
            ]
        }
        
        return try? encoder.encode(exportData)
    }
}