import SwiftUI
import SwiftData
import OSLog

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WeeklyScheduleView()
                .shakeDetector(currentView: "スケジュール")
                .tabItem {
                    Label("スケジュール", systemImage: selectedTab == 0 ? "calendar.circle.fill" : "calendar.circle")
                }
                .tag(0)
            
            UnifiedHomeDashboardView()
                .shakeDetector(currentView: "ホーム")
                .tabItem {
                    Label("ホーム", systemImage: selectedTab == 1 ? "house.circle.fill" : "house.circle")
                }
                .tag(1)
            
            WPRCentralDashboardView()
                .shakeDetector(currentView: "WPR")
                .tabItem {
                    Label("WPR", systemImage: selectedTab == 2 ? "bolt.circle.fill" : "bolt.circle")
                }
                .tag(2)
            
            SettingsView(
                viewModel: SettingsViewModel(modelContext: modelContext),
                selectedTab: $selectedTab
            )
                .shakeDetector(currentView: "設定")
                .tabItem {
                    Label("設定", systemImage: selectedTab == 3 ? "gear.circle.fill" : "gear.circle")
                }
                .tag(3)
        }
        .tint(.blue)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .onAppear {
            // アプリ起動時にHealthKit認証確認→自動同期の順序制御
            Task {
                Logger.general.info("MainView: アプリ起動時のHealthKit処理を開始")
                
                // 1. 起動前の認証状態をログ出力
                Logger.general.info("MainView: 起動時認証状態 - isAuthorized: \(healthKitManager.isAuthorized)")
                
                // 2. 認証状態を確認・リクエスト
                do {
                    Logger.general.info("MainView: requestPermissions() を実行")
                    try await healthKitManager.requestPermissions()
                    
                    // 少し待機してから状態を再確認
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                    Logger.general.info("MainView: 認証後の状態 - isAuthorized: \(healthKitManager.isAuthorized)")
                    
                } catch {
                    Logger.error.error("MainView: HealthKit認証リクエストエラー: \(error.localizedDescription)")
                }
                
                // 3. 認証完了後に自動同期を実行
                Logger.general.info("MainView: 自動同期を開始")
                await healthKitManager.autoSyncOnAppLaunch(modelContext: modelContext)
                
                // 4. バックグラウンド配信を有効化
                if healthKitManager.isAuthorized {
                    do {
                        try await healthKitManager.enableBackgroundDelivery()
                        Logger.general.info("MainView: バックグラウンド配信を有効化")
                    } catch {
                        Logger.error.error("MainView: バックグラウンド配信の有効化に失敗: \(error.localizedDescription)")
                    }
                }
                
                Logger.general.info("MainView: HealthKit処理完了")
            }
        }
    }
}