import SwiftUI
import SwiftData
// import DelaxSwiftUIComponents // TODO: Add via Xcode Swift Package Manager

@main
struct Delax100DaysWorkoutApp: App {
    @StateObject private var bugReportManager = BugReportManager.shared
    
    init() {
        // BugReportManager設定（共有パッケージ互換）
        BugReportManager.shared.configure(
            gitHubToken: EnvironmentConfig.githubToken,
            gitHubOwner: EnvironmentConfig.githubOwner,
            gitHubRepo: EnvironmentConfig.githubRepo
        )
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(for: [
            UserProfile.self,
            DailyLog.self,
            WorkoutRecord.self,
            WeeklyTemplate.self,
            DailyTask.self,
            WeeklyReport.self,
            Achievement.self,
            CyclingDetail.self,
            StrengthDetail.self,
            FlexibilityDetail.self,
            // Phase 1: 自転車トレーニング集計機能用モデル
            FTPHistory.self,
            DailyMetric.self,
            // Phase 2: WPR科学的トレーニング貯金システム
            WPRTrackingSystem.self,
            EfficiencyMetrics.self,
            PowerProfile.self,
            HRAtPowerTracking.self,
            VolumeLoadSystem.self,
            ROMTracking.self,
            TrainingSavings.self
        ])
    }
}
