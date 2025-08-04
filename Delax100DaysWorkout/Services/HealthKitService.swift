import Foundation
import HealthKit
import SwiftData

@MainActor
class HealthKitService: ObservableObject {
    
    // MARK: - Properties
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // MARK: - HealthKit Types
    
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .cyclingPower)!,
        HKObjectType.workoutType()
    ]
    
    // MARK: - Initialization
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        checkAuthorizationStatus()
    }
    
    @MainActor
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .notDetermined
            isAuthorized = false
            return
        }
        
        let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        authorizationStatus = healthStore.authorizationStatus(for: bodyMassType)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }
    
    // MARK: - Weight Data Sync
    
    func syncWeightData(from startDate: Date, modelContext: ModelContext) async throws -> [DailyMetric] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let samples = try await queryQuantitySamples(
            quantityType: weightType,
            from: startDate,
            to: Date()
        )
        
        var metrics: [DailyMetric] = []
        
        for sample in samples {
            let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            let date = sample.startDate
            
            // Check if we already have a metric for this date
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let predicate = DailyMetric.sameDayPredicate(for: startOfDay)
            
            let descriptor = FetchDescriptor<DailyMetric>(predicate: predicate)
            let existingMetrics = try modelContext.fetch(descriptor)
            
            if let existingMetric = existingMetrics.first {
                // Update existing metric with HealthKit data
                existingMetric.updateFromHealthKit(weight: weight)
                try modelContext.save()
                metrics.append(existingMetric)
            } else {
                // Create new metric
                let newMetric = DailyMetric(
                    date: startOfDay,
                    weightKg: weight,
                    dataSource: .appleHealth
                )
                modelContext.insert(newMetric)
                try modelContext.save()
                metrics.append(newMetric)
            }
        }
        
        return metrics
    }
    
    // MARK: - Heart Rate Data Sync
    
    func syncHeartRateData(from startDate: Date, modelContext: ModelContext) async throws -> [DailyMetric] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let samples = try await queryQuantitySamples(
            quantityType: heartRateType,
            from: startDate,
            to: Date()
        )
        
        // Group samples by date and calculate daily statistics
        let groupedSamples = Dictionary(grouping: samples) { sample in
            Calendar.current.startOfDay(for: sample.startDate)
        }
        
        var metrics: [DailyMetric] = []
        
        for (date, dailySamples) in groupedSamples {
            let heartRates = dailySamples.map { sample in
                Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
            
            let restingHR = heartRates.min()
            let maxHR = heartRates.max()
            
            // Check if we already have a metric for this date
            let predicate = DailyMetric.sameDayPredicate(for: date)
            let descriptor = FetchDescriptor<DailyMetric>(predicate: predicate)
            let existingMetrics = try modelContext.fetch(descriptor)
            
            if let existingMetric = existingMetrics.first {
                // Update existing metric with HealthKit data
                existingMetric.updateFromHealthKit(restingHR: restingHR, maxHR: maxHR)
                try modelContext.save()
                metrics.append(existingMetric)
            } else {
                // Create new metric
                let newMetric = DailyMetric(
                    date: date,
                    restingHeartRate: restingHR,
                    maxHeartRate: maxHR,
                    dataSource: .appleHealth
                )
                modelContext.insert(newMetric)
                try modelContext.save()
                metrics.append(newMetric)
            }
        }
        
        return metrics
    }
    
    // MARK: - Workout Data Sync
    
    func syncCyclingWorkouts(from startDate: Date) async throws -> [HKWorkout] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        let cyclingPredicate = HKQuery.predicateForWorkouts(with: .cycling)
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            cyclingPredicate,
            datePredicate
        ])
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Power Data Analysis
    
    func getAveragePowerForWorkout(_ workout: HKWorkout) async throws -> Double? {
        guard let powerType = HKQuantityType.quantityType(forIdentifier: .cyclingPower) else {
            return nil
        }
        
        let samples = try await queryQuantitySamples(
            quantityType: powerType,
            from: workout.startDate,
            to: workout.endDate
        )
        
        guard !samples.isEmpty else { return nil }
        
        let totalPower = samples.reduce(0.0) { sum, sample in
            sum + sample.quantity.doubleValue(for: .watt())
        }
        
        return totalPower / Double(samples.count)
    }
    
    func getMaxPowerForWorkout(_ workout: HKWorkout) async throws -> Double? {
        guard let powerType = HKQuantityType.quantityType(forIdentifier: .cyclingPower) else {
            return nil
        }
        
        let samples = try await queryQuantitySamples(
            quantityType: powerType,
            from: workout.startDate,
            to: workout.endDate
        )
        
        guard !samples.isEmpty else { return nil }
        
        return samples.map { sample in
            sample.quantity.doubleValue(for: .watt())
        }.max()
    }
    
    // MARK: - FTP Analysis
    
    func calculateTwentyMinutePower(for workout: HKWorkout) async throws -> Double? {
        guard let powerType = HKQuantityType.quantityType(forIdentifier: .cyclingPower),
              workout.duration >= 20 * 60 else { // At least 20 minutes
            return nil
        }
        
        let samples = try await queryQuantitySamples(
            quantityType: powerType,
            from: workout.startDate,
            to: workout.endDate
        )
        
        guard samples.count >= 20 else { return nil } // Need sufficient data points
        
        // Find the best 20-minute average power
        let powerValues = samples.map { $0.quantity.doubleValue(for: .watt()) }
        let windowSize = min(20, powerValues.count)
        
        var bestAverage = 0.0
        for i in 0...(powerValues.count - windowSize) {
            let windowValues = Array(powerValues[i..<(i + windowSize)])
            let average = windowValues.reduce(0, +) / Double(windowValues.count)
            bestAverage = max(bestAverage, average)
        }
        
        return bestAverage > 0 ? bestAverage : nil
    }
    
    // MARK: - Helper Methods
    
    private func queryQuantitySamples(
        quantityType: HKQuantityType,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )
            
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let quantitySamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: quantitySamples)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Error Types

enum HealthKitError: LocalizedError {
    case healthDataNotAvailable
    case notAuthorized
    case noData
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "ヘルスデータが利用できません"
        case .notAuthorized:
            return "ヘルスデータへのアクセスが許可されていません"
        case .noData:
            return "データが見つかりません"
        case .invalidData:
            return "無効なデータです"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .healthDataNotAvailable:
            return "ヘルスアプリが利用可能なデバイスで実行してください"
        case .notAuthorized:
            return "設定からヘルスデータへのアクセスを許可してください"
        case .noData:
            return "ヘルスアプリにデータを追加してから再試行してください"
        case .invalidData:
            return "データの形式を確認してください"
        }
    }
}