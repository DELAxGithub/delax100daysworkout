import SwiftUI
import SwiftData

struct HistoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: HistoryTab = .workouts
    
    enum HistoryTab: String, CaseIterable {
        case workouts = "ワークアウト"
        case ftp = "FTP"
        case metrics = "体重・メトリクス"
        case progress = "進捗グラフ"
        case dataManagement = "データ管理"
        
        var iconName: String {
            switch self {
            case .workouts: return "figure.run"
            case .ftp: return "bolt.fill"
            case .metrics: return "scalemass.fill"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .dataManagement: return "gear"
            }
        }
        
        var color: Color {
            switch self {
            case .workouts: return .green
            case .ftp: return .blue
            case .metrics: return .orange
            case .progress: return .purple
            case .dataManagement: return .red
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("履歴タイプ", selection: $selectedTab) {
                ForEach(HistoryTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.iconName)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                WorkoutHistoryView()
                    .tag(HistoryTab.workouts)
                
                FTPHistoryView()
                    .tag(HistoryTab.ftp)
                
                MetricsHistoryView()
                    .tag(HistoryTab.metrics)
                
                NavigationStack {
                    ProgressChartView(viewModel: ProgressChartViewModel(modelContext: modelContext))
                        .navigationTitle("進捗グラフ")
                        .navigationBarHidden(true)
                }
                .tag(HistoryTab.progress)
                
                DataManagementView()
                    .tag(HistoryTab.dataManagement)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    HistoryManagementView()
        .modelContainer(for: [WorkoutRecord.self, FTPHistory.self, DailyMetric.self])
}