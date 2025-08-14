import SwiftUI
import SwiftData
// DelaxSwiftUIComponents will be added when needed via Swift Package Manager

@main
struct Delax100DaysWorkoutApp: App {
    @StateObject private var bugReportManager = BugReportManager.shared
    @StateObject private var diContainer = DIContainer.shared
    
    private let modelContainer: ModelContainer
    
    init() {
        // Initialize ModelContainer
        do {
            modelContainer = try ModelContainer(for:
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
                FTPHistory.self,
                DailyMetric.self,
                WPRTrackingSystem.self,
                TrainingSavings.self,
                TaskCompletionCounter.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Configure DI Container with app services
        DIContainer.shared.configureAppServices(modelContainer: modelContainer)
        
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
                .diContainer(diContainer)
        }
        .modelContainer(modelContainer)
    }
}
