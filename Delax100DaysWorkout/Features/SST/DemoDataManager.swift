import Foundation
import SwiftData

class DemoDataManager {
    
    // MARK: - Demo Data Generation
    
    static func generateJuly2025DemoData(modelContext: ModelContext) {
        print("🚀 Generating July 2025 demo data...")
        
        // Clear existing demo data first
        clearExistingDemoData(modelContext: modelContext)
        
        // Generate data in chronological order
        generateFTPHistory(modelContext: modelContext)
        generateDailyMetrics(modelContext: modelContext)
        generateCyclingWorkouts(modelContext: modelContext)
        
        // Save all changes
        do {
            try modelContext.save()
            print("✅ July 2025 demo data generated successfully!")
        } catch {
            print("❌ Failed to save demo data: \(error)")
        }
    }
    
    // MARK: - FTP History Generation
    
    private static func generateFTPHistory(modelContext: ModelContext) {
        let ftpUpdates = [
            (date: createDate(2025, 7, 1), ftp: 260, method: FTPMeasurementMethod.manual, notes: "7月のベースライン設定"),
            (date: createDate(2025, 7, 10), ftp: 265, method: FTPMeasurementMethod.twentyMinuteTest, notes: "初回20分テスト - 良好な結果"),
            (date: createDate(2025, 7, 20), ftp: 270, method: FTPMeasurementMethod.rampTest, notes: "ランプテスト - 順調な向上"),
            (date: createDate(2025, 7, 30), ftp: 275, method: FTPMeasurementMethod.twentyMinuteTest, notes: "月末テスト - 目標達成！")
        ]
        
        for update in ftpUpdates {
            let ftpHistory = FTPHistory(
                date: update.date,
                ftpValue: update.ftp,
                measurementMethod: update.method,
                notes: update.notes,
                isAutoCalculated: update.method == .autoCalculated
            )
            modelContext.insert(ftpHistory)
        }
        
        print("📈 Generated \(ftpUpdates.count) FTP history records")
    }
    
    // MARK: - Daily Metrics Generation
    
    private static func generateDailyMetrics(modelContext: ModelContext) {
        var generatedCount = 0
        
        for day in 1...31 {
            let date = createDate(2025, 7, day)
            
            // Base values with realistic variations
            let baseWeight = 70.0
            let weightVariation = Double.random(in: -0.5...0.5)
            let weight = baseWeight + weightVariation
            
            let baseRestingHR = 50
            let restingHRVariation = Int.random(in: -3...3)
            let restingHR = baseRestingHR + restingHRVariation
            
            let baseMaxHR = 187
            let maxHRVariation = Int.random(in: -2...3)
            let maxHR = baseMaxHR + maxHRVariation
            
            let dailyMetric = DailyMetric(
                date: Calendar.current.startOfDay(for: date),
                weightKg: weight,
                restingHeartRate: restingHR,
                maxHeartRate: maxHR,
                dataSource: .manual
            )
            
            modelContext.insert(dailyMetric)
            generatedCount += 1
        }
        
        print("📊 Generated \(generatedCount) daily metrics records")
    }
    
    // MARK: - Cycling Workouts Generation
    
    private static func generateCyclingWorkouts(modelContext: ModelContext) {
        // Workout schedule: 週3-4回、計15回
        let workoutDays = [2, 4, 6, 9, 11, 13, 16, 18, 20, 23, 25, 27, 30] // 13回
        var generatedCount = 0
        
        for (index, day) in workoutDays.enumerated() {
            let date = createDate(2025, 7, day)
            
            // Progressive training intensity based on FTP progression
            let currentFTP = interpolateFTP(forDay: day)
            
            // Different workout types
            let workoutTypes: [(intensity: CyclingIntensity, durationMins: Int, description: String)] = [
                (.endurance, 90, "エンデュランスライド"),
                (.tempo, 60, "テンポ走"),
                (.sst, 75, "SST インターバル"),
                (.vo2max, 45, "VO2max インターバル")
            ]
            
            let workoutType = workoutTypes[index % workoutTypes.count]
            let duration = workoutType.durationMins * 60 // Convert to seconds
            
            // Calculate realistic power and heart rate
            let intensityMultiplier = getIntensityMultiplier(for: workoutType.intensity)
            let averagePower = Double(currentFTP) * intensityMultiplier
            let maxPower = averagePower * Double.random(in: 1.15...1.35)
            
            // Heart rate calculation with progressive efficiency improvement
            let baseWHR = 1.6 + (Double(index) * 0.015) // Gradual W/HR improvement
            let whrVariation = Double.random(in: -0.1...0.1)
            let actualWHR = baseWHR + whrVariation
            let averageHR = Int(averagePower / actualWHR)
            let maxHR = Int(Double(averageHR) * Double.random(in: 1.1...1.2))
            
            // Create cycling detail
            let cyclingDetail = CyclingDetail(
                distance: Double(duration) / 60.0 * 0.4, // ~24km/h average
                duration: duration,
                averagePower: averagePower,
                intensity: workoutType.intensity,
                notes: workoutType.description,
                averageHeartRate: averageHR,
                maxHeartRate: maxHR,
                maxPower: maxPower,
                normalizedPower: averagePower * Double.random(in: 1.02...1.08),
                isFromHealthKit: false
            )
            
            // Create workout record
            let workoutRecord = WorkoutRecord(
                date: date,
                workoutType: .cycling,
                summary: workoutType.description,
                isQuickRecord: false
            )
            
            // Set cycling detail
            workoutRecord.cyclingDetail = cyclingDetail
            workoutRecord.markAsCompleted()
            
            modelContext.insert(workoutRecord)
            generatedCount += 1
        }
        
        print("🚴 Generated \(generatedCount) cycling workout records")
    }
    
    // MARK: - Helper Functions
    
    private static func createDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 10 // Set to 10 AM
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private static func interpolateFTP(forDay day: Int) -> Int {
        // Linear interpolation between FTP milestones
        switch day {
        case 1...9:
            return 260
        case 10...19:
            let progress = Double(day - 10) / 10.0
            return Int(265.0 + progress * 5.0) // 265 -> 270
        case 20...29:
            let progress = Double(day - 20) / 10.0
            return Int(270.0 + progress * 5.0) // 270 -> 275
        default:
            return 275
        }
    }
    
    private static func getIntensityMultiplier(for intensity: CyclingIntensity) -> Double {
        switch intensity {
        case .recovery:
            return 0.5
        case .z2:
            return 0.65
        case .endurance:
            return 0.72
        case .tempo:
            return 0.85
        case .sst:
            return 0.95
        case .vo2max:
            return 1.1
        case .anaerobic:
            return 1.2
        case .sprint:
            return 1.5
        }
    }
    
    // MARK: - Data Cleanup
    
    private static func clearExistingDemoData(modelContext: ModelContext) {
        let julyStart = createDate(2025, 7, 1)
        let julyEnd = createDate(2025, 7, 31)
        
        // Clear FTP History
        let ftpPredicate = #Predicate<FTPHistory> { ftp in
            ftp.date >= julyStart && ftp.date <= julyEnd
        }
        let ftpDescriptor = FetchDescriptor<FTPHistory>(predicate: ftpPredicate)
        
        // Clear Daily Metrics
        let metricsPredicate = #Predicate<DailyMetric> { metric in
            metric.date >= julyStart && metric.date <= julyEnd
        }
        let metricsDescriptor = FetchDescriptor<DailyMetric>(predicate: metricsPredicate)
        
        // Clear Workout Records
        let workoutPredicate = #Predicate<WorkoutRecord> { workout in
            workout.date >= julyStart && workout.date <= julyEnd
        }
        let workoutDescriptor = FetchDescriptor<WorkoutRecord>(predicate: workoutPredicate)
        
        do {
            let existingFTP = try modelContext.fetch(ftpDescriptor)
            let existingMetrics = try modelContext.fetch(metricsDescriptor)
            let existingWorkouts = try modelContext.fetch(workoutDescriptor)
            
            for item in existingFTP { modelContext.delete(item) }
            for item in existingMetrics { modelContext.delete(item) }
            for item in existingWorkouts { modelContext.delete(item) }
            
            if !existingFTP.isEmpty || !existingMetrics.isEmpty || !existingWorkouts.isEmpty {
                print("🧹 Cleared existing July 2025 demo data")
            }
            
        } catch {
            print("⚠️ Warning: Could not clear existing demo data: \(error)")
        }
    }
    
    // MARK: - Demo Data Check
    
    static func hasJuly2025DemoData(modelContext: ModelContext) -> Bool {
        let julyStart = createDate(2025, 7, 1)
        let julyEnd = createDate(2025, 7, 31)
        
        let ftpPredicate = #Predicate<FTPHistory> { ftp in
            ftp.date >= julyStart && ftp.date <= julyEnd
        }
        let ftpDescriptor = FetchDescriptor<FTPHistory>(predicate: ftpPredicate)
        
        do {
            let existingFTP = try modelContext.fetch(ftpDescriptor)
            return !existingFTP.isEmpty
        } catch {
            return false
        }
    }
    
    // MARK: - Demo Data Summary
    
    static func getDemoDataSummary(modelContext: ModelContext) -> String {
        let julyStart = createDate(2025, 7, 1)
        let julyEnd = createDate(2025, 7, 31)
        
        do {
            // Count FTP records
            let ftpPredicate = #Predicate<FTPHistory> { ftp in
                ftp.date >= julyStart && ftp.date <= julyEnd
            }
            let ftpCount = try modelContext.fetch(FetchDescriptor<FTPHistory>(predicate: ftpPredicate)).count
            
            // Count workout records
            let workoutPredicate = #Predicate<WorkoutRecord> { workout in
                workout.date >= julyStart && workout.date <= julyEnd
            }
            let workoutCount = try modelContext.fetch(FetchDescriptor<WorkoutRecord>(predicate: workoutPredicate)).count
            
            // Count daily metrics
            let metricsPredicate = #Predicate<DailyMetric> { metric in
                metric.date >= julyStart && metric.date <= julyEnd
            }
            let metricsCount = try modelContext.fetch(FetchDescriptor<DailyMetric>(predicate: metricsPredicate)).count
            
            return """
            📊 July 2025 Demo Data:
            • FTP記録: \(ftpCount)件
            • ワークアウト: \(workoutCount)件  
            • デイリー記録: \(metricsCount)件
            """
            
        } catch {
            return "データ取得エラー: \(error.localizedDescription)"
        }
    }
}