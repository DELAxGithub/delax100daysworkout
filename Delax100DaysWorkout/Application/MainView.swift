import SwiftUI

struct MainView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "calendar.day.timeline.left")
                }
            
            WeeklyScheduleView()
                .tabItem {
                    Label("週間予定", systemImage: "calendar")
                }
            
            DashboardView(viewModel: DashboardViewModel(modelContext: modelContext))
                .tabItem {
                    Label("ダッシュボード", systemImage: "house.fill")
                }
            
            NavigationStack {
                LogEntryView(viewModel: LogEntryViewModel(modelContext: modelContext))
            }
            .tabItem {
                Label("記録", systemImage: "plus.circle")
            }

            ProgressChartView(viewModel: ProgressChartViewModel(modelContext: modelContext))
                .tabItem {
                    Label("進捗", systemImage: "chart.bar.xaxis")
                }

            SettingsView(viewModel: SettingsViewModel(modelContext: modelContext))
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
    }
}