import Foundation
import HealthKit
import SwiftData
import OSLog

// MARK: - HealthKitManager (Based on Working Guide Implementation)
@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var lastAutoSyncDate: Date?
    @Published var lastSyncDataCount: Int = 0
    @Published var isAutoSyncing = false
    
    private let healthStore = HKHealthStore()
    
    // MARK: - HealthKit Types
    
    // 読み取り権限が必要なデータタイプ
    private let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        
        // 基本的なヘルスデータ（安全に確認）
        if let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMassType)
            Logger.general.info("HealthKit: Body mass type available")
        }
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRateType)
            Logger.general.info("HealthKit: Heart rate type available")
        }
        if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergyType)
            Logger.general.info("HealthKit: Active energy type available")
        }
        if let basalEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
            types.insert(basalEnergyType)
            Logger.general.info("HealthKit: Basal energy type available")
        }
        if let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCountType)
            Logger.general.info("HealthKit: Step count type available")
        }
        
        // サイクリングパワー（Apple Watch Series 2+必要、問題の可能性あり）
        if let cyclingPowerType = HKObjectType.quantityType(forIdentifier: .cyclingPower) {
            types.insert(cyclingPowerType)
            Logger.general.info("HealthKit: Cycling power type available")
        } else {
            Logger.general.warning("HealthKit: Cycling power type not available on this device")
        }
        
        types.insert(HKObjectType.workoutType())
        
        return types
    }()
    
    // 書き込み権限が必要なデータタイプ
    private let writeTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = []
        
        // 基本的な書き込み可能データ
        if let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMassType)
        }
        if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergyType)
        }
        
        // 追加の書き込みタイプ（手引書に従って拡張）
        if let basalEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
            types.insert(basalEnergyType)
        }
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRateType)
        }
        
        // ワークアウトデータ
        types.insert(HKObjectType.workoutType())
        
        return types
    }()
    
    // MARK: - Initialization
    
    private init() {
        checkAuthorizationStatus()
        loadLastSyncDate()
    }
    
    // MARK: - UserDefaults Management
    
    private func loadLastSyncDate() {
        lastAutoSyncDate = UserDefaults.standard.object(forKey: "HealthKit_LastAutoSyncDate") as? Date
    }
    
    private func saveLastSyncDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "HealthKit_LastAutoSyncDate")
        DispatchQueue.main.async {
            self.lastAutoSyncDate = date
        }
    }
    
    // MARK: - Core Properties
    
    // HealthKitが利用可能かチェック
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Authorization
    
    // 権限リクエスト
    func requestPermissions() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        Logger.general.info("HealthKit: Starting authorization request")
        Logger.general.info("HealthKit: Requesting authorization for \(self.readTypes.count) read types and \(self.writeTypes.count) write types")
        
        for type in self.readTypes {
            Logger.general.info("HealthKit: - \(type.identifier)")
        }
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        
        Logger.general.info("HealthKit: Authorization request completed")
        checkAuthorizationStatus()
        
        Logger.general.info("HealthKit: Final authorization status - isAuthorized: \(self.isAuthorized)")
        
        // 各typeの詳細な認証状況をログ出力
        logDetailedAuthorizationStatus()
    }
    
    @MainActor
    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
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
            Task {
                await checkDataAccess()
            }
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Detailed Authorization Logging
    
    private func logDetailedAuthorizationStatus() {
        Logger.general.info("HealthKit: Detailed authorization status:")
        
        for type in self.readTypes {
            let status = self.healthStore.authorizationStatus(for: type)
            let statusString = switch status {
            case .notDetermined: "notDetermined"
            case .sharingDenied: "sharingDenied"  
            case .sharingAuthorized: "sharingAuthorized"
            @unknown default: "unknown"
            }
            Logger.general.info("HealthKit: - \(type.identifier): \(statusString)")
        }
    }
    
    private func checkDataAccess() async {
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

// MARK: - Data Reading Methods

extension HealthKitManager {
    // 最新の体重を取得
    func getLatestWeight() async throws -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: weightInKg)
            }
            
            healthStore.execute(query)
        }
    }
    
    // 指定期間の歩数を取得
    func getStepCount(from startDate: Date, to endDate: Date) async throws -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.noData
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let stepCount = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: stepCount)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Data Writing Methods

extension HealthKitManager {
    // 体重データを保存
    func saveWeight(_ weight: Double, date: Date = Date()) async throws {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.noData
        }
        
        // データの妥当性チェック
        guard weight > 0 && weight < 1000 else {
            throw HealthKitError.invalidData
        }
        
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: date,
            end: date
        )
        
        try await healthStore.save(weightSample)
        Logger.general.info("HealthKit: Saved weight \(weight) kg to HealthKit")
    }
    
    // 消費カロリーを保存
    func saveActiveEnergy(_ calories: Double, date: Date = Date()) async throws {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.noData
        }
        
        // データの妥当性チェック
        guard calories > 0 && calories < 10000 else {
            throw HealthKitError.invalidData
        }
        
        let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
        let energySample = HKQuantitySample(
            type: energyType,
            quantity: energyQuantity,
            start: date,
            end: date
        )
        
        try await healthStore.save(energySample)
        Logger.general.info("HealthKit: Saved active energy \(calories) kcal to HealthKit")
    }
    
    // 体重データを検証付きで保存
    func saveWeightWithValidation(_ weight: Double) async throws {
        // データの妥当性チェック
        guard weight > 0 && weight < 1000 else {
            throw HealthKitError.invalidData
        }
        
        try await saveWeight(weight)
    }
    
    // 基礎代謝カロリーを保存
    func saveBasalEnergy(_ calories: Double, date: Date = Date()) async throws {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            throw HealthKitError.noData
        }
        
        // データの妥当性チェック
        guard calories > 0 && calories < 5000 else {
            throw HealthKitError.invalidData
        }
        
        let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
        let energySample = HKQuantitySample(
            type: energyType,
            quantity: energyQuantity,
            start: date,
            end: date
        )
        
        try await healthStore.save(energySample)
        Logger.general.info("HealthKit: Saved basal energy \(calories) kcal to HealthKit")
    }
    
    // 心拍数データを保存
    func saveHeartRate(_ heartRate: Int, date: Date = Date()) async throws {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.noData
        }
        
        // データの妥当性チェック
        guard heartRate > 0 && heartRate < 300 else {
            throw HealthKitError.invalidData
        }
        
        let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: Double(heartRate))
        let heartRateSample = HKQuantitySample(
            type: heartRateType,
            quantity: heartRateQuantity,
            start: date,
            end: date
        )
        
        try await healthStore.save(heartRateSample)
        Logger.general.info("HealthKit: Saved heart rate \(heartRate) bpm to HealthKit")
    }
}

// MARK: - Background Updates

extension HealthKitManager {
    func enableBackgroundDelivery() async throws {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        
        try await healthStore.enableBackgroundDelivery(
            for: weightType,
            frequency: .immediate
        ) { [weak self] query, error in
            if let error = error {
                Logger.error.error("HealthKit: Background delivery error: \(error.localizedDescription)")
                return
            }
            
            Task {
                await self?.handleBackgroundUpdate()
            }
        }
        
        Logger.general.info("HealthKit: Background delivery enabled")
    }
    
    private func handleBackgroundUpdate() async {
        // バックグラウンドでデータが更新された時の処理
        Logger.general.info("HealthKit: Data updated in background")
        
        // 必要に応じてアプリのデータを更新
        NotificationCenter.default.post(name: .healthDataUpdated, object: nil)
    }
}

// MARK: - Auto Sync (Preserved Advanced Functionality)

extension HealthKitManager {
    func autoSyncOnAppLaunch(modelContext: ModelContext) async {
        guard isAuthorized else { 
            Logger.general.info("HealthKit not authorized, skipping auto sync")
            return 
        }
        
        await MainActor.run {
            isAutoSyncing = true
            lastSyncDataCount = 0
        }
        
        do {
            let startDate = lastAutoSyncDate ?? Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let endDate = Date()
            
            Logger.general.info("HealthKit auto sync: checking for new data since \(startDate)")
            
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
                    Logger.general.info("HealthKit auto sync completed: \(totalCount) new data items")
                    self.saveLastSyncDate(endDate)
                } else {
                    Logger.general.info("HealthKit auto sync: no new data found")
                }
            }
            
        } catch {
            await MainActor.run {
                self.isAutoSyncing = false
                Logger.error.error("HealthKit auto sync failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Advanced Features (Preserved)

extension HealthKitManager {
    // Weight Data Sync
    func syncWeightData(from startDate: Date, modelContext: ModelContext) async throws -> [DailyMetric] {
        guard isAuthorized else {
            throw HealthKitError.unauthorized
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
    
    // Heart Rate Data Sync
    func syncHeartRateData(from startDate: Date, modelContext: ModelContext) async throws -> [DailyMetric] {
        guard isAuthorized else {
            throw HealthKitError.unauthorized
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
    
    // Cycling Workouts Sync
    func syncCyclingWorkouts(from startDate: Date) async throws -> [HKWorkout] {
        guard isAuthorized else {
            throw HealthKitError.unauthorized
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
    
    // Power Data Analysis
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
    
    // FTP Analysis
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
    
    // Helper Methods
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

// MARK: - Authorization Status Helper

extension HealthKitManager {
    func checkAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }
    
    var isWeightAuthorized: Bool {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return false
        }
        return checkAuthorizationStatus(for: weightType) == .sharingAuthorized
    }
}

// MARK: - Error Types

enum HealthKitError: LocalizedError {
    case notAvailable
    case unauthorized
    case noData
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKitが利用できません"
        case .unauthorized:
            return "HealthKitへのアクセスが許可されていません"
        case .noData:
            return "データが見つかりません"
        case .invalidData:
            return "無効なデータです"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notAvailable:
            return "ヘルスアプリが利用可能なデバイスで実行してください"
        case .unauthorized:
            return "設定からヘルスデータへのアクセスを許可してください"
        case .noData:
            return "ヘルスアプリにデータを追加してから再試行してください"
        case .invalidData:
            return "データの形式を確認してください"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let healthDataUpdated = Notification.Name("healthDataUpdated")
}