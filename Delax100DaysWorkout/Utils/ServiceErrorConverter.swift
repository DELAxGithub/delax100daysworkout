import Foundation

/// Converts service-specific errors to AppError for consistency
enum ServiceErrorConverter {
    
    /// Convert GitHubError to AppError
    static func convert(_ error: GitHubError) -> AppError {
        switch error {
        case .missingToken:
            return .githubTokenMissing
        case .failedToCreateIssue, .failedToUploadScreenshot:
            return .githubRequestFailed(error)
        case .invalidResponse:
            return .invalidResponse
        case .unauthorized:
            return .unauthorized
        case .repositoryNotFound:
            return .githubRepositoryNotFound
        case .validationFailed:
            return .invalidData(reason: error.localizedDescription)
        }
    }
    
    /// Convert HealthKitError to AppError
    static func convert(_ error: HealthKitError) -> AppError {
        switch error {
        case .healthDataNotAvailable:
            return .healthDataNotAvailable
        case .notAuthorized:
            return .healthKitNotAuthorized
        case .noData:
            return .dataNotFound
        case .invalidData:
            return .invalidData(reason: error.localizedDescription)
        }
    }
    
    /// Convert WeeklyPlanError to AppError
    static func convert(_ error: WeeklyPlanError) -> AppError {
        switch error {
        case .noRecentHistory:
            return .dataNotFound
        case .insufficientData:
            return .invalidData(reason: "トレーニング履歴が不足しています")
        case .noActiveTemplate:
            return .dataNotFound
        case .anthropicAPIError(let underlyingError):
            return .aiRequestFailed(underlyingError)
        case .jsonDecodingError(let underlyingError):
            return .invalidData(reason: underlyingError.localizedDescription)
        }
    }
}

// MARK: - Extension for Error Protocol
extension Error {
    /// Convert any error to AppError
    var asAppError: AppError {
        if let appError = self as? AppError {
            return appError
        }
        
        if let githubError = self as? GitHubError {
            return ServiceErrorConverter.convert(githubError)
        }
        
        if let healthKitError = self as? HealthKitError {
            return ServiceErrorConverter.convert(healthKitError)
        }
        
        if let weeklyPlanError = self as? WeeklyPlanError {
            return ServiceErrorConverter.convert(weeklyPlanError)
        }
        
        return AppError.from(self)
    }
}