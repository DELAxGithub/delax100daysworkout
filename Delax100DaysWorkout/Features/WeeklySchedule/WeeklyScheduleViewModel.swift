import Foundation
import SwiftData
import SwiftUI

@Observable
class WeeklyScheduleViewModel {
    var completedTasks: Set<PersistentIdentifier> = []
    var showingQuickRecord = false
    var quickRecordTask: DailyTask?
    var quickRecordWorkout: WorkoutRecord?
    
    private var modelContext: ModelContext
    private var taskSuggestionManager: TaskSuggestionManager
    private var progressAnalyzer: ProgressAnalyzer
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.taskSuggestionManager = TaskSuggestionManager(modelContext: modelContext)
        self.progressAnalyzer = ProgressAnalyzer(modelContext: modelContext)
        checkCompletedTasks()
    }
    
    private func checkCompletedTasks() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let recordDescriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { record in
                record.date >= today && record.date < tomorrow && record.isCompleted
            }
        )
        
        do {
            let todaysRecords = try modelContext.fetch(recordDescriptor)
            completedTasks = Set(todaysRecords.compactMap { $0.templateTask?.id })
        } catch {
            print("Error checking completed tasks: \(error)")
        }
    }
    
    func quickCompleteTask(_ task: DailyTask) -> WorkoutRecord? {
        let record = WorkoutRecord.fromDailyTask(task)
        record.markAsCompleted()
        modelContext.insert(record)
        
        switch task.workoutType {
        case .cycling:
            if let targetDetails = task.targetDetails {
                let detail = CyclingDetail(
                    distance: 0,
                    duration: targetDetails.duration ?? 0,
                    averagePower: Double(targetDetails.targetPower ?? 0),
                    intensity: targetDetails.intensity ?? .endurance
                )
                record.cyclingDetail = detail
                modelContext.insert(detail)
            }
        case .strength:
            record.strengthDetails = []
        case .flexibility:
            if let targetDetails = task.targetDetails {
                let detail = FlexibilityDetail(
                    forwardBendDistance: 0,
                    leftSplitAngle: 90,
                    rightSplitAngle: 90,
                    duration: targetDetails.targetDuration ?? 20
                )
                record.flexibilityDetail = detail
                modelContext.insert(detail)
            }
        }
        
        do {
            try modelContext.save()
            completedTasks.insert(task.id)
            checkForAchievements(record)
            return record
        } catch {
            print("Error saving quick completion: \(error)")
            return nil
        }
    }
    
    private func checkForAchievements(_ record: WorkoutRecord) {
        let recordDescriptor = FetchDescriptor<WorkoutRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allRecords = try modelContext.fetch(recordDescriptor)
            
            if let prAchievement = progressAnalyzer.detectPR(newRecord: record, history: allRecords) {
                modelContext.insert(prAchievement)
            }
            
            if let streakAchievement = Achievement.checkForStreak(records: allRecords, targetDays: 7) {
                modelContext.insert(streakAchievement)
            }
            
            let progress = progressAnalyzer.analyzeProgress(records: allRecords)
            if progress.currentStreak == 3 || progress.currentStreak == 5 {
                let message = progressAnalyzer.generateMotivationalMessage(progress: progress)
                print("Motivational: \(message)")
            }
            
            try modelContext.save()
        } catch {
            print("Error checking achievements: \(error)")
        }
    }
    
    func isTaskCompleted(_ task: DailyTask) -> Bool {
        return completedTasks.contains(task.id)
    }
    
    func isToday(_ day: Int) -> Bool {
        return Calendar.current.component(.weekday, from: Date()) - 1 == day
    }
    
    func refreshCompletedTasks() {
        checkCompletedTasks()
    }
}