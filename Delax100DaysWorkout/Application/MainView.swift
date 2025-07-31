import SwiftUI

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .shakeDetector(currentView: "今日")
                .tabItem {
                    Label("今日", systemImage: "calendar.day.timeline.left")
                }
                .tag(0)
            
            WeeklyScheduleView()
                .shakeDetector(currentView: "週間予定")
                .tabItem {
                    Label("週間予定", systemImage: "calendar")
                }
                .tag(1)
            
            DashboardView(viewModel: DashboardViewModel(modelContext: modelContext))
                .shakeDetector(currentView: "ダッシュボード")
                .tabItem {
                    Label("ダッシュボード", systemImage: "house.fill")
                }
                .tag(2)
            
            NavigationStack {
                LogEntryView(viewModel: LogEntryViewModel(modelContext: modelContext))
                    .shakeDetector(currentView: "記録")
            }
            .tabItem {
                Label("記録", systemImage: "plus.circle")
            }
            .tag(3)

            ProgressChartView(viewModel: ProgressChartViewModel(modelContext: modelContext))
                .shakeDetector(currentView: "進捗")
                .tabItem {
                    Label("進捗", systemImage: "chart.bar.xaxis")
                }
                .tag(4)

            SettingsView(viewModel: SettingsViewModel(modelContext: modelContext))
                .shakeDetector(currentView: "設定")
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(5)
        }
    }
}