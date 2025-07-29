import SwiftUI
import SwiftData

@main
struct Delax100DaysWorkoutApp: App {
    @StateObject private var bugReportManager = BugReportManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .shakeDetector(currentView: "MainView")
                .sheet(isPresented: $bugReportManager.isReportingBug) {
                    BugReportView(currentView: "MainView")
                }
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
            FlexibilityDetail.self
        ])
    }
}
