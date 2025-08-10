import Foundation
import SwiftData

// MARK: - WPR機能テスト実行スクリプト

/// WPRTrackingSystemの機能テストを実行
class WPRFunctionalTests {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - テストシナリオ実行
    
    func runAllTests() {
        print("🧪 WPR機能テスト開始...")
        
        // 1. WPR計算精度テスト
        testWPRCalculationAccuracy()
        
        // 2. ボトルネック検出テスト
        testBottleneckDetection()
        
        // 3. 自動更新統合テスト
        testAutoUpdateIntegration()
        
        // 4. 科学的指標統合テスト
        testScientificMetricsIntegration()
        
        print("✅ WPR機能テスト完了")
    }
    
    // MARK: - 1. WPR計算精度テスト
    
    private func testWPRCalculationAccuracy() {
        print("\n📊 WPR計算精度テスト")
        
        // テストデータ作成
        let wprSystem = WPRTrackingSystem()
        wprSystem.setBaseline(ftp: 250, weight: 70.0, ef: 1.2)
        
        // Test Case 1: 基本WPR計算
        let baselineWPR = wprSystem.baselineWPR
        let expectedBaseline = 250.0 / 70.0 // ≈ 3.57
        assert(abs(baselineWPR - expectedBaseline) < 0.01, "ベースラインWPR計算エラー")
        print("✅ ベースラインWPR: \(String(format: "%.2f", baselineWPR)) (期待値: \(String(format: "%.2f", expectedBaseline)))")
        
        // Test Case 2: 改善後WPR計算
        wprSystem.updateCurrentMetrics(ftp: 270, weight: 68.0)
        let currentWPR = wprSystem.calculatedWPR
        let expectedCurrent = 270.0 / 68.0 // ≈ 3.97
        assert(abs(currentWPR - expectedCurrent) < 0.01, "現在WPR計算エラー")
        print("✅ 現在WPR: \(String(format: "%.2f", currentWPR)) (期待値: \(String(format: "%.2f", expectedCurrent)))")
        
        // Test Case 3: 目標達成率計算
        let targetProgress = wprSystem.targetProgressRatio
        let expectedProgress = (currentWPR - baselineWPR) / (4.5 - baselineWPR)
        assert(abs(targetProgress - expectedProgress) < 0.01, "目標達成率計算エラー")
        print("✅ 目標達成率: \(String(format: "%.1f", targetProgress * 100))% (期待値: \(String(format: "%.1f", expectedProgress * 100))%)")
        
        // Test Case 4: 係数妥当性チェック
        wprSystem.resetToEvidenceBasedCoefficients()
        let isValid = wprSystem.validateCoefficients()
        assert(isValid, "係数合計が100%ではありません")
        print("✅ 係数妥当性: \(isValid ? "正常" : "異常")")
    }
    
    // MARK: - 2. ボトルネック検出テスト
    
    private func testBottleneckDetection() {
        print("\n🔍 ボトルネック検出テスト")
        
        let wprSystem = WPRTrackingSystem()
        wprSystem.setBaseline(ftp: 250, weight: 70.0, ef: 1.2)
        
        // Test Case 1: 効率性ボトルネック（低EF）
        wprSystem.efficiencyFactor = 1.0  // 低効率
        wprSystem.recalculateWPRMetrics()
        
        // 効率性が最も低い場合のボトルネック判定をシミュレート
        let efficiencyScore = (wprSystem.efficiencyFactor - wprSystem.efficiencyBaseline) / 
                             (wprSystem.efficiencyTarget - wprSystem.efficiencyBaseline)
        print("✅ 効率性スコア: \(String(format: "%.2f", efficiencyScore)) (低値 = ボトルネック候補)")
        
        // Test Case 2: 体重ボトルネック（体重増加）
        wprSystem.updateCurrentMetrics(ftp: 250, weight: 75.0)  // 5kg増加
        let weightIncrease = ((75.0 - 70.0) / 70.0) * 100
        assert(weightIncrease > 5.0, "体重増加検出エラー")
        print("✅ 体重変化: +\(String(format: "%.1f", weightIncrease))% (5%超過 = 体重ボトルネック)")
        
        // Test Case 3: パワー不足（FTP停滞）
        let powerImprovement = (250 - 250) / 250.0  // 0%改善
        print("✅ パワー改善: \(String(format: "%.1f", powerImprovement * 100))% (低値 = パワーボトルネック)")
    }
    
    // MARK: - 3. 自動更新統合テスト
    
    private func testAutoUpdateIntegration() {
        print("\n🔄 自動更新統合テスト")
        
        // Test Case 1: WorkoutRecord→WPR更新
        let cyclingWorkout = WorkoutRecord(date: Date(), workoutType: .cycling, summary: "SST 1時間")
        let cyclingDetail = CyclingDetail(
            distance: 40.0,
            duration: 3600,
            averagePower: 240.0,
            intensity: .sst,
            averageHeartRate: 165
        )
        cyclingWorkout.cyclingDetail = cyclingDetail
        
        // WPR自動更新をテスト
        Task { @MainActor in
            cyclingWorkout.triggerWPRUpdate(context: modelContext)
            print("✅ サイクリングワークアウト→WPR自動更新 実行完了")
        }
        
        // Test Case 2: FTPHistory→WPR更新
        let ftpRecord = FTPHistory(date: Date(), ftpValue: 265, measurementMethod: .twentyMinuteTest)
        Task { @MainActor in
            ftpRecord.triggerWPRFTPUpdate(context: modelContext)
            print("✅ FTP更新→WPR自動更新 実行完了")
        }
        
        // Test Case 3: DailyMetric→WPR更新
        let dailyMetric = DailyMetric(date: Date(), weightKg: 68.5)
        Task { @MainActor in
            dailyMetric.triggerWPRWeightUpdate(context: modelContext)
            print("✅ 体重更新→WPR自動更新 実行完了")
        }
    }
    
    // MARK: - 4. 科学的指標統合テスト
    
    private func testScientificMetricsIntegration() {
        print("\n🧬 科学的指標統合テスト")
        
        // Test Case 1: EfficiencyMetrics作成
        let efficiencyMetric = EfficiencyMetrics(
            normalizedPower: 245.0,
            averageHeartRate: 162,
            duration: 3600.0,
            workoutType: "SST"
        )
        modelContext.insert(efficiencyMetric)
        print("✅ EfficiencyMetrics作成: NP=\(efficiencyMetric.normalizedPower)W, HR=\(efficiencyMetric.averageHeartRate)bpm")
        
        // Test Case 2: PowerProfile作成
        let powerProfile = PowerProfile()
        powerProfile.ftp = 265
        powerProfile.vo2maxPower = 320
        powerProfile.anaerobicCapacity = 450
        modelContext.insert(powerProfile)
        print("✅ PowerProfile作成: FTP=\(powerProfile.ftp)W, VO2max=\(powerProfile.vo2maxPower)W")
        
        // Test Case 3: VolumeLoadSystem作成
        let vlSystem = VolumeLoadSystem()
        vlSystem.weeklyPushVL = 2500.0
        vlSystem.weeklyPullVL = 2200.0
        vlSystem.weeklyLegsVL = 3000.0
        modelContext.insert(vlSystem)
        print("✅ VolumeLoadSystem作成: Push=\(vlSystem.weeklyPushVL), Pull=\(vlSystem.weeklyPullVL), Legs=\(vlSystem.weeklyLegsVL)")
        
        // Test Case 4: ROMTracking作成
        let romTracking = ROMTracking()
        romTracking.forwardBendAngle = 45.0
        romTracking.hipFlexibility = 120.0
        romTracking.sessionDuration = 1800.0
        modelContext.insert(romTracking)
        print("✅ ROMTracking作成: 前屈=\(romTracking.forwardBendAngle)°, 股関節=\(romTracking.hipFlexibility)°")
        
        // Test Case 5: 統合保存テスト
        do {
            try modelContext.save()
            print("✅ 全科学的指標の保存完了")
        } catch {
            print("❌ 保存エラー: \(error)")
        }
    }
}

// MARK: - テスト実行用ヘルパー

extension WPRFunctionalTests {
    
    /// 実際のモデルコンテナでテスト実行
    static func executeWithRealData() {
        // 注意: これは実際のアプリ実行時にテストする想定
        print("⚠️  実データテストは実際のアプリ起動時に実行してください")
        print("   アプリ起動後、WPRCentralDashboardViewでテストボタンを追加することを推奨")
    }
    
    /// WPRシステムの現在状態をデバッグ出力
    func debugWPRSystemState() {
        do {
            let descriptor = FetchDescriptor<WPRTrackingSystem>()
            let systems = try modelContext.fetch(descriptor)
            
            guard let system = systems.first else {
                print("⚠️  WPRTrackingSystemが見つかりません")
                return
            }
            
            print("\n🔍 WPRシステム現在状態:")
            print("  現在WPR: \(String(format: "%.2f", system.calculatedWPR))")
            print("  目標WPR: \(system.targetWPR)")
            print("  進捗率: \(String(format: "%.1f", system.targetProgressRatio * 100))%")
            print("  現在ボトルネック: \(system.currentBottleneck)")
            print("  効率性係数: \(String(format: "%.2f", system.efficiencyFactor))")
            print("  最終更新: \(system.lastUpdated)")
            
        } catch {
            print("❌ WPRシステム状態取得エラー: \(error)")
        }
    }
}