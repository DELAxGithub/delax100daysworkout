import Foundation
import SwiftData

// This enum will drive the picker in the LogEntryView
enum LogType: String, CaseIterable, Identifiable {
    case weight = "Weight"
    case cycling = "Cycling"
    case strength = "Strength"
    case flexibility = "Flexibility"

    var id: String { self.rawValue }
}

@Observable
class LogEntryViewModel {
    var logType: LogType = .weight
    var date: Date = Date()

    // Properties for DailyLog (Weight)
    var weightKg: Double = 0.0

    // Properties for WorkoutRecord
    var workoutSummary: String = ""
    
    // Cycling details
    var cyclingDistance: Double = 0.0
    var cyclingDuration: Int = 0
    var cyclingAveragePower: Double = 0.0
    var cyclingIntensity: CyclingIntensity = .endurance
    var cyclingNotes: String = ""
    
    // Strength details
    var strengthDetails: [StrengthDetail] = []
    
    // Flexibility details
    var flexibilityForwardBend: Double = 0.0
    var flexibilityLeftSplit: Double = 90.0
    var flexibilityRightSplit: Double = 90.0
    var flexibilityDuration: Int = 0
    var flexibilityNotes: String = ""

    var isSaveDisabled: Bool {
        switch logType {
        case .weight:
            // Disable save if weight is 0 or less
            return weightKg <= 0
        case .cycling, .strength, .flexibility:
            // Disable save if summary is empty or just whitespace
            return workoutSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save() {
        guard !isSaveDisabled else { return }

        switch logType {
        case .weight:
            let newLog = DailyLog(date: date, weightKg: weightKg)
            modelContext.insert(newLog)
        case .cycling:
            let newRecord = WorkoutRecord(date: date, workoutType: .cycling, summary: workoutSummary)
            let cyclingDetail = CyclingDetail(
                distance: cyclingDistance,
                duration: cyclingDuration,
                averagePower: cyclingAveragePower,
                intensity: cyclingIntensity,
                notes: cyclingNotes.isEmpty ? nil : cyclingNotes
            )
            newRecord.cyclingDetail = cyclingDetail
            newRecord.markAsCompleted()
            modelContext.insert(newRecord)
            modelContext.insert(cyclingDetail)
        case .strength:
            let newRecord = WorkoutRecord(date: date, workoutType: .strength, summary: workoutSummary)
            newRecord.strengthDetails = strengthDetails
            newRecord.markAsCompleted()
            modelContext.insert(newRecord)
            for detail in strengthDetails {
                modelContext.insert(detail)
            }
        case .flexibility:
            let newRecord = WorkoutRecord(date: date, workoutType: .flexibility, summary: workoutSummary)
            let flexibilityDetail = FlexibilityDetail(
                forwardBendDistance: flexibilityForwardBend,
                leftSplitAngle: flexibilityLeftSplit,
                rightSplitAngle: flexibilityRightSplit,
                duration: flexibilityDuration,
                notes: flexibilityNotes.isEmpty ? nil : flexibilityNotes
            )
            newRecord.flexibilityDetail = flexibilityDetail
            newRecord.markAsCompleted()
            modelContext.insert(newRecord)
            modelContext.insert(flexibilityDetail)
        }
    }
}