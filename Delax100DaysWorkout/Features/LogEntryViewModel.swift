import Foundation
import SwiftData

enum SaveState: Equatable {
    case idle
    case saving
    case success
    case error(String)
    
    static func == (lhs: SaveState, rhs: SaveState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.saving, .saving), (.success, .success):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

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
    var saveState: SaveState = .idle

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
    
    private let errorHandler = ErrorHandler.shared

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
    
    var hasChanges: Bool {
        switch logType {
        case .weight:
            return weightKg > 0
        case .cycling, .strength, .flexibility:
            return !workoutSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    var isSaving: Bool {
        if case .saving = saveState {
            return true
        }
        return false
    }

    private var modelContext: ModelContext
    private var baselineSignature: String? = nil

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Smart Defaults
    /// Prefill fields using the most recent entry of the selected type.
    /// Called on appear; only fills when current fields are empty/zero.
    func preloadFromLastEntries() {
        switch logType {
        case .weight:
            preloadLastWeight()
        case .cycling:
            preloadLastCycling()
        case .strength:
            preloadLastStrength()
        case .flexibility:
            preloadLastFlexibility()
        }
    }

    /// Capture current values as the baseline so prefilled data isn't treated as edits.
    func captureBaseline() {
        baselineSignature = computeSignature()
    }

    private func preloadLastWeight() {
        guard weightKg <= 0 else { return }
        let descriptor = FetchDescriptor<DailyLog>(
            sortBy: [SortDescriptor(\DailyLog.date, order: .reverse)],
            fetchLimit: 1
        )
        if let last = try? modelContext.fetch(descriptor).first {
            weightKg = last.weightKg
        }
    }

    // MARK: - Change Tracking
    private func computeSignature() -> String {
        switch logType {
        case .weight:
            return "type:weight;date:\(date.timeIntervalSince1970);kg:\(weightKg)"
        case .cycling:
            return [
                "type:cycling",
                "date:\(date.timeIntervalSince1970)",
                "sum:\(workoutSummary)",
                "dist:\(cyclingDistance)",
                "dur:\(cyclingDuration)",
                "avgP:\(cyclingAveragePower)",
                "int:\(cyclingIntensity.rawValue)",
                "notes:\(cyclingNotes)"
            ].joined(separator: ";")
        case .strength:
            let detailsSig = strengthDetails.map { d in
                [d.exercise, String(d.sets), String(d.reps), String(d.weight), d.notes ?? "", d.pullUpVariant?.rawValue ?? "", String(d.isAssisted), String(d.assistWeight), String(d.maxConsecutiveReps)].joined(separator: ",")
            }.joined(separator: "|")
            return ["type:strength", "date:\(date.timeIntervalSince1970)", "sum:\(workoutSummary)", "items:\(detailsSig)"]
                .joined(separator: ";")
        case .flexibility:
            return [
                "type:flex",
                "date:\(date.timeIntervalSince1970)",
                "sum:\(workoutSummary)",
                "fb:\(flexibilityForwardBend)",
                "ls:\(flexibilityLeftSplit)",
                "rs:\(flexibilityRightSplit)",
                "dur:\(flexibilityDuration)",
                "notes:\(flexibilityNotes)"
            ].joined(separator: ";")
        }
    }

    var hasChanges: Bool {
        if let baseline = baselineSignature {
            return computeSignature() != baseline
        }
        // Fallback (no baseline captured yet)
        switch logType {
        case .weight:
            return weightKg > 0
        case .cycling, .strength, .flexibility:
            return !workoutSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func preloadLastCycling() {
        guard cyclingDistance == 0,
              cyclingDuration == 0,
              cyclingAveragePower == 0,
              workoutSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.workoutType == .cycling },
            sortBy: [SortDescriptor(\WorkoutRecord.date, order: .reverse)],
            fetchLimit: 1
        )
        if let record = try? modelContext.fetch(descriptor).first,
           let detail = record.cyclingDetail {
            cyclingDistance = detail.distance
            cyclingDuration = detail.duration
            cyclingAveragePower = detail.averagePower
            cyclingIntensity = detail.intensity
            cyclingNotes = detail.notes ?? ""
            if workoutSummary.isEmpty { workoutSummary = record.summary }
        }
    }

    private func preloadLastStrength() {
        guard strengthDetails.isEmpty,
              workoutSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.workoutType == .strength },
            sortBy: [SortDescriptor(\WorkoutRecord.date, order: .reverse)],
            fetchLimit: 1
        )
        if let record = try? modelContext.fetch(descriptor).first,
           let details = record.strengthDetails {
            // Create fresh copies so we don't reuse persisted objects
            strengthDetails = details.map { d in
                let copy = StrengthDetail(
                    exercise: d.exercise,
                    sets: d.sets,
                    reps: d.reps,
                    weight: d.weight,
                    notes: d.notes
                )
                copy.isPersonalRecord = d.isPersonalRecord
                copy.pullUpVariant = d.pullUpVariant
                copy.isAssisted = d.isAssisted
                copy.assistWeight = d.assistWeight
                copy.maxConsecutiveReps = d.maxConsecutiveReps
                return copy
            }
            if workoutSummary.isEmpty { workoutSummary = record.summary }
        }
    }

    private func preloadLastFlexibility() {
        guard flexibilityDuration == 0,
              flexibilityForwardBend == 0,
              workoutSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.workoutType == .flexibility },
            sortBy: [SortDescriptor(\WorkoutRecord.date, order: .reverse)],
            fetchLimit: 1
        )
        if let record = try? modelContext.fetch(descriptor).first,
           let detail = record.flexibilityDetail {
            flexibilityForwardBend = detail.forwardBendDistance
            flexibilityLeftSplit = detail.leftSplitAngle
            flexibilityRightSplit = detail.rightSplitAngle
            flexibilityDuration = detail.duration
            flexibilityNotes = detail.notes ?? ""
            if workoutSummary.isEmpty { workoutSummary = record.summary }
        }
    }

    @MainActor
    func save() async {
        guard !isSaveDisabled else { 
            print("❌ 保存無効: 必要な入力が不足しています")
            return 
        }
        
        print("🔄 保存開始...")
        saveState = .saving
        
        // UI更新を確実にするため少し待機
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        do {
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
                
                // WPR自動更新をトリガー
                newRecord.triggerWPRUpdate(context: modelContext)
                
            case .strength:
                let newRecord = WorkoutRecord(date: date, workoutType: .strength, summary: workoutSummary)
                newRecord.strengthDetails = strengthDetails
                newRecord.markAsCompleted()
                modelContext.insert(newRecord)
                for detail in strengthDetails {
                    modelContext.insert(detail)
                }
                
                // WPR自動更新をトリガー
                newRecord.triggerWPRUpdate(context: modelContext)
                
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
                
                // WPR自動更新をトリガー
                newRecord.triggerWPRUpdate(context: modelContext)
            }
            
            // 永続化を実行
            try modelContext.save()
            print("✅ 保存成功!")
            saveState = .success
            
        } catch {
            let appError = AppError.failedToSave(error)
            errorHandler.handle(
                appError,
                context: "ワークアウトデータの保存中"
            )
            saveState = .error(appError.localizedDescription)
        }
    }
}
