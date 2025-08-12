import Foundation
import SwiftData
import OSLog

@MainActor
@Observable
class SettingsViewModel {
    var goalDate: Date = Date().addingTimeInterval(100 * 24 * 60 * 60)
    var startWeightKg: Double = 0.0
    var goalWeightKg: Double = 0.0
    var startFtp: Int = 0
    var goalFtp: Int = 0

    var showSaveConfirmation = false
    
    // AI設定
    var aiAnalysisEnabled: Bool = true
    var maxCostPerUpdate: Double = 1.00
    var updateFrequencyDays: Int = 7
    var lastAnalysisDate: Date?
    var analysisCount: Int = 0
    
    // AI制御
    private var weeklyPlanManager: WeeklyPlanManager
    var isAnalyzing: Bool = false
    
    // APIキー管理
    var claudeAPIKey: String = ""
    var showingAPIKeyField: Bool = false
    var isTestingAPIKey: Bool = false
    var apiKeyTestResult: String = ""
    
    // HealthKit管理
    var healthKitService = HealthKitService()
    var isHealthKitSyncing: Bool = false
    var lastHealthKitSync: Date?

    private var modelContext: ModelContext
    private var userProfile: UserProfile?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.weeklyPlanManager = WeeklyPlanManager(modelContext: modelContext)
        fetchOrCreateUserProfile()
        loadAISettings()
        loadAPIKey()
        loadHealthKitSyncDate()
    }

    private func fetchOrCreateUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            if let profile = try modelContext.fetch(descriptor).first {
                // 既存のプロフィールを読み込む
                self.userProfile = profile
                self.goalDate = profile.goalDate
                self.startWeightKg = profile.startWeightKg
                self.goalWeightKg = profile.goalWeightKg
                self.startFtp = profile.startFtp
                self.goalFtp = profile.goalFtp
            } else {
                // プロフィールが存在しない場合、新しいデフォルトプロフィールを作成して保存
                let newProfile = UserProfile()
                modelContext.insert(newProfile)
                self.userProfile = newProfile
            }
        } catch {
            Logger.error.error("Failed to fetch UserProfile: \(error.localizedDescription)")
        }
    }

    func save() {
        guard let userProfile = userProfile else { return }

        // ViewModelの値をモデルに反映
        userProfile.goalDate = self.goalDate
        userProfile.startWeightKg = self.startWeightKg
        userProfile.goalWeightKg = self.goalWeightKg
        userProfile.startFtp = self.startFtp
        userProfile.goalFtp = self.goalFtp

        // Show confirmation alert
        showSaveConfirmation = true
    }
    
    private func loadAISettings() {
        // WeeklyPlanManagerの設定を読み込む
        self.aiAnalysisEnabled = weeklyPlanManager.autoUpdateEnabled
        self.maxCostPerUpdate = weeklyPlanManager.maxCostPerUpdate
        self.updateFrequencyDays = Int(weeklyPlanManager.updateFrequency / (24 * 60 * 60))
        self.lastAnalysisDate = weeklyPlanManager.lastUpdateDate
        self.analysisCount = weeklyPlanManager.analysisCount
    }
    
    func updateAISettings() {
        // AI設定をWeeklyPlanManagerに反映
        weeklyPlanManager.autoUpdateEnabled = self.aiAnalysisEnabled
        weeklyPlanManager.maxCostPerUpdate = self.maxCostPerUpdate
        weeklyPlanManager.updateFrequency = TimeInterval(updateFrequencyDays * 24 * 60 * 60)
    }
    
    @MainActor
    func runManualAnalysis() async {
        isAnalyzing = true
        await weeklyPlanManager.requestManualUpdate()
        lastAnalysisDate = weeklyPlanManager.lastUpdateDate
        isAnalyzing = false
    }
    
    var canRunAnalysis: Bool {
        return !isAnalyzing && weeklyPlanManager.updateStatus == .idle
    }
    
    var analysisStatusText: String {
        switch weeklyPlanManager.updateStatus {
        case .idle:
            return "分析可能"
        case .analyzing:
            return "分析中..."
        case .completed:
            return "完了"
        case .failed(_):
            return "エラー"
        }
    }
    
    // 分析情報表示用プロパティ
    var analysisDataDescription: String {
        return weeklyPlanManager.analysisDataDescription
    }
    
    var analysisResultDescription: String {
        return weeklyPlanManager.analysisResultDescription
    }
    
    var monthlyUsageDescription: String {
        return weeklyPlanManager.monthlyUsageDescription
    }
    
    // MARK: - API Key Management
    
    func loadAPIKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "claude_api_key") {
            claudeAPIKey = savedKey
        }
    }
    
    func saveAPIKey() {
        WeeklyPlanAIService.saveAPIKey(claudeAPIKey)
        // ViewModelの状態をリセット
        apiKeyTestResult = ""
        showSaveConfirmation = true
    }
    
    func clearAPIKey() {
        claudeAPIKey = ""
        WeeklyPlanAIService.clearAPIKey()
        apiKeyTestResult = ""
    }
    
    @MainActor
    func testAPIKey() async {
        guard !claudeAPIKey.isEmpty else {
            apiKeyTestResult = "APIキーを入力してください"
            return
        }
        
        isTestingAPIKey = true
        apiKeyTestResult = "テスト中..."
        
        // 一時的にAPIキーを保存してテスト
        let originalKey = UserDefaults.standard.string(forKey: "claude_api_key")
        WeeklyPlanAIService.saveAPIKey(claudeAPIKey)
        
        // 新しいサービスインスタンスでテスト
        let testService = WeeklyPlanAIService()
        let result = await testService.testAPIKey()
        
        switch result {
        case .valid:
            apiKeyTestResult = "✅ APIキーは有効です"
        case .missing:
            apiKeyTestResult = "❌ APIキーが設定されていません"
        case .invalid:
            apiKeyTestResult = "❌ APIキーの形式が無効です"
        case .untested:
            apiKeyTestResult = "⚠️ 接続テストに失敗しました"
        }
        
        // テスト結果が無効な場合は元のキーに戻す
        if result != .valid {
            if let original = originalKey {
                WeeklyPlanAIService.saveAPIKey(original)
            } else {
                WeeklyPlanAIService.clearAPIKey()
            }
        }
        
        isTestingAPIKey = false
    }
    
    var apiKeyDisplayStatus: String {
        if claudeAPIKey.isEmpty {
            return "未設定"
        } else if claudeAPIKey.hasPrefix("sk-ant-") {
            // APIキーの最初の部分のみ表示
            let prefix = String(claudeAPIKey.prefix(10))
            return "\(prefix)..."
        } else {
            return "形式エラー"
        }
    }
    
    // MARK: - HealthKit管理
    
    var healthKitAuthStatus: String {
        return healthKitService.isAuthorized ? "認証済み" : "未認証"
    }
    
    var lastHealthKitSyncDate: String {
        guard let lastSync = lastHealthKitSync else {
            return "未同期"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: lastSync)
    }
    
    func requestHealthKitAuthorization() async {
        do {
            try await healthKitService.requestAuthorization()
            if healthKitService.isAuthorized {
                await syncHealthKitData()
            }
        } catch {
            Logger.error.error("HealthKit認証エラー: \(error.localizedDescription)")
        }
    }
    
    func syncHealthKitData() async {
        guard healthKitService.isAuthorized else { return }
        
        isHealthKitSyncing = true
        
        do {
            // 過去30日間のデータを同期
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            
            // 体重データを同期
            let _ = try await healthKitService.syncWeightData(from: startDate, modelContext: modelContext)
            
            // 心拍数データを同期
            let _ = try await healthKitService.syncHeartRateData(from: startDate, modelContext: modelContext)
            
            lastHealthKitSync = Date()
            saveHealthKitSyncDate()
            
            Logger.general.info("HealthKitデータ同期完了")
            
        } catch {
            Logger.error.error("HealthKitデータ同期エラー: \(error.localizedDescription)")
        }
        
        isHealthKitSyncing = false
    }
    
    private func saveHealthKitSyncDate() {
        UserDefaults.standard.set(lastHealthKitSync, forKey: "LastHealthKitSync")
    }
    
    private func loadHealthKitSyncDate() {
        lastHealthKitSync = UserDefaults.standard.object(forKey: "LastHealthKitSync") as? Date
    }
}