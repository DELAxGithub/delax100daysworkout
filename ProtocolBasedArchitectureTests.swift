import XCTest
import SwiftData
@testable import Delax100DaysWorkout

// MARK: - Protocol-Based Architecture Tests

@MainActor
final class ProtocolBasedArchitectureTests: XCTestCase {
    
    var testContainer: DIContainer!
    var mockContextProvider: MockModelContextProvider!
    var mockErrorHandler: MockErrorHandler!
    var mockAnalytics: MockAnalyticsProvider!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up test DI container with mocks
        testContainer = DIContainer.createTestContainer()
        
        // Get references to mock objects for verification
        mockContextProvider = testContainer.resolve(ModelContextProviding.self) as? MockModelContextProvider
        mockErrorHandler = testContainer.getMockErrorHandler()
        mockAnalytics = testContainer.getMockAnalytics()
        
        XCTAssertNotNil(mockContextProvider)
        XCTAssertNotNil(mockErrorHandler)
        XCTAssertNotNil(mockAnalytics)
    }
    
    override func tearDown() async throws {
        testContainer.clear()
        testContainer = nil
        mockContextProvider = nil
        mockErrorHandler = nil
        mockAnalytics = nil
        
        try await super.tearDown()
    }
    
    // MARK: - DI Container Tests
    
    func testDIContainerRegistration() throws {
        let container = DIContainer()
        
        // Test singleton registration
        let testService = MockAnalyticsProvider()
        container.register(AnalyticsProviding.self, implementation: testService)
        
        let resolved = container.resolve(AnalyticsProviding.self)
        XCTAssertNotNil(resolved)
        XCTAssertTrue(resolved is MockAnalyticsProvider)
    }
    
    func testDIContainerFactory() throws {
        let container = DIContainer()
        
        // Test factory registration
        container.register(String.self) {
            return "Factory Created"
        }
        
        let result = container.resolve(String.self)
        XCTAssertEqual(result, "Factory Created")
    }
    
    func testDIContainerServiceNotFound() throws {
        let container = DIContainer()
        
        // Test error handling for unregistered service
        XCTAssertThrowsError(try container.resolve(AnalyticsProviding.self)) { error in
            XCTAssertTrue(error is DIError)
        }
    }
}

// MARK: - Test Error Types

enum TestError: Error {
    case mockError
    case networkError
    case validationError
}