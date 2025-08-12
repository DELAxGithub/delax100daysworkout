import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WeeklyScheduleView()
                .shakeDetector(currentView: "スケジュール")
                .tabItem {
                    Label("スケジュール", systemImage: "calendar")
                }
                .tag(0)
            
            UnifiedHomeDashboardView()
                .shakeDetector(currentView: "ホーム")
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(1)
            
            WPRCentralDashboardView()
                .shakeDetector(currentView: "WPR")
                .tabItem {
                    Label("WPR", systemImage: "bolt.fill")
                }
                .tag(2)
            

            SettingsView(viewModel: SettingsViewModel(modelContext: modelContext))
                .shakeDetector(currentView: "設定")
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(3)
        }
    }
}