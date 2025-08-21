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
                    
                    // 科学的指標概要 (簡素化)
                    if let optimizationEngine = optimizationEngine {
                        VStack {
                            Text("科学的指標概要")
                                .font(.headline)
                            Text("最適化エンジン実行中...")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // 機能テストカード
                    FunctionalTestCard(
                        onRunTests: {
                            runFunctionalTests()
                        },
                        testResults: testResults
                    )
                    
                    // テスト結果サマリー（テスト実行後に表示）
                    if !testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("テスト結果")
                                .font(.headline)
                            ForEach(testResults.suffix(5), id: \.self) { result in
                                Text(result)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
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
        .sheet(isPresented: $showingTestResults) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(testResults, id: \.self) { result in
                            Text(result)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .navigationTitle("テスト結果")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了") {
                            showingTestResults = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingTargetSettings) {
            WPRTargetSettingsSheet(system: wprSystem)
        }
    }
    
    private func setupWPRSystem() {
        // WPR自動更新サービスは簡単化のため無効化
        
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
    
    // MARK: - Test Functions
    private func runFunctionalTests() {
        WPRTestRunner.runAllTests(
            modelContext: modelContext,
            wprSystem: wprSystem
        ) { results in
            testResults = results
            showingTestResults = true
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

#Preview {
    WPRCentralDashboardView()
        .modelContainer(for: [
            WPRTrackingSystem.self,
            WorkoutRecord.self,
            FTPHistory.self,
            DailyMetric.self
        ])
}