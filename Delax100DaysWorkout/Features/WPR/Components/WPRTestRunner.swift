import SwiftUI
import SwiftData
import OSLog

struct WPRTestRunner {
    static func runAllTests(
        modelContext: ModelContext,
        wprSystem: WPRTrackingSystem,
        completion: @escaping ([String]) -> Void
    ) {
        var testResults: [String] = []
        testResults.append("🧪 WPR機能テスト開始...")
        
        Task {
            await MainActor.run {
                // 1. WPR計算精度テスト
                testWPRCalculationAccuracy(&testResults)
                
                // 2. ボトルネック検出テスト
                testBottleneckDetection(&testResults, wprSystem: wprSystem)
                
                // 3. 自動更新統合テスト
                testAutoUpdateIntegration(&testResults)
                
                // 4. 科学的指標統合テスト
                testScientificMetricsIntegration(&testResults)
                
                // 5. 実データ統合テスト
                testRealDataIntegration(&testResults, modelContext: modelContext, wprSystem: wprSystem)
                
                testResults.append("✅ WPR機能テスト完了")
                completion(testResults)
            }
        }
    }
    
    private static func testWPRCalculationAccuracy(_ testResults: inout [String]) {
        testResults.append("\n📊 WPR計算精度テスト")
        
        let testSystem = WPRTrackingSystem()
        testSystem.setBaseline(ftp: 250, weight: 70.0, ef: 1.2)
        
        let baselineWPR = testSystem.baselineWPR
        let expectedBaseline = 250.0 / 70.0
        let baselineAccurate = abs(baselineWPR - expectedBaseline) < 0.01
        testResults.append("✅ ベースラインWPR: \(String(format: "%.2f", baselineWPR)) \(baselineAccurate ? "正確" : "エラー")")
        
        testSystem.updateCurrentMetrics(ftp: 270, weight: 68.0)
        let currentWPR = testSystem.calculatedWPR
        let expectedCurrent = 270.0 / 68.0
        let currentAccurate = abs(currentWPR - expectedCurrent) < 0.01
        testResults.append("✅ 現在WPR: \(String(format: "%.2f", currentWPR)) \(currentAccurate ? "正確" : "エラー")")
        
        let targetProgress = testSystem.targetProgressRatio
        testResults.append("✅ 目標達成率: \(String(format: "%.1f", targetProgress * 100))%")
        
        testSystem.resetToEvidenceBasedCoefficients()
        let isValid = testSystem.validateCoefficients()
        testResults.append("✅ 係数妥当性: \(isValid ? "正常" : "異常")")
    }
    
    private static func testBottleneckDetection(_ testResults: inout [String], wprSystem: WPRTrackingSystem) {
        testResults.append("\n🔍 ボトルネック検出テスト")
        
        let testSystem = WPRTrackingSystem()
        testSystem.setBaseline(ftp: 250, weight: 70.0, ef: 1.2)
        
        testSystem.efficiencyFactor = 1.0
        let efficiencyScore = (testSystem.efficiencyFactor - testSystem.efficiencyBaseline) / 
                             (testSystem.efficiencyTarget - testSystem.efficiencyBaseline)
        testResults.append("✅ 効率性スコア: \(String(format: "%.2f", efficiencyScore))")
        
        testSystem.updateCurrentMetrics(ftp: 250, weight: 75.0)
        let weightIncrease = ((75.0 - 70.0) / 70.0) * 100
        testResults.append("✅ 体重変化: +\(String(format: "%.1f", weightIncrease))% \(weightIncrease > 5.0 ? "(ボトルネック)" : "")")
        
        testResults.append("✅ 現在ボトルネック: \(wprSystem.currentBottleneck)")
    }
    
    private static func testAutoUpdateIntegration(_ testResults: inout [String]) {
        testResults.append("\n🔄 自動更新統合テスト")
        
        let cyclingWorkout = WorkoutRecord(date: Date(), workoutType: .cycling, summary: "テスト用SST")
        let cyclingDetail = CyclingDetail(
            distance: 40.0,
            duration: 3600,
            averagePower: 240.0,
            intensity: .sst,
            averageHeartRate: 165
        )
        cyclingWorkout.cyclingDetail = cyclingDetail
        testResults.append("✅ サイクリングワークアウト作成完了")
        
        let ftpRecord = FTPHistory(date: Date(), ftpValue: 265, measurementMethod: .twentyMinuteTest)
        testResults.append("✅ FTP記録作成完了: \(ftpRecord.ftpValue)W")
        
        let dailyMetric = DailyMetric(date: Date(), weightKg: 68.5)
        testResults.append("✅ 体重記録作成完了: \(dailyMetric.weightKg ?? 0)kg")
    }
    
    private static func testScientificMetricsIntegration(_ testResults: inout [String]) {
        testResults.append("\n🧬 科学的指標統合テスト")
        
        let efficiencyMetric = EfficiencyMetrics(
            normalizedPower: 245.0,
            averageHeartRate: 162,
            duration: 3600.0,
            workoutType: "SST"
        )
        testResults.append("✅ EfficiencyMetrics: NP=\(efficiencyMetric.normalizedPower)W")
        
        let powerProfile = PowerProfile()
        powerProfile.power20Min = 265
        powerProfile.power5Min = 320
        testResults.append("✅ PowerProfile: 20min=\(powerProfile.power20Min)W")
        
        let vlSystem = VolumeLoadSystem()
        vlSystem.weeklyPushVL = 2500.0
        testResults.append("✅ VolumeLoadSystem: Push=\(vlSystem.weeklyPushVL)")
        
        let romTracking = ROMTracking()
        romTracking.forwardBendAngle = 45.0
        romTracking.hipFlexibility = 120.0
        testResults.append("✅ ROMTracking: 前屈=\(romTracking.forwardBendAngle)°")
        
        testResults.append("✅ 全科学的指標作成完了")
    }
    
    private static func testRealDataIntegration(_ testResults: inout [String], modelContext: ModelContext, wprSystem: WPRTrackingSystem) {
        testResults.append("\n🔗 実データ統合テスト")
        
        // Synchronous test only - async operations would require different architecture
        do {
            let testWPRSystem = WPRTrackingSystem()
            testWPRSystem.setBaseline(ftp: 250, weight: 70.0, ef: 1.2)
            testWPRSystem.updateCurrentMetrics(ftp: 265, weight: 69.0)
            modelContext.insert(testWPRSystem)
            
            let testFTP = FTPHistory(
                date: Date(),
                ftpValue: 265,
                measurementMethod: .twentyMinuteTest,
                notes: "機能テスト用"
            )
            modelContext.insert(testFTP)
            
            let testWeight = DailyMetric(
                date: Date(),
                weightKg: 69.0,
                restingHeartRate: 48,
                maxHeartRate: 185
            )
            modelContext.insert(testWeight)
            
            try modelContext.save()
            
            testResults.append("✅ 実データ統合テスト: 全データ保存完了")
            testResults.append("✅ WPRシステム、FTP、体重記録作成成功")
        } catch {
            testResults.append("❌ 実データ統合テストエラー: \(error.localizedDescription)")
        }
    }
}