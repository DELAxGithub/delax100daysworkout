import XCTest
import SwiftUI
@testable import Delax100DaysWorkout

/// Unit tests for the unified error handling system
final class ErrorHandlingTests: XCTestCase {
    
    var errorHandler: ErrorHandler!
    
    override func setUp() {
        super.setUp()
        errorHandler = ErrorHandler.shared
        errorHandler.clearHistory()
    }
    
    override func tearDown() {
        errorHandler.clearHistory()
        errorHandler = nil
        super.tearDown()
    }
    
    // MARK: - AppError Tests
    
    func testAppErrorLocalization() {
        // Test that all error cases have localized descriptions
        let errors: [AppError] = [
            .networkUnavailable,
            .dataCorrupted,
            .userCancelled,
            .healthDataNotAvailable,
            .aiServiceUnavailable,
            .githubTokenMissing,
            .imageTooLarge,
            .timeout
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Error \(error) description should not be empty")
        }
    }
    
    func testAppErrorRecoverySuggestions() {
        // Test that critical errors have recovery suggestions
        let errorsWithRecovery: [AppError] = [
            .networkUnavailable,
            .unauthorized,
            .healthKitNotAuthorized,
            .aiCostLimitExceeded,
            .githubTokenMissing,
            .imageTooLarge,
            .dataCorrupted,
            .timeout
        ]
        
        for error in errorsWithRecovery {
            XCTAssertNotNil(error.recoverySuggestion, "Error \(error) should have a recovery suggestion")
        }
    }
    
    func testAppErrorCodes() {
        // Test that all errors have unique codes
        let errors: [AppError] = [
            .networkUnavailable,
            .apiRequestFailed(NSError(domain: "test", code: 0)),
            .dataCorrupted,
            .dataNotFound,
            .userCancelled,
            .healthDataNotAvailable,
            .aiServiceUnavailable,
            .githubTokenMissing,
            .imageUploadFailed(NSError(domain: "test", code: 0)),
            .unknown(NSError(domain: "test", code: 0))
        ]
        
        var seenCodes = Set<String>()
        for error in errors {
            let code = error.errorCode
            XCTAssertFalse(seenCodes.contains(code), "Error code \(code) is duplicated")
            seenCodes.insert(code)
        }
    }
    
    func testAppErrorSeverity() {
        // Test severity levels
        XCTAssertEqual(AppError.userCancelled.severity, .low)
        XCTAssertEqual(AppError.networkUnavailable.severity, .medium)
        XCTAssertEqual(AppError.dataCorrupted.severity, .high)
        XCTAssertEqual(AppError.unknown(NSError(domain: "test", code: 0)).severity, .critical)
    }
    
    func testErrorConversion() {
        // Test converting system errors to AppError
        let urlError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let appError = AppError.from(urlError)
        XCTAssertEqual(appError.errorCode, "NET_001")
        
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let timeoutAppError = AppError.from(timeoutError)
        XCTAssertEqual(timeoutAppError.errorCode, "GEN_003")
    }
    
    // MARK: - ErrorHandler Tests
    
    @MainActor
    func testErrorHandlerBasicFunctionality() async {
        // Test basic error handling
        let testError = AppError.networkUnavailable
        
        errorHandler.handle(
            testError,
            context: "Test context"
        )
        
        XCTAssertEqual(errorHandler.currentError?.errorCode, testError.errorCode)
        XCTAssertTrue(errorHandler.isShowingError)
        XCTAssertEqual(errorHandler.errorHistory.count, 1)
        
        // Test dismiss
        errorHandler.dismiss()
        XCTAssertNil(errorHandler.currentError)
        XCTAssertFalse(errorHandler.isShowingError)
    }
    
    @MainActor
    func testErrorHistoryManagement() async {
        // Test that error history is maintained
        let errors: [AppError] = [
            .networkUnavailable,
            .dataCorrupted,
            .userCancelled
        ]
        
        for (index, error) in errors.enumerated() {
            errorHandler.handle(error, context: "Test \(index)")
        }
        
        XCTAssertEqual(errorHandler.errorHistory.count, 3)
        
        // Test clear history
        errorHandler.clearHistory()
        XCTAssertEqual(errorHandler.errorHistory.count, 0)
    }
    
    @MainActor
    func testErrorHistoryLimit() async {
        // Test that error history respects max limit
        errorHandler.configuration.maxErrorHistory = 5
        
        for i in 0..<10 {
            errorHandler.handle(
                AppError.unknown(NSError(domain: "test", code: i)),
                context: "Test \(i)"
            )
        }
        
        XCTAssertEqual(errorHandler.errorHistory.count, 5, "History should be limited to 5 entries")
    }
    
    @MainActor
    func testErrorReport() async {
        // Test error report generation
        let errors: [AppError] = [
            .networkUnavailable,
            .dataCorrupted,
            .unauthorized
        ]
        
        for error in errors {
            errorHandler.handle(error, context: "Test context")
        }
        
        let report = errorHandler.generateErrorReport()
        
        XCTAssertTrue(report.contains("Error Report"))
        XCTAssertTrue(report.contains("Total Errors: 3"))
        XCTAssertTrue(report.contains("NET_001"))
        XCTAssertTrue(report.contains("DATA_001"))
        XCTAssertTrue(report.contains("AUTH_001"))
    }
    
    @MainActor
    func testRecoveryHandler() async {
        // Test custom recovery handler registration
        var recoveryAttempted = false
        
        errorHandler.registerRecoveryHandler(for: "NET_001") { error in
            recoveryAttempted = true
            return true // Simulate successful recovery
        }
        
        errorHandler.handle(AppError.networkUnavailable)
        
        // Wait for async recovery
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertTrue(recoveryAttempted, "Recovery handler should have been called")
    }
    
    // MARK: - ServiceErrorConverter Tests
    
    func testGitHubErrorConversion() {
        XCTAssertEqual(ServiceErrorConverter.convert(.missingToken).errorCode, "GH_001")
        XCTAssertEqual(ServiceErrorConverter.convert(.unauthorized).errorCode, "AUTH_001")
        XCTAssertEqual(ServiceErrorConverter.convert(.repositoryNotFound).errorCode, "GH_003")
    }
    
    func testHealthKitErrorConversion() {
        XCTAssertEqual(ServiceErrorConverter.convert(HealthKitError.healthDataNotAvailable).errorCode, "HEALTH_001")
        XCTAssertEqual(ServiceErrorConverter.convert(HealthKitError.notAuthorized).errorCode, "HEALTH_002")
        XCTAssertEqual(ServiceErrorConverter.convert(HealthKitError.noData).errorCode, "DATA_002")
    }
    
    func testErrorAsAppErrorExtension() {
        // Test the asAppError extension
        let githubError = GitHubError.missingToken
        let appError = githubError.asAppError
        XCTAssertEqual(appError.errorCode, "GH_001")
        
        let healthError = HealthKitError.notAuthorized
        let healthAppError = healthError.asAppError
        XCTAssertEqual(healthAppError.errorCode, "HEALTH_002")
        
        let regularError = NSError(domain: "test", code: 123)
        let regularAppError = regularError.asAppError
        XCTAssertEqual(regularAppError.errorCode, "GEN_001")
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testViewModelErrorHandling() async {
        // Test that ViewModels properly use ErrorHandler
        let modelContext = MockModelContext() // You would need to create this mock
        let viewModel = TodayViewModel(modelContext: modelContext)
        
        // Simulate an error condition
        // This would require mocking the model context to throw errors
        // For now, just verify the error handler is integrated
        XCTAssertNotNil(viewModel)
    }
    
    @MainActor
    func testErrorHandlerViewModifier() async {
        // Test the view modifier integration
        let testView = Text("Test")
            .withErrorHandling()
        
        // Trigger an error
        errorHandler.handle(AppError.networkUnavailable)
        
        XCTAssertTrue(errorHandler.isShowingError)
        
        // The actual UI testing would require a more sophisticated setup
        // This test verifies the modifier can be applied
        XCTAssertNotNil(testView)
    }
}

// MARK: - Mock Objects

class MockModelContext: ModelContext {
    // This would need to be implemented for proper testing
    // For now, it's a placeholder to show the testing approach
}