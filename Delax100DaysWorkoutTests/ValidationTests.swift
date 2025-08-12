import XCTest
import SwiftData
@testable import Delax100DaysWorkout

final class ValidationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let schema = Schema([
            UserProfile.self,
            DailyLog.self,
            WorkoutRecord.self,
            CyclingDetail.self,
            StrengthDetail.self,
            FlexibilityDetail.self,
            FTPHistory.self,
            DailyMetric.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - ValidationRules Tests
    
    func testWeightValidation() {
        XCTAssertNil(ValidationRules.validateWeight(70.0))
        XCTAssertNil(ValidationRules.validateWeight(50.0))
        
        let tooLow = ValidationRules.validateWeight(25.0)
        XCTAssertNotNil(tooLow)
        XCTAssertEqual(tooLow?.severity, .error)
        
        let tooHigh = ValidationRules.validateWeight(250.0)
        XCTAssertNotNil(tooHigh)
        XCTAssertEqual(tooHigh?.severity, .error)
        
        let warning = ValidationRules.validateWeight(160.0)
        XCTAssertNotNil(warning)
        XCTAssertEqual(warning?.severity, .warning)
    }
    
    func testHeartRateValidation() {
        // Resting heart rate
        XCTAssertNil(ValidationRules.validateHeartRate(60, type: .resting))
        
        let tooLowResting = ValidationRules.validateHeartRate(25, type: .resting)
        XCTAssertNotNil(tooLowResting)
        XCTAssertEqual(tooLowResting?.severity, .error)
        
        let highResting = ValidationRules.validateHeartRate(85, type: .resting)
        XCTAssertNotNil(highResting)
        XCTAssertEqual(highResting?.severity, .warning)
        
        // Average heart rate
        XCTAssertNil(ValidationRules.validateHeartRate(120, type: .average))
        
        let tooHighAverage = ValidationRules.validateHeartRate(210, type: .average)
        XCTAssertNotNil(tooHighAverage)
        XCTAssertEqual(tooHighAverage?.severity, .error)
        
        // Max heart rate
        XCTAssertNil(ValidationRules.validateHeartRate(180, type: .max))
        
        let tooHighMax = ValidationRules.validateHeartRate(230, type: .max)
        XCTAssertNotNil(tooHighMax)
        XCTAssertEqual(tooHighMax?.severity, .error)
    }
    
    func testPowerValidation() {
        // Average power
        XCTAssertNil(ValidationRules.validatePower(200, type: .average))
        
        let negativePower = ValidationRules.validatePower(-10, type: .average)
        XCTAssertNotNil(negativePower)
        XCTAssertEqual(negativePower?.severity, .error)
        
        let highAveragePower = ValidationRules.validatePower(600, type: .average)
        XCTAssertNotNil(highAveragePower)
        XCTAssertEqual(highAveragePower?.severity, .warning)
        
        // FTP
        XCTAssertNil(ValidationRules.validatePower(250, type: .ftp))
        
        let lowFTP = ValidationRules.validatePower(40, type: .ftp)
        XCTAssertNotNil(lowFTP)
        XCTAssertEqual(lowFTP?.severity, .error)
        
        let highFTP = ValidationRules.validatePower(450, type: .ftp)
        XCTAssertNotNil(highFTP)
        XCTAssertEqual(highFTP?.severity, .warning)
    }
    
    func testDateValidation() {
        let today = Date()
        XCTAssertNil(ValidationRules.validateDate(today, allowFuture: false))
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        XCTAssertNil(ValidationRules.validateDate(yesterday, allowFuture: false))
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let futureDateError = ValidationRules.validateDate(tomorrow, allowFuture: false)
        XCTAssertNotNil(futureDateError)
        XCTAssertEqual(futureDateError?.severity, .error)
        
        XCTAssertNil(ValidationRules.validateDate(tomorrow, allowFuture: true))
        
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: today)!
        let oldDateError = ValidationRules.validateDate(twoYearsAgo, allowFuture: false)
        XCTAssertNotNil(oldDateError)
        XCTAssertEqual(oldDateError?.severity, .error)
    }
    
    // MARK: - Model Validation Tests
    
    func testUserProfileValidation() {
        let profile = UserProfile(
            goalDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            startWeightKg: 70.0,
            goalWeightKg: 65.0,
            startFtp: 200,
            goalFtp: 250
        )
        
        let result = profile.validate()
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.warnings.isEmpty)
        
        // Test invalid weight
        profile.startWeightKg = 25.0
        let invalidResult = profile.validate()
        XCTAssertFalse(invalidResult.isValid)
        
        // Test unrealistic goal
        profile.startWeightKg = 70.0
        profile.goalWeightKg = 40.0
        let unrealisticResult = profile.validate()
        XCTAssertTrue(unrealisticResult.isValid) // Should be valid but with warning
        XCTAssertFalse(unrealisticResult.warnings.isEmpty)
    }
    
    func testDailyLogValidation() {
        let log = DailyLog(date: Date(), weightKg: 70.0)
        
        let result = log.validate()
        XCTAssertTrue(result.isValid)
        
        // Test invalid weight
        log.weightKg = 300.0
        let invalidResult = log.validate()
        XCTAssertFalse(invalidResult.isValid)
        
        // Test future date
        log.weightKg = 70.0
        log.date = Date().addingTimeInterval(24 * 60 * 60)
        let futureDateResult = log.validate()
        XCTAssertFalse(futureDateResult.isValid)
    }
    
    func testWorkoutRecordValidation() {
        let workout = WorkoutRecord(
            date: Date(),
            workoutType: .cycling,
            summary: "Morning ride"
        )
        
        let result = workout.validate()
        XCTAssertTrue(result.isValid)
        
        // Test empty summary
        workout.summary = ""
        let emptyResult = workout.validate()
        XCTAssertFalse(emptyResult.isValid)
        
        // Test completed workout without details
        workout.summary = "Morning ride"
        workout.isCompleted = true
        let incompleteResult = workout.validate()
        XCTAssertTrue(incompleteResult.isValid) // Valid but with warning
        XCTAssertFalse(incompleteResult.warnings.isEmpty)
    }
    
    func testCyclingDetailValidation() {
        let cycling = CyclingDetail(
            distance: 30.0,
            duration: 3600,
            averagePower: 200.0,
            intensity: .endurance
        )
        
        XCTAssertTrue(cycling.isValidPowerData)
        XCTAssertTrue(cycling.isComplete)
        
        // Test invalid heart rate
        cycling.averageHeartRate = 250
        XCTAssertFalse(cycling.isValidHeartRateData)
        
        // Test average > max
        cycling.averageHeartRate = 150
        cycling.maxHeartRate = 140
        XCTAssertFalse(cycling.isValidHeartRateData)
    }
    
    func testStrengthDetailValidation() {
        let strength = StrengthDetail(
            exercise: "Bench Press",
            sets: 3,
            reps: 10,
            weight: 60.0
        )
        
        let result = strength.validate()
        XCTAssertTrue(result.isValid)
        
        // Test negative weight
        strength.weight = -10.0
        let negativeResult = strength.validate()
        XCTAssertFalse(negativeResult.isValid)
        
        // Test excessive sets
        strength.weight = 60.0
        strength.sets = 100
        let excessiveResult = strength.validate()
        XCTAssertFalse(excessiveResult.isValid)
    }
    
    func testFlexibilityDetailValidation() {
        let flexibility = FlexibilityDetail(
            forwardBendDistance: 10.0,
            leftSplitAngle: 120.0,
            rightSplitAngle: 125.0,
            frontSplitAngle: 130.0,
            backSplitAngle: 90.0,
            duration: 1800
        )
        
        let result = flexibility.validate()
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.warnings.isEmpty)
        
        // Test invalid angle
        flexibility.leftSplitAngle = -10.0
        let invalidResult = flexibility.validate()
        XCTAssertFalse(invalidResult.isValid)
        
        // Test imbalance warning
        flexibility.leftSplitAngle = 100.0
        flexibility.rightSplitAngle = 140.0
        let imbalanceResult = flexibility.validate()
        XCTAssertTrue(imbalanceResult.isValid)
        XCTAssertFalse(imbalanceResult.warnings.isEmpty)
    }
    
    func testFTPHistoryValidation() {
        let ftp = FTPHistory(
            date: Date(),
            ftpValue: 250,
            measurementMethod: .twentyMinuteTest
        )
        
        let result = ftp.validate()
        XCTAssertTrue(result.isValid)
        
        // Test invalid FTP value
        ftp.ftpValue = 30
        let lowResult = ftp.validate()
        XCTAssertFalse(lowResult.isValid)
        
        // Test auto-calculated consistency
        ftp.ftpValue = 250
        ftp.measurementMethod = .autoCalculated
        ftp.isAutoCalculated = false
        let inconsistentResult = ftp.validate()
        XCTAssertTrue(inconsistentResult.isValid)
        XCTAssertFalse(inconsistentResult.warnings.isEmpty)
    }
    
    func testDailyMetricValidation() {
        let metric = DailyMetric(
            date: Date(),
            weightKg: 70.0,
            restingHeartRate: 55,
            maxHeartRate: 185
        )
        
        XCTAssertTrue(metric.isValid)
        
        // Test invalid weight
        metric.weightKg = 25.0
        XCTAssertFalse(metric.isValid)
        
        // Test invalid resting heart rate
        metric.weightKg = 70.0
        metric.restingHeartRate = 120
        XCTAssertFalse(metric.isValid)
    }
    
    // MARK: - DataIntegrityManager Tests
    
    func testDataIntegrityManager() async throws {
        let manager = DataIntegrityManager(modelContext: modelContext)
        
        // Create test data with some invalid values
        let profile = UserProfile(
            goalDate: Date().addingTimeInterval(100 * 24 * 60 * 60),
            startWeightKg: 25.0, // Invalid
            goalWeightKg: 70.0,
            startFtp: 200,
            goalFtp: 250
        )
        modelContext.insert(profile)
        
        let log = DailyLog(
            date: Date().addingTimeInterval(24 * 60 * 60), // Future date
            weightKg: 70.0
        )
        modelContext.insert(log)
        
        try modelContext.save()
        
        // Run validation
        await manager.performFullValidation()
        
        // Check results
        XCTAssertNotNil(manager.validationResults["UserProfile"])
        XCTAssertNotNil(manager.validationResults["DailyLog"])
        
        let profileResult = manager.validationResults["UserProfile"]!
        XCTAssertFalse(profileResult.isValid)
        
        let logResult = manager.validationResults["DailyLog"]!
        XCTAssertFalse(logResult.isValid)
    }
    
    func testDuplicateMetricRepair() async throws {
        let manager = DataIntegrityManager(modelContext: modelContext)
        
        // Create duplicate metrics
        let date = Date()
        let metric1 = DailyMetric(
            date: date,
            weightKg: 70.0,
            restingHeartRate: 55,
            dataSource: .manual
        )
        modelContext.insert(metric1)
        
        let metric2 = DailyMetric(
            date: date,
            weightKg: 71.0,
            restingHeartRate: 56,
            dataSource: .appleHealth
        )
        modelContext.insert(metric2)
        
        try modelContext.save()
        
        // Repair duplicates
        try await manager.repairDuplicateDailyMetrics()
        
        // Check that only one metric remains
        let descriptor = FetchDescriptor<DailyMetric>()
        let metrics = try modelContext.fetch(descriptor)
        XCTAssertEqual(metrics.count, 1)
        
        // Check that Apple Health data was preferred
        let remaining = metrics.first!
        XCTAssertEqual(remaining.dataSource, .appleHealth)
        XCTAssertEqual(remaining.weightKg, 71.0)
    }
    
    // MARK: - Performance Tests
    
    func testValidationPerformance() {
        let profile = UserProfile(
            goalDate: Date().addingTimeInterval(100 * 24 * 60 * 60),
            startWeightKg: 70.0,
            goalWeightKg: 65.0,
            startFtp: 200,
            goalFtp: 250
        )
        
        measure {
            for _ in 0..<1000 {
                _ = profile.validate()
            }
        }
    }
}