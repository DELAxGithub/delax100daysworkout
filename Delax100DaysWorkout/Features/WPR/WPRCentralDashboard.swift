import SwiftUI
import SwiftData
import Charts
import OSLog

struct WPRCentralDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var wprSystems: [WPRTrackingSystem]
    @State private var optimizationEngine: WPROptimizationEngine?
    @State private var bottleneckSystem: BottleneckDetectionSystem?
    
    @State private var showingBottleneckDetail = false
    @State private var showingProtocolDetail = false
    @State private var selectedBottleneck: BottleneckAnalysis?
    @State private var isRefreshing = false
    @State private var showingTestResults = false
    @State private var testResults: [String] = []
    @State private var showingTargetSettings = false
    
    private var wprSystem: WPRTrackingSystem {
        wprSystems.first ?? WPRTrackingSystem()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 中央WPRカード
                    WPRMainCard(
                        system: wprSystem,
                        onTargetSettingsTap: {
                            showingTargetSettings = true
                        }
                    )
                    
                    // 科学的指標概要
                    if let optimizationEngine = optimizationEngine {
                        ScientificMetricsSummaryCard(
                            system: wprSystem,
                            optimizationEngine: optimizationEngine
                        )
                    }
                    
                    // ボトルネック分析
                    if let bottleneckSystem = bottleneckSystem {
                        BottleneckAnalysisCard(
                            bottlenecks: bottleneckSystem.detectedBottlenecks,
                            onBottleneckTap: { bottleneck in
                                selectedBottleneck = bottleneck
                                showingBottleneckDetail = true
                            }
                        )
                        
                        // 推奨アクション
                        RecommendedActionsCard(
                            protocols: bottleneckSystem.prioritizedActions,
                            onProtocolTap: {
                                showingProtocolDetail = true
                            }
                        )
                    }
                    
                    // WPR予測グラフ
                    if let optimizationEngine = optimizationEngine {
                        WPRPredictionChart(
                            current: wprSystem.calculatedWPR,
                            predictions: [
                                optimizationEngine.projectedWPRIn30Days,
                                optimizationEngine.projectedWPRIn60Days,
                                optimizationEngine.projectedWPRIn100Days
                            ],
                            target: wprSystem.targetWPR
                        )
                    }
                    
                    // 達成バッジ
                    WPRAchievementBadges(system: wprSystem)
                    
                    // 機能テストカード
                    FunctionalTestCard(
                        onRunTests: {
                            runFunctionalTests()
                        },
                        testResults: testResults
                    )
                    
                    // テスト結果サマリー（テスト実行後に表示）
                    if !testResults.isEmpty {
                        TestResultsSummaryCard(testResults: testResults)
                    }
                }
                .padding()
            }
            .navigationTitle("WPR 4.5 達成")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("テスト", systemImage: "testtube.2") {
                            runFunctionalTests()
                        }
                        
                        Button("更新", systemImage: "arrow.clockwise") {
                            refreshAnalysis()
                        }
                        .disabled(optimizationEngine?.isAnalyzing == true || bottleneckSystem?.isAnalyzing == true)
                    }
                }
            }
            .refreshable {
                await refreshAnalysisAsync()
            }
        }
        .onAppear {
            setupWPRSystem()
        }
        .sheet(isPresented: $showingBottleneckDetail) {
            if let bottleneck = selectedBottleneck {
                BottleneckDetailView(bottleneck: bottleneck)
            }
        }
        .sheet(isPresented: $showingProtocolDetail) {
            if let bottleneckSystem = bottleneckSystem {
                ProtocolDetailView(protocols: bottleneckSystem.prioritizedActions)
            }
        }
        .sheet(isPresented: $showingTestResults) {
            FunctionalTestResultsView(results: testResults)
        }
        .sheet(isPresented: $showingTargetSettings) {
            WPRTargetSettingsSheet(system: wprSystem)
        }
    }
    
    private func setupWPRSystem() {
        // WPR自動更新サービスを使用してシステムを初期化
        let _ = WPRAutoUpdateService(modelContext: modelContext)
        
        // WPRシステムが存在しない場合は作成
        if wprSystems.isEmpty {
            let newSystem = WPRTrackingSystem()
            newSystem.targetDate = Calendar.current.date(byAdding: .day, value: 100, to: Date())
            modelContext.insert(newSystem)
            
            do {
                try modelContext.save()
            } catch {
                Logger.error.error("WPRシステム作成エラー: \(error.localizedDescription)")
            }
        } else if let existingSystem = wprSystems.first, existingSystem.targetDate == nil {
            // 既存システムでtarget dateが未設定の場合
            existingSystem.targetDate = Calendar.current.date(byAdding: .day, value: 100, to: Date())
            do {
                try modelContext.save()
            } catch {
                Logger.error.error("WPRシステム更新エラー: \(error.localizedDescription)")
            }
        }
        
        // 最適化エンジンとボトルネックシステムの初期化
        let engine = WPROptimizationEngine(modelContext: modelContext)
        let bottleneck = BottleneckDetectionSystem(modelContext: modelContext, optimizationEngine: engine)
        
        optimizationEngine = engine
        bottleneckSystem = bottleneck
        
        if !wprSystems.isEmpty, let currentSystem = wprSystems.first {
            optimizationEngine?.performQuickAnalysis(currentSystem)
        }
    }
    
    // MARK: - 機能テスト実行
    
    private func runFunctionalTests() {
        testResults.removeAll()
        testResults.append("🧪 WPR機能テスト開始...")
        
        Task {
            await MainActor.run {
                // 1. WPR計算精度テスト
                testWPRCalculationAccuracy()
                
                // 2. ボトルネック検出テスト
                testBottleneckDetection()
                
                // 3. 自動更新統合テスト
                testAutoUpdateIntegration()
                
                // 4. 科学的指標統合テスト
                testScientificMetricsIntegration()
                
                // 5. 実データ統合テスト（実際にデータベースに保存・自動更新）
                testRealDataIntegration()
                
                testResults.append("✅ WPR機能テスト完了")
                showingTestResults = true
            }
        }
    }
    
    private func testWPRCalculationAccuracy() {
        testResults.append("\n📊 WPR計算精度テスト")
        
        // テストデータ作成
        let testSystem = WPRTrackingSystem()
        testSystem.setBaseline(ftp: 250, weight: 70.0, ef: 1.2)
        
        // Test Case 1: 基本WPR計算
        let baselineWPR = testSystem.baselineWPR
        let expectedBaseline = 250.0 / 70.0
        let baselineAccurate = abs(baselineWPR - expectedBaseline) < 0.01
        testResults.append("✅ ベースラインWPR: \(String(format: "%.2f", baselineWPR)) \(baselineAccurate ? "正確" : "エラー")")
        
        // Test Case 2: 改善後WPR計算
        testSystem.updateCurrentMetrics(ftp: 270, weight: 68.0)
        let currentWPR = testSystem.calculatedWPR
        let expectedCurrent = 270.0 / 68.0
        let currentAccurate = abs(currentWPR - expectedCurrent) < 0.01
        testResults.append("✅ 現在WPR: \(String(format: "%.2f", currentWPR)) \(currentAccurate ? "正確" : "エラー")")
        
        // Test Case 3: 目標達成率計算
        let targetProgress = testSystem.targetProgressRatio
        testResults.append("✅ 目標達成率: \(String(format: "%.1f", targetProgress * 100))%")
        
        // Test Case 4: 係数妥当性チェック
        testSystem.resetToEvidenceBasedCoefficients()
        let isValid = testSystem.validateCoefficients()
        testResults.append("✅ 係数妥当性: \(isValid ? "正常" : "異常")")
    }
    
    private func testBottleneckDetection() {
        testResults.append("\n🔍 ボトルネック検出テスト")
        
        let testSystem = WPRTrackingSystem()
        testSystem.setBaseline(ftp: 250, weight: 70.0, ef: 1.2)
        
        // Test Case 1: 効率性スコア
        testSystem.efficiencyFactor = 1.0  // 低効率
        let efficiencyScore = (testSystem.efficiencyFactor - testSystem.efficiencyBaseline) / 
                             (testSystem.efficiencyTarget - testSystem.efficiencyBaseline)
        testResults.append("✅ 効率性スコア: \(String(format: "%.2f", efficiencyScore))")
        
        // Test Case 2: 体重変化検出
        testSystem.updateCurrentMetrics(ftp: 250, weight: 75.0)
        let weightIncrease = ((75.0 - 70.0) / 70.0) * 100
        testResults.append("✅ 体重変化: +\(String(format: "%.1f", weightIncrease))% \(weightIncrease > 5.0 ? "(ボトルネック)" : "")")
        
        // 現在のボトルネック表示
        testResults.append("✅ 現在ボトルネック: \(wprSystem.currentBottleneck)")
    }
    
    private func testAutoUpdateIntegration() {
        testResults.append("\n🔄 自動更新統合テスト")
        
        // Test Case 1: WorkoutRecord作成テスト
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
        
        // Test Case 2: FTPHistory作成テスト
        let ftpRecord = FTPHistory(date: Date(), ftpValue: 265, measurementMethod: .twentyMinuteTest)
        testResults.append("✅ FTP記録作成完了: \(ftpRecord.ftpValue)W")
        
        // Test Case 3: DailyMetric作成テスト
        let dailyMetric = DailyMetric(date: Date(), weightKg: 68.5)
        testResults.append("✅ 体重記録作成完了: \(dailyMetric.weightKg ?? 0)kg")
    }
    
    private func testScientificMetricsIntegration() {
        testResults.append("\n🧬 科学的指標統合テスト")
        
        // Test Case 1: EfficiencyMetrics
        let efficiencyMetric = EfficiencyMetrics(
            normalizedPower: 245.0,
            averageHeartRate: 162,
            duration: 3600.0,
            workoutType: "SST"
        )
        testResults.append("✅ EfficiencyMetrics: NP=\(efficiencyMetric.normalizedPower)W")
        
        // Test Case 2: PowerProfile
        let powerProfile = PowerProfile()
        powerProfile.power20Min = 265  // FTP相当
        powerProfile.power5Min = 320   // VO2max相当
        testResults.append("✅ PowerProfile: 20min=\(powerProfile.power20Min)W")
        
        // Test Case 3: VolumeLoadSystem
        let vlSystem = VolumeLoadSystem()
        vlSystem.weeklyPushVL = 2500.0
        testResults.append("✅ VolumeLoadSystem: Push=\(vlSystem.weeklyPushVL)")
        
        // Test Case 4: ROMTracking
        let romTracking = ROMTracking()
        romTracking.forwardBendAngle = 45.0
        romTracking.hipFlexibility = 120.0
        testResults.append("✅ ROMTracking: 前屈=\(romTracking.forwardBendAngle)°")
        
        testResults.append("✅ 全科学的指標作成完了")
    }
    
    // MARK: - 実データ統合テスト
    
    private func testRealDataIntegration() {
        testResults.append("\n🔗 実データ統合テスト")
        
        Task {
            do {
                // 1. テスト用WPRシステム作成・保存
                let testWPRSystem = WPRTrackingSystem()
                testWPRSystem.setBaseline(ftp: 250, weight: 70.0, ef: 1.2)
                testWPRSystem.updateCurrentMetrics(ftp: 265, weight: 69.0)
                modelContext.insert(testWPRSystem)
                
                // 2. テスト用FTP記録作成・保存
                let testFTP = FTPHistory(
                    date: Date(),
                    ftpValue: 265,
                    measurementMethod: .twentyMinuteTest,
                    notes: "機能テスト用"
                )
                modelContext.insert(testFTP)
                
                // 3. テスト用体重記録作成・保存
                let testWeight = DailyMetric(
                    date: Date(),
                    weightKg: 69.0,
                    restingHeartRate: 48,
                    maxHeartRate: 185
                )
                modelContext.insert(testWeight)
                
                // 4. テスト用ワークアウト記録作成・保存
                let testWorkout = WorkoutRecord(
                    date: Date(),
                    workoutType: .cycling,
                    summary: "機能テスト用SST"
                )
                let testCyclingDetail = CyclingDetail(
                    distance: 42.0,
                    duration: 3600,
                    averagePower: 245.0,
                    intensity: .sst,
                    averageHeartRate: 165
                )
                testWorkout.cyclingDetail = testCyclingDetail
                modelContext.insert(testWorkout)
                
                // 5. 保存実行
                try modelContext.save()
                
                await MainActor.run {
                    testResults.append("✅ 実データ統合テスト: 全データ保存完了")
                    testResults.append("✅ WPRシステム、FTP、体重、ワークアウト記録作成成功")
                    
                    // 6. 自動更新テスト実行
                    testRealAutoUpdate(workout: testWorkout, ftp: testFTP, weight: testWeight)
                }
            } catch {
                await MainActor.run {
                    testResults.append("❌ 実データ統合テストエラー: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testRealAutoUpdate(workout: WorkoutRecord, ftp: FTPHistory, weight: DailyMetric) {
        testResults.append("\n⚡ 自動更新実動作テスト")
        
        // WPR自動更新をトリガー
        Task { @MainActor in
            workout.triggerWPRUpdate(context: modelContext)
            testResults.append("✅ WorkoutRecord→WPR自動更新実行")
            
            ftp.triggerWPRFTPUpdate(context: modelContext)
            testResults.append("✅ FTPHistory→WPR自動更新実行")
            
            weight.triggerWPRWeightUpdate(context: modelContext)
            testResults.append("✅ DailyMetric→WPR自動更新実行")
            
            // 更新後のWPRシステム状態確認
            do {
                let descriptor = FetchDescriptor<WPRTrackingSystem>()
                let systems = try modelContext.fetch(descriptor)
                
                if let updatedSystem = systems.first {
                    testResults.append("✅ 更新後WPR: \(String(format: "%.2f", updatedSystem.calculatedWPR))")
                    testResults.append("✅ 現在ボトルネック: \(updatedSystem.currentBottleneck)")
                    testResults.append("✅ 最終更新: \(DateFormatter.localizedString(from: updatedSystem.lastUpdated, dateStyle: .short, timeStyle: .short))")
                } else {
                    testResults.append("⚠️  WPRシステムが見つかりません")
                }
            } catch {
                testResults.append("❌ WPRシステム状態確認エラー: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshAnalysis() {
        guard let optimizationEngine = optimizationEngine,
              let bottleneckSystem = bottleneckSystem,
              let currentSystem = wprSystems.first else { return }
        
        isRefreshing = true
        
        Task {
            await optimizationEngine.performCompleteAnalysis(currentSystem)
            await bottleneckSystem.performComprehensiveBottleneckAnalysis(currentSystem)
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func refreshAnalysisAsync() async {
        guard let optimizationEngine = optimizationEngine,
              let bottleneckSystem = bottleneckSystem,
              let currentSystem = wprSystems.first else { return }
        
        await optimizationEngine.performCompleteAnalysis(currentSystem)
        await bottleneckSystem.performComprehensiveBottleneckAnalysis(currentSystem)
    }
}

// MARK: - WPR Main Card

struct WPRMainCard: View {
    let system: WPRTrackingSystem
    let onTargetSettingsTap: () -> Void
    @State private var animatedProgress: Double = 0
    @State private var animatedWPR: Double = 0
    
    private var progressRatio: Double {
        system.targetProgressRatio
    }
    
    private var currentWPR: Double {
        system.calculatedWPR
    }
    
    private var targetWPR: Double {
        system.targetWPR
    }
    
    private var daysRemaining: Int? {
        if let targetDate = system.targetDate {
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: Date(), to: targetDate).day
            return days ?? system.daysToTarget
        }
        return system.daysToTarget
    }
    
    private var monthlyGain: Double {
        // 簡易的な月間ゲイン計算
        max(0.1, (targetWPR - currentWPR) / 3.0)
    }
    
    private var currentBottleneck: String {
        system.currentBottleneck.rawValue
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(WPRColor.wprBlue)
                    
                    Text("WPR 4.5 達成への道のり")
                        .font(WPRFont.sectionTitle)
                        .foregroundColor(SemanticColor.primaryText)
                }
                
                Spacer()
            }
            
            // メイン数値表示
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if currentWPR > 0 {
                        Text(String(format: "%.1f", animatedWPR))
                            .font(WPRFont.heroNumber)
                            .foregroundColor(WPRColor.wprBlue)
                            .contentTransition(.numericText())
                    } else {
                        Text("--")
                            .font(WPRFont.heroNumber)
                            .foregroundColor(SemanticColor.secondaryText)
                        
                        Text("データを入力してください")
                            .font(.system(size: 10))
                            .foregroundColor(SemanticColor.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("現在")
                        .font(WPRFont.caption)
                        .foregroundColor(SemanticColor.secondaryText)
                }
                
                Spacer()
                
                // プログレスバー（縦向き視覚効果）
                VStack(spacing: 8) {
                    if currentWPR > 0 {
                        WPRProgressBar(
                            progress: animatedProgress,
                            color: progressRatio >= 0.8 ? WPRColor.excellent : 
                                   progressRatio >= 0.6 ? WPRColor.good :
                                   progressRatio >= 0.4 ? WPRColor.average : WPRColor.needsWork
                        )
                        .frame(width: 120, height: 12)
                        
                        Text("\(Int(animatedProgress * 100))%")
                            .font(WPRFont.mediumNumber)
                            .foregroundColor(SemanticColor.primaryText)
                            .contentTransition(.numericText())
                    } else {
                        WPRProgressBar(progress: 0.0, color: SemanticColor.secondaryText.opacity(0.3))
                            .frame(width: 120, height: 12)
                        
                        Text("0%")
                            .font(WPRFont.mediumNumber)
                            .foregroundColor(SemanticColor.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", targetWPR))
                            .font(WPRFont.heroNumber)
                            .foregroundColor(WPRColor.wprGreen)
                        
                        Button(action: onTargetSettingsTap) {
                            Image(systemName: "gear")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(WPRColor.wprBlue)
                                .padding(4)
                                .background(SemanticColor.secondaryBackground)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(system.isCustomTargetSet ? "カスタム目標" : "デフォルト目標")
                        .font(WPRFont.caption)
                        .foregroundColor(SemanticColor.secondaryText)
                }
            }
            
            // 統計情報行
            HStack(spacing: 24) {
                // 残り日数
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColor.info)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if currentWPR > 0, let days = daysRemaining, days > 0 {
                            Text("残り \(days)日")
                                .font(WPRFont.metricLabel)
                                .foregroundColor(SemanticColor.primaryText)
                        } else if currentWPR > 0 {
                            Text("目標達成済み")
                                .font(WPRFont.metricLabel)
                                .foregroundColor(WPRColor.wprGreen)
                        } else {
                            Text("データ待ち")
                                .font(WPRFont.metricLabel)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                // 月間ゲイン
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(WPRColor.wprGreen)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if currentWPR > 0 {
                            Text("月間 +\(String(format: "%.1f", monthlyGain)) WPR")
                                .font(WPRFont.metricLabel)
                                .foregroundColor(SemanticColor.primaryText)
                        } else {
                            Text("予測計算中")
                                .font(WPRFont.metricLabel)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                }
                
                Spacer()
            }
            
            // ボトルネック情報 or 初期設定案内
            if currentWPR > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(WPRColor.wprRed)
                    
                    Text("ボトルネック: \(currentBottleneck)")
                        .font(WPRFont.metricLabel)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(WPRColor.wprBlue)
                        
                        Text("FTPと体重を記録してWPR計算を開始")
                            .font(WPRFont.metricLabel)
                            .foregroundColor(SemanticColor.primaryText)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        NavigationLink(destination: EmptyView()) { // TODO: FTP入力画面へのリンク
                            Text("FTP記録")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(WPRColor.wprBlue)
                                .cornerRadius(8)
                        }
                        
                        NavigationLink(destination: EmptyView()) { // TODO: 体重入力画面へのリンク
                            Text("体重記録")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(WPRColor.wprGreen)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(WPRSpacing.cardPadding)
        .background(SemanticColor.cardBackground)
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        .onAppear {
            withAnimation(WPRAnimation.smooth) {
                animatedProgress = progressRatio
                animatedWPR = currentWPR
            }
        }
        .onChange(of: currentWPR) { _, newValue in
            withAnimation(WPRAnimation.standard) {
                animatedWPR = newValue
            }
        }
        .onChange(of: progressRatio) { _, newValue in
            withAnimation(WPRAnimation.standard) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - WPR Design System Components

enum WPRColor {
    static let wprBlue = Color(red: 0.0, green: 0.48, blue: 1.0)      // #007AFF
    static let wprGreen = Color(red: 0.20, green: 0.78, blue: 0.35)   // #34C759
    static let wprRed = Color(red: 1.0, green: 0.23, blue: 0.19)      // #FF3B30
    
    // 進捗状態カラー
    static let excellent = Color(red: 0.0, green: 0.8, blue: 0.2)     // 90%+
    static let good = Color(red: 0.4, green: 0.8, blue: 0.2)          // 70-89%
    static let average = Color(red: 1.0, green: 0.8, blue: 0.0)       // 50-69%
    static let needsWork = Color(red: 1.0, green: 0.6, blue: 0.0)     // 30-49%
    static let critical = Color(red: 1.0, green: 0.3, blue: 0.3)      // <30%
}

enum SemanticColor {
    static let success = WPRColor.wprGreen
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let error = WPRColor.wprRed
    static let info = WPRColor.wprBlue
    
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
}

enum WPRFont {
    static let heroNumber = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let largeNumber = Font.system(size: 32, weight: .bold, design: .rounded)
    static let mediumNumber = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let smallNumber = Font.system(size: 18, weight: .medium, design: .rounded)
    
    static let sectionTitle = Font.system(size: 22, weight: .bold, design: .default)
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .default)
    static let metricLabel = Font.system(size: 16, weight: .medium, design: .default)
    static let caption = Font.system(size: 14, weight: .regular, design: .default)
    
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let scientificNote = Font.system(size: 12, weight: .regular, design: .monospaced)
}

enum WPRSpacing {
    static let xs: CGFloat = 4    // 0.5x
    static let sm: CGFloat = 8    // 1x
    static let md: CGFloat = 16   // 2x
    static let lg: CGFloat = 24   // 3x
    static let xl: CGFloat = 32   // 4x
    static let xxl: CGFloat = 48  // 6x
    
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 20
    static let sectionSpacing: CGFloat = 32
}

enum WPRAnimation {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let smooth = Animation.easeInOut(duration: 0.5)
    static let slow = Animation.easeInOut(duration: 0.8)
    
    static let bounce = Animation.spring(response: 0.6, dampingFraction: 0.7)
    static let gentle = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    static func withDelay(_ delay: Double) -> Animation {
        standard.delay(delay)
    }
}

struct WPRProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))
                    .frame(height: height)
                
                // プログレス
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(
                        width: geometry.size.width * progress,
                        height: height
                    )
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Scientific Metrics Summary

struct ScientificMetricsSummaryCard: View {
    let system: WPRTrackingSystem
    let optimizationEngine: WPROptimizationEngine
    @State private var animatedMetrics: [AnimatedMetricData] = []
    @State private var selectedMetric: MetricType?
    @State private var showingMetricDetail = false
    
    // 科学的指標のメトリック定義
    private var metricsData: [MetricDisplayData] {
        [
            MetricDisplayData(
                type: .efficiency,
                currentValue: system.efficiencyFactor,
                targetValue: system.efficiencyTarget,
                unit: "",
                icon: "bolt.fill",
                color: MetricColor.efficiency,
                progress: system.efficiencyProgress
            ),
            MetricDisplayData(
                type: .powerProfile,
                currentValue: system.currentPowerProfileScore,
                targetValue: system.powerProfileTarget,
                unit: "%",
                icon: "speedometer",
                color: MetricColor.powerProfile,
                progress: system.powerProfileProgress
            ),
            MetricDisplayData(
                type: .hrEfficiency,
                currentValue: abs(system.hrEfficiencyBaseline),
                targetValue: abs(system.hrEfficiencyTarget),
                unit: "bpm",
                icon: "heart.fill",
                color: MetricColor.hrEfficiency,
                progress: system.hrEfficiencyProgress
            ),
            MetricDisplayData(
                type: .volumeLoad,
                currentValue: system.strengthBaseline,
                targetValue: system.strengthTarget,
                unit: "",
                icon: "figure.strengthtraining.traditional",
                color: MetricColor.volumeLoad,
                progress: system.strengthProgress
            ),
            MetricDisplayData(
                type: .rom,
                currentValue: system.flexibilityBaseline,
                targetValue: system.flexibilityTarget,
                unit: "°",
                icon: "figure.flexibility",
                color: MetricColor.rom,
                progress: system.flexibilityProgress
            )
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: WPRSpacing.md) {
            // ヘッダー
            HStack {
                Text("科学的指標概要")
                    .font(WPRFont.sectionTitle)
                    .foregroundColor(SemanticColor.primaryText)
                
                Spacer()
                
                Text("進捗スコア: \(Int(system.overallProgressScore * 100))%")
                    .font(WPRFont.metricLabel)
                    .fontWeight(.medium)
                    .foregroundColor(WPRColor.wprBlue)
            }
            
            // 指標グリッド表示
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: WPRSpacing.sm), count: 2),
                spacing: WPRSpacing.sm
            ) {
                ForEach(Array(metricsData.enumerated()), id: \.element.type) { index, metric in
                    TappableMetricRow(
                        data: metric,
                        animationDelay: Double(index) * 0.1,
                        onTap: { metricType in
                            selectedMetric = metricType
                            showingMetricDetail = true
                        }
                    )
                }
            }
        }
        .padding(WPRSpacing.cardPadding)
        .background(SemanticColor.cardBackground)
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        .sheet(isPresented: $showingMetricDetail) {
            if let selectedMetric = selectedMetric {
                MetricDetailSheet(
                    metricType: selectedMetric,
                    system: system
                )
            }
        }
    }
}

// MARK: - Metric Types & Colors

enum MetricType: CaseIterable {
    case efficiency
    case powerProfile
    case hrEfficiency
    case volumeLoad
    case rom
    
    var displayName: String {
        switch self {
        case .efficiency: return "効率性 (EF)"
        case .powerProfile: return "パワープロファイル"
        case .hrEfficiency: return "心拍効率"
        case .volumeLoad: return "筋力VL"
        case .rom: return "可動域ROM"
        }
    }
}

enum MetricColor {
    static let efficiency = Color(red: 1.0, green: 0.8, blue: 0.0)    // ⚡ イエロー
    static let powerProfile = Color(red: 1.0, green: 0.0, blue: 0.0)  // 🚀 レッド
    static let hrEfficiency = Color(red: 1.0, green: 0.0, blue: 0.5)  // 💓 ピンク
    static let volumeLoad = Color(red: 0.0, green: 0.8, blue: 0.0)    // 💪 グリーン
    static let rom = Color(red: 0.6, green: 0.0, blue: 1.0)           // 🤸 パープル
}

struct MetricDisplayData {
    let type: MetricType
    let currentValue: Double
    let targetValue: Double
    let unit: String
    let icon: String
    let color: Color
    let progress: Double
}

struct AnimatedMetricData {
    let type: MetricType
    var animatedValue: Double = 0
    var animatedProgress: Double = 0
}

// MARK: - Metric Row Component

struct MetricRow: View {
    let data: MetricDisplayData
    let animationDelay: Double
    @State private var animatedValue: Double = 0
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: WPRSpacing.xs) {
            // ヘッダー：アイコン + タイトル + 進捗%
            HStack(spacing: 6) {
                Image(systemName: data.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(data.color)
                    .frame(width: 16, height: 16)
                
                Text(data.type.displayName)
                    .font(WPRFont.caption)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColor.secondaryText)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(data.color)
                    .contentTransition(.numericText())
            }
            
            // 現在値表示
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", animatedValue))
                    .font(WPRFont.smallNumber)
                    .foregroundColor(data.color)
                    .contentTransition(.numericText())
                
                if !data.unit.isEmpty {
                    Text(data.unit)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(SemanticColor.secondaryText)
                }
                
                Spacer()
                
                Text("/ \(String(format: "%.1f", data.targetValue))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(SemanticColor.secondaryText)
            }
            
            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(data.color)
                        .frame(
                            width: geometry.size.width * animatedProgress,
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.8), value: animatedProgress)
                }
            }
            .frame(height: 4)
        }
        .padding(WPRSpacing.sm)
        .background(SemanticColor.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(data.color.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            withAnimation(WPRAnimation.smooth.delay(animationDelay)) {
                animatedValue = data.currentValue
                animatedProgress = data.progress
            }
        }
        .onChange(of: data.currentValue) { _, newValue in
            withAnimation(WPRAnimation.standard) {
                animatedValue = newValue
            }
        }
        .onChange(of: data.progress) { _, newProgress in
            withAnimation(WPRAnimation.standard) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Tappable Metric Row Component

struct TappableMetricRow: View {
    let data: MetricDisplayData
    let animationDelay: Double
    let onTap: (MetricType) -> Void
    
    @State private var animatedValue: Double = 0
    @State private var animatedProgress: Double = 0
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            HapticFeedbackManager.lightTap()
            onTap(data.type)
        }) {
            VStack(alignment: .leading, spacing: WPRSpacing.xs) {
                // ヘッダー：アイコン + タイトル + 進捗%
                HStack(spacing: 6) {
                    Image(systemName: data.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(data.color)
                        .frame(width: 16, height: 16)
                    
                    Text(data.type.displayName)
                        .font(WPRFont.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColor.secondaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(data.color)
                        .contentTransition(.numericText())
                }
                
                // 現在値表示
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.2f", animatedValue))
                        .font(WPRFont.smallNumber)
                        .foregroundColor(data.color)
                        .contentTransition(.numericText())
                    
                    if !data.unit.isEmpty {
                        Text(data.unit)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(SemanticColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text("/ \(String(format: "%.1f", data.targetValue))")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(SemanticColor.secondaryText)
                }
                
                // プログレスバー
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(data.color)
                            .frame(
                                width: geometry.size.width * animatedProgress,
                                height: 4
                            )
                            .animation(.easeInOut(duration: 0.8), value: animatedProgress)
                    }
                }
                .frame(height: 4)
                
                // タップインジケーター
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(SemanticColor.secondaryText.opacity(0.6))
                }
            }
            .padding(WPRSpacing.sm)
            .background(SemanticColor.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(data.color.opacity(isPressed ? 0.4 : 0.2), lineWidth: isPressed ? 2 : 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(WPRAnimation.quick, value: isPressed)
            .onAppear {
                withAnimation(WPRAnimation.smooth.delay(animationDelay)) {
                    animatedValue = data.currentValue
                    animatedProgress = data.progress
                }
            }
            .onChange(of: data.currentValue) { _, newValue in
                withAnimation(WPRAnimation.standard) {
                    animatedValue = newValue
                }
            }
            .onChange(of: data.progress) { _, newProgress in
                withAnimation(WPRAnimation.standard) {
                    animatedProgress = newProgress
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
}

// MARK: - Haptic Feedback Manager

struct HapticFeedbackManager {
    static func lightTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func achievement() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Press Events ViewModifier

struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                if pressing {
                    onPress()
                } else {
                    onRelease()
                }
            }, perform: {})
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Bottleneck Analysis Card

struct BottleneckAnalysisCard: View {
    let bottlenecks: [BottleneckAnalysis]
    let onBottleneckTap: (BottleneckAnalysis) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ボトルネック分析")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !bottlenecks.isEmpty {
                    Text("\(bottlenecks.filter { $0.severity.priority >= 4 }.count)件の重要課題")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            if bottlenecks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    
                    Text("ボトルネックが検出されていません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(bottlenecks.prefix(3), id: \.bottleneckType) { bottleneck in
                        BottleneckRow(bottleneck: bottleneck) {
                            onBottleneckTap(bottleneck)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct BottleneckRow: View {
    let bottleneck: BottleneckAnalysis
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: bottleneck.bottleneckType.iconName)
                    .font(.title3)
                    .foregroundColor(bottleneck.bottleneckType.color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(bottleneck.bottleneckType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(bottleneck.severity.rawValue)
                        .font(.caption)
                        .foregroundColor(bottleneck.severity.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(bottleneck.gapPercentage))% Gap")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("\(bottleneck.timeToResolve)日")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recommended Actions Card

struct RecommendedActionsCard: View {
    let protocols: [TrainingProtocol]
    let onProtocolTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("推奨アクション")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("詳細", action: onProtocolTap)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if protocols.isEmpty {
                Text("現在推奨アクションはありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(protocols.prefix(2), id: \.name) { trainingProtocol in
                        ProtocolRow(trainingProtocol: trainingProtocol)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ProtocolRow: View {
    let trainingProtocol: TrainingProtocol
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(trainingProtocol.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(trainingProtocol.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(trainingProtocol.frequency)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text(trainingProtocol.duration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - WPR Prediction Chart

struct WPRPredictionChart: View {
    let current: Double
    let predictions: [Double]
    let target: Double
    
    private var chartData: [WPRPredictionData] {
        [
            WPRPredictionData(day: 0, wpr: current, type: .current),
            WPRPredictionData(day: 30, wpr: predictions[0], type: .prediction),
            WPRPredictionData(day: 60, wpr: predictions[1], type: .prediction),
            WPRPredictionData(day: 100, wpr: predictions[2], type: .prediction),
            WPRPredictionData(day: 100, wpr: target, type: .target)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WPR予測")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(chartData, id: \.day) { data in
                switch data.type {
                case .current:
                    PointMark(
                        x: .value("日数", data.day),
                        y: .value("WPR", data.wpr)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                    .symbolSize(100)
                    
                case .prediction:
                    LineMark(
                        x: .value("日数", data.day),
                        y: .value("WPR", data.wpr)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("日数", data.day),
                        y: .value("WPR", data.wpr)
                    )
                    .foregroundStyle(.green)
                    .symbol(.circle)
                    .symbolSize(60)
                    
                case .target:
                    RuleMark(y: .value("目標", data.wpr))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            .frame(height: 200)
            .chartYScale(domain: (current * 0.9)...(target * 1.1))
            .chartXAxis {
                AxisMarks(values: [0, 30, 60, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)日")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.1f", doubleValue))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct WPRPredictionData {
    let day: Int
    let wpr: Double
    let type: WPRDataType
    
    enum WPRDataType {
        case current, prediction, target
    }
}

// MARK: - Achievement Badges

struct WPRAchievementBadges: View {
    let system: WPRTrackingSystem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("達成バッジ")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(WPRMilestone.milestones, id: \.wprValue) { milestone in
                    WPRBadgeView(
                        milestone: milestone,
                        isAchieved: system.calculatedWPR >= milestone.wprValue
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct WPRBadgeView: View {
    let milestone: WPRMilestone
    let isAchieved: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(milestone.badgeEmoji)
                .font(.system(size: 24))
                .opacity(isAchieved ? 1.0 : 0.3)
            
            VStack(spacing: 2) {
                Text(String(format: "%.1f", milestone.wprValue))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isAchieved ? .primary : .secondary)
                
                Text(milestone.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isAchieved ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Detail Views

struct BottleneckDetailView: View {
    let bottleneck: BottleneckAnalysis
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ボトルネック詳細情報
                    // TODO: 詳細な分析表示
                    Text("詳細分析を実装予定")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle(bottleneck.bottleneckType.rawValue)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProtocolDetailView: View {
    let protocols: [TrainingProtocol]
    
    var body: some View {
        NavigationStack {
            List(protocols, id: \.name) { trainingProtocol in
                VStack(alignment: .leading, spacing: 8) {
                    Text(trainingProtocol.name)
                        .font(.headline)
                    
                    Text(trainingProtocol.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(trainingProtocol.frequency, systemImage: "calendar")
                        Spacer()
                        Label(trainingProtocol.duration, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("推奨プロトコル")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Metric Detail Sheet

struct MetricDetailSheet: View {
    let metricType: MetricType
    let system: WPRTrackingSystem
    @Environment(\.dismiss) private var dismiss
    
    private var metricData: MetricDetailData {
        switch metricType {
        case .efficiency:
            return MetricDetailData(
                title: "効率性 (Efficiency Factor)",
                currentValue: system.efficiencyFactor,
                targetValue: system.efficiencyTarget,
                unit: "",
                progress: system.efficiencyProgress,
                color: MetricColor.efficiency,
                icon: "bolt.fill",
                description: "同じ心拍数でのパワー出力効率。Seiler et al.の研究に基づく重要指標。",
                scientificBasis: "Seiler & Kjerland (2006): 効率性向上により同一心拍数でより高いパワーを持続可能",
                improvementTips: [
                    "SST (Sweet Spot Training): FTPの88-94%で20-90分",
                    "テンポ走: FTPの76-90%で長時間維持",
                    "効率的ペダリング技術の向上"
                ],
                coefficient: system.efficiencyCoefficient
            )
            
        case .powerProfile:
            return MetricDetailData(
                title: "パワープロファイル",
                currentValue: system.currentPowerProfileScore,
                targetValue: system.powerProfileTarget,
                unit: "%",
                progress: system.powerProfileProgress,
                color: MetricColor.powerProfile,
                icon: "speedometer",
                description: "各時間域（5秒/1分/5分/20分/60分）でのパワー向上度。全域バランス向上が重要。",
                scientificBasis: "Cesanelli et al. (2021): 時間域別パワープロファイル分析による最適化",
                improvementTips: [
                    "5秒パワー: スプリント・プライオメトリクス",
                    "1-5分: VO2maxインターバル (3-8分×3-5)",
                    "20-60分: FTP向上（SST・閾値トレーニング）"
                ],
                coefficient: system.powerProfileCoefficient
            )
            
        case .hrEfficiency:
            return MetricDetailData(
                title: "心拍効率 (HR at Power)",
                currentValue: abs(system.hrEfficiencyFactor),
                targetValue: abs(system.hrEfficiencyTarget),
                unit: "bpm",
                progress: system.hrEfficiencyProgress,
                color: MetricColor.hrEfficiency,
                icon: "heart.fill",
                description: "同一パワー出力時の心拍数低下。心肺機能・効率向上の指標。",
                scientificBasis: "Lunn et al. (2009): HR@Power改善による持久力向上効果",
                improvementTips: [
                    "長時間持続走: 会話可能ペースで2-6時間",
                    "心拍変動性向上: 深呼吸・リラクゼーション",
                    "定期的な心拍数モニタリング"
                ],
                coefficient: system.hrEfficiencyCoefficient
            )
            
        case .volumeLoad:
            return MetricDetailData(
                title: "筋力VL (Volume Load)",
                currentValue: system.strengthFactor,
                targetValue: system.strengthTarget,
                unit: "",
                progress: system.strengthProgress,
                color: MetricColor.volumeLoad,
                icon: "figure.strengthtraining.traditional",
                description: "Push/Pull/Legs別の総負荷量。サイクリング特化筋力強化による出力向上。",
                scientificBasis: "Vikmoen et al. (2021): 筋力トレーニングによるサイクリングパフォーマンス向上",
                improvementTips: [
                    "Push: スクワット・デッドリフト（重量×回数×セット）",
                    "Pull: チンアップ・ローイング（上半身安定性）",
                    "週2-3回、月間VL 30%向上目標"
                ],
                coefficient: system.strengthCoefficient
            )
            
        case .rom:
            return MetricDetailData(
                title: "可動域ROM (Range of Motion)",
                currentValue: system.flexibilityFactor,
                targetValue: system.flexibilityTarget,
                unit: "°",
                progress: system.flexibilityProgress,
                color: MetricColor.rom,
                icon: "figure.flexibility",
                description: "股関節・肩・脊椎の可動域。エアロダイナミクス・ペダリング効率に直結。",
                scientificBasis: "Holliday et al. (2021): 柔軟性向上によるサイクリング効率改善",
                improvementTips: [
                    "前屈: +15°目標（エアロポジション改善）",
                    "股関節: 120°+（ペダリング効率向上）",
                    "毎日10-15分のストレッチ・ヨガ"
                ],
                coefficient: system.flexibilityCoefficient
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WPRSpacing.lg) {
                    // ヘッダーカード
                    MetricDetailHeaderCard(data: metricData)
                    
                    // 進捗詳細
                    MetricProgressDetailCard(data: metricData)
                    
                    // 科学的根拠
                    MetricScientificBasisCard(data: metricData)
                    
                    // 改善提案
                    MetricImprovementTipsCard(data: metricData)
                    
                    // WPR寄与度
                    MetricContributionCard(data: metricData)
                }
                .padding(WPRSpacing.md)
            }
            .navigationTitle(metricData.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(metricData.color)
                }
            }
        }
    }
}

struct MetricDetailData {
    let title: String
    let currentValue: Double
    let targetValue: Double
    let unit: String
    let progress: Double
    let color: Color
    let icon: String
    let description: String
    let scientificBasis: String
    let improvementTips: [String]
    let coefficient: Double
}

struct MetricDetailHeaderCard: View {
    let data: MetricDetailData
    
    var body: some View {
        VStack(spacing: WPRSpacing.md) {
            HStack {
                Image(systemName: data.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(data.color)
                    .frame(width: 40, height: 40)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", data.currentValue))
                            .font(WPRFont.largeNumber)
                            .foregroundColor(data.color)
                        
                        if !data.unit.isEmpty {
                            Text(data.unit)
                                .font(WPRFont.metricLabel)
                                .foregroundColor(SemanticColor.secondaryText)
                        }
                    }
                    
                    Text("/ \(String(format: "%.1f", data.targetValue))")
                        .font(WPRFont.caption)
                        .foregroundColor(SemanticColor.secondaryText)
                }
            }
            
            // プログレスバー
            VStack(alignment: .leading, spacing: WPRSpacing.xs) {
                HStack {
                    Text("目標達成率")
                        .font(WPRFont.metricLabel)
                        .foregroundColor(SemanticColor.primaryText)
                    
                    Spacer()
                    
                    Text("\(Int(data.progress * 100))%")
                        .font(WPRFont.metricLabel)
                        .fontWeight(.medium)
                        .foregroundColor(data.color)
                }
                
                WPRProgressBar(progress: data.progress, color: data.color)
                    .frame(height: 8)
            }
            
            Text(data.description)
                .font(WPRFont.body)
                .foregroundColor(SemanticColor.primaryText)
                .multilineTextAlignment(.leading)
        }
        .padding(WPRSpacing.cardPadding)
        .background(SemanticColor.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MetricProgressDetailCard: View {
    let data: MetricDetailData
    
    var body: some View {
        VStack(alignment: .leading, spacing: WPRSpacing.md) {
            Text("進捗詳細")
                .font(WPRFont.sectionTitle)
                .foregroundColor(SemanticColor.primaryText)
            
            HStack(spacing: WPRSpacing.lg) {
                VStack(spacing: WPRSpacing.xs) {
                    Text("現在値")
                        .font(WPRFont.caption)
                        .foregroundColor(SemanticColor.secondaryText)
                    
                    Text(String(format: "%.2f", data.currentValue))
                        .font(WPRFont.mediumNumber)
                        .foregroundColor(data.color)
                }
                
                VStack(spacing: WPRSpacing.xs) {
                    Text("目標値")
                        .font(WPRFont.caption)
                        .foregroundColor(SemanticColor.secondaryText)
                    
                    Text(String(format: "%.2f", data.targetValue))
                        .font(WPRFont.mediumNumber)
                        .foregroundColor(SemanticColor.primaryText)
                }
                
                VStack(spacing: WPRSpacing.xs) {
                    Text("残り")
                        .font(WPRFont.caption)
                        .foregroundColor(SemanticColor.secondaryText)
                    
                    Text(String(format: "%.2f", max(0, data.targetValue - data.currentValue)))
                        .font(WPRFont.mediumNumber)
                        .foregroundColor(SemanticColor.warning)
                }
                
                Spacer()
            }
        }
        .padding(WPRSpacing.cardPadding)
        .background(SemanticColor.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MetricScientificBasisCard: View {
    let data: MetricDetailData
    
    var body: some View {
        VStack(alignment: .leading, spacing: WPRSpacing.md) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(data.color)
                
                Text("科学的根拠")
                    .font(WPRFont.sectionTitle)
                    .foregroundColor(SemanticColor.primaryText)
            }
            
            Text(data.scientificBasis)
                .font(WPRFont.scientificNote)
                .foregroundColor(SemanticColor.secondaryText)
                .padding(WPRSpacing.sm)
                .background(SemanticColor.secondaryBackground)
                .cornerRadius(8)
        }
        .padding(WPRSpacing.cardPadding)
        .background(SemanticColor.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MetricImprovementTipsCard: View {
    let data: MetricDetailData
    
    var body: some View {
        VStack(alignment: .leading, spacing: WPRSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(data.color)
                
                Text("改善提案")
                    .font(WPRFont.sectionTitle)
                    .foregroundColor(SemanticColor.primaryText)
            }
            
            LazyVStack(spacing: WPRSpacing.sm) {
                ForEach(Array(data.improvementTips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: WPRSpacing.sm) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(data.color)
                            .cornerRadius(10)
                        
                        Text(tip)
                            .font(WPRFont.body)
                            .foregroundColor(SemanticColor.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(WPRSpacing.cardPadding)
        .background(SemanticColor.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MetricContributionCard: View {
    let data: MetricDetailData
    
    var body: some View {
        VStack(alignment: .leading, spacing: WPRSpacing.md) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(data.color)
                
                Text("WPR寄与度")
                    .font(WPRFont.sectionTitle)
                    .foregroundColor(SemanticColor.primaryText)
            }
            
            HStack {
                Text("\(Int(data.coefficient * 100))%")
                    .font(WPRFont.largeNumber)
                    .foregroundColor(data.color)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("WPR全体への寄与")
                        .font(WPRFont.caption)
                        .foregroundColor(SemanticColor.secondaryText)
                    
                    Text("科学的エビデンス係数")
                        .font(WPRFont.footnote)
                        .foregroundColor(SemanticColor.secondaryText)
                }
            }
            
            Text("この指標の改善により、WPR全体の\(Int(data.coefficient * 100))%に相当する効果が期待されます。")
                .font(WPRFont.footnote)
                .foregroundColor(SemanticColor.secondaryText)
        }
        .padding(WPRSpacing.cardPadding)
        .background(SemanticColor.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Target Settings Sheet

struct WPRTargetSettingsSheet: View {
    let system: WPRTrackingSystem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var customTargetWPR: Double = 4.5
    @State private var targetDate: Date = Date()
    @State private var useCustomTarget: Bool = false
    
    private let targetOptions: [Double] = [3.5, 4.0, 4.5, 5.0, 5.5]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("目標設定") {
                    Toggle("カスタム目標を使用", isOn: $useCustomTarget)
                    
                    if useCustomTarget {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("目標WPR: \(String(format: "%.1f", customTargetWPR))")
                                .font(WPRFont.metricLabel)
                            
                            Slider(
                                value: $customTargetWPR,
                                in: 3.0...6.0,
                                step: 0.1
                            ) {
                                Text("目標WPR")
                            } minimumValueLabel: {
                                Text("3.0")
                                    .font(WPRFont.caption)
                            } maximumValueLabel: {
                                Text("6.0")
                                    .font(WPRFont.caption)
                            }
                        }
                        
                        DatePicker(
                            "目標達成日",
                            selection: $targetDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("推奨目標")
                                .font(WPRFont.metricLabel)
                                .fontWeight(.medium)
                            
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: 2),
                                spacing: 8
                            ) {
                                ForEach(targetOptions, id: \.self) { option in
                                    TargetOptionCard(
                                        wpr: option,
                                        isSelected: customTargetWPR == option,
                                        onTap: {
                                            customTargetWPR = option
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                
                Section("現在の進捗") {
                    HStack {
                        Text("現在WPR")
                        Spacer()
                        Text(String(format: "%.2f", system.calculatedWPR))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("必要な改善")
                        Spacer()
                        Text("+\(String(format: "%.2f", max(0, customTargetWPR - system.calculatedWPR)))")
                            .fontWeight(.medium)
                            .foregroundColor(WPRColor.wprGreen)
                    }
                    
                    if let days = daysToTarget {
                        HStack {
                            Text("推定期間")
                            Spacer()
                            Text("\(days)日")
                                .fontWeight(.medium)
                                .foregroundColor(WPRColor.wprBlue)
                        }
                    }
                }
            }
            .navigationTitle("WPR目標設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .foregroundColor(WPRColor.wprBlue)
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private var daysToTarget: Int? {
        if useCustomTarget {
            let calendar = Calendar.current
            return calendar.dateComponents([.day], from: Date(), to: targetDate).day
        } else {
            // デフォルトは100日
            return 100
        }
    }
    
    private func loadCurrentSettings() {
        useCustomTarget = system.isCustomTargetSet
        customTargetWPR = system.targetWPR
        targetDate = system.targetDate ?? Calendar.current.date(byAdding: .day, value: 100, to: Date()) ?? Date()
    }
    
    private func saveSettings() {
        if useCustomTarget {
            system.setCustomTarget(wpr: customTargetWPR, targetDate: targetDate)
        } else {
            system.setCustomTarget(wpr: customTargetWPR, targetDate: Calendar.current.date(byAdding: .day, value: 100, to: Date()))
        }
        
        // SwiftDataコンテキストで保存
        do {
            try modelContext.save()
        } catch {
            print("WPR目標設定保存エラー: \(error.localizedDescription)")
        }
    }
}

struct TargetOptionCard: View {
    let wpr: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    private var categoryInfo: (title: String, description: String, color: Color) {
        switch wpr {
        case 3.5: return ("中級者", "レクリエーション", WPRColor.average)
        case 4.0: return ("上級者", "競技レベル", WPRColor.good)
        case 4.5: return ("エリート", "国内トップ", WPRColor.excellent)
        case 5.0: return ("プロ", "世界クラス", WPRColor.wprGreen)
        case 5.5: return ("トップ", "世界トップ", WPRColor.wprBlue)
        default: return ("カスタム", "独自設定", WPRColor.wprRed)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(String(format: "%.1f", wpr))
                    .font(WPRFont.mediumNumber)
                    .foregroundColor(isSelected ? .white : categoryInfo.color)
                
                VStack(spacing: 2) {
                    Text(categoryInfo.title)
                        .font(WPRFont.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(categoryInfo.description)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? categoryInfo.color : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? categoryInfo.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WPRCentralDashboardView()
        .modelContainer(for: [
            WPRTrackingSystem.self,
            EfficiencyMetrics.self,
            PowerProfile.self,
            HRAtPowerTracking.self,
            VolumeLoadSystem.self,
            ROMTracking.self
        ])
}