import Foundation
import HealthKit
import SwiftData

// MARK: - Memory Management・並行処理安全化 (Issue #33)
@MainActor
class HealthKitService: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var lastAutoSyncDate: Date?
    @Published var lastSyncDataCount: Int = 0
    @Published var isAutoSyncing = false
    
    // MARK: - Properties (@MainActor安全)
    
    private let healthStore = HKHealthStore()
    
    // MARK: - HealthKit Types
    
    private let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        
        if let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMassType)
        }
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRateType)
        }
        if let cyclingPowerType = HKObjectType.quantityType(forIdentifier: .cyclingPower) {
            types.insert(cyclingPowerType)
        }
        types.insert(HKObjectType.workoutType())
        
        return types
    }()
    
    // MARK: - Initialization
    
    init() {
        checkAuthorizationStatus()
        loadLastSyncDate()
    }
    
    // MARK: - UserDefaults Management
    
    private func loadLastSyncDate() {
        lastAutoSyncDate = UserDefaults.standard.object(forKey: "HealthKit_LastAutoSyncDate") as? Date
    }
    
    private func saveLastSyncDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "HealthKit_LastAutoSyncDate")
        lastAutoSyncDate = date
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
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .notDetermined
            isAuthorized = false
            return
        }
        
        let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        authorizationStatus = healthStore.authorizationStatus(for: bodyMassType)
        
        // HealthKitでは、ユーザーがデータアクセスを許可していても
        // プライバシー保護のため.notDeterminedが返されることがある
        // そのため、実際にデータクエリを試行して判定する
        switch authorizationStatus {
        case .sharingAuthorized:
            isAuthorized = true
        case .sharingDenied:
            isAuthorized = false
        case .notDetermined:
            // 実際にデータアクセスを試行して判定
            checkDataAccess()
        @unknown default:
            isAuthorized = false
        }
    }
    
    @MainActor
    private func checkDataAccess() {
        Task {
            do {
                let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate) ?? endDate
                
                // 最新のデータを1件だけクエリして、アクセス可能かチェック
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let predicate = HKQuery.predicateForSamples(
                        withStart: startDate,
                        end: endDate,
                        options: .strictStartDate
                    )
                    
                    let query = HKSampleQuery(
                        sampleType: bodyMassType,
                        predicate: predicate,
                        limit: 1,
                        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                    ) { _, samples, error in
                        Task { @MainActor in
                            if let error = error {
                                // エラーの種類で判定
                                if (error as NSError).code == HKError.errorAuthorizationDenied.rawValue {
                                    self.isAuthorized = false
                                } else {
                                    // アクセス権限はあるがデータがない場合
                                    self.isAuthorized = true
                                }
                            } else {
                                // クエリが成功（データの有無に関わらず）
                                self.isAuthorized = true
                            }
                            continuation.resume()
                        }
                    }
                    
                    healthStore.execute(query)
                }
            } catch {
                await MainActor.run {
                    self.isAuthorized = false
                }
            }
        }
    }
    
    // MARK: - Auto Sync on App Launch
    
    func autoSyncOnAppLaunch(modelContext: ModelContext) async {
        guard isAuthorized else { 
            print("HealthKit not authorized, skipping auto sync")
            return 
        }
        
        await MainActor.run {
            isAutoSyncing = true
            lastSyncDataCount = 0
        }
        
        do {
            let startDate = lastAutoSyncDate ?? Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let endDate = Date()
            
            print("HealthKit auto sync: checking for new data since \(startDate)")
            
            // 並行して全データを同期
            async let weightMetrics = syncWeightData(from: startDate, modelContext: modelContext)
            async let heartRateMetrics = syncHeartRateData(from: startDate, modelContext: modelContext)
            async let workouts = syncCyclingWorkouts(from: startDate)
            
            let (weight, heartRate, cycling) = await (
                try? weightMetrics ?? [],
                try? heartRateMetrics ?? [],
                try? workouts ?? []
            )
            
            let totalCount = (weight?.count ?? 0) + (heartRate?.count ?? 0) + (cycling?.count ?? 0)
            
            await MainActor.run {
                self.lastSyncDataCount = totalCount
                self.isAutoSyncing = false
                if totalCount > 0 {
                    print("HealthKit auto sync completed: \(totalCount) new data items")
                    self.saveLastSyncDate(endDate)
                } else {
                    print("HealthKit auto sync: no new data found")
                }
            }
            
        } catch {
            await MainActor.run {
                self.isAutoSyncing = false
                print("HealthKit auto sync failed: \(error.localizedDescription)")
            }
        }
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