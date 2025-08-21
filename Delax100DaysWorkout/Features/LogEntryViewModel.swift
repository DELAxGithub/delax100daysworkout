import Foundation
import SwiftData
import OSLog

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

@MainActor
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
    var cyclingIntensity: CyclingZone = .z2
    var cyclingNotes: String = ""
    
    // Strength details
    var strengthData: SimpleStrengthData = SimpleStrengthData(muscleGroup: .chest, weight: 0, reps: 0, sets: 0)
    
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
        // 初回起動時にDailyLogからDailyMetricへのマイグレーションを実行
        Task {
            await migrateDailyLogToMetric()
        }
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
        
        // まずDailyMetricから最新の体重データを取得
        var metricDescriptor = FetchDescriptor<DailyMetric>(
            sortBy: [SortDescriptor(\DailyMetric.date, order: .reverse)]
        )
        metricDescriptor.fetchLimit = 1
        
        if let lastMetric = try? modelContext.fetch(metricDescriptor).first,
           let weight = lastMetric.weightKg {
            weightKg = weight
            return
        }
        
        // DailyMetricにデータがない場合は、後方互換性のためDailyLogから取得
        var logDescriptor = FetchDescriptor<DailyLog>(
            sortBy: [SortDescriptor(\DailyLog.date, order: .reverse)]
        )
        logDescriptor.fetchLimit = 1
        if let lastLog = try? modelContext.fetch(logDescriptor).first {
            weightKg = lastLog.weightKg
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
            let detailsSig = "\(strengthData.muscleGroup.displayName),\(strengthData.sets),\(strengthData.reps),\(strengthData.weight)"
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

        var descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.workoutType.rawValue == "Cycling" },
            sortBy: [SortDescriptor(\WorkoutRecord.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let record = try? modelContext.fetch(descriptor).first,
           let detail = record.cyclingData {
            cyclingDistance = 0.0  // distance not available in SimpleCyclingData
            cyclingDuration = detail.duration
            cyclingAveragePower = Double(detail.power ?? 0)
            cyclingIntensity = mapZoneToIntensity(detail.zone)
            cyclingNotes = ""  // notes not available in SimpleCyclingData
            if workoutSummary.isEmpty { workoutSummary = record.summary }
        }
    }

    private func preloadLastStrength() {
        guard strengthData.weight == 0,
              workoutSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.workoutType.rawValue == "Strength" },
            sortBy: [SortDescriptor(\WorkoutRecord.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let record = try? modelContext.fetch(descriptor).first,
           let data = record.strengthData {
            // Use the existing strengthData property
            strengthData = data
            if workoutSummary.isEmpty { workoutSummary = record.summary }
        }
    }

    private func preloadLastFlexibility() {
        guard flexibilityDuration == 0,
              flexibilityForwardBend == 0,
              workoutSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.workoutType.rawValue == "Flexibility" },
            sortBy: [SortDescriptor(\WorkoutRecord.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let record = try? modelContext.fetch(descriptor).first,
           let data = record.flexibilityData {
            flexibilityForwardBend = data.measurement ?? 0.0
            flexibilityLeftSplit = 90.0  // default value
            flexibilityRightSplit = 90.0  // default value
            flexibilityDuration = data.duration
            flexibilityNotes = ""  // notes not available in simple data
            if workoutSummary.isEmpty { workoutSummary = record.summary }
        }
    }

    @MainActor
    func save() async {
        guard !isSaveDisabled else { 
            Logger.debug.debug("保存無効: 必要な入力が不足しています")
            return 
        }
        
        Logger.database.info("保存開始: \(self.logType.rawValue)")
        saveState = .saving
        
        // UI更新を確実にするため少し待機
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        do {
            switch logType {
            case .weight:
                // 体重を小数点1桁に丸める
                let roundedWeight = round(self.weightKg * 10) / 10
                
                // 同じ日付の既存DailyMetricがあるかチェック
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                let predicate = DailyMetric.sameDayPredicate(for: startOfDay)
                let descriptor = FetchDescriptor<DailyMetric>(predicate: predicate)
                
                do {
                    let existingMetrics = try modelContext.fetch(descriptor)
                    if let existingMetric = existingMetrics.first {
                        // 既存のDailyMetricを更新
                        Logger.database.info("既存DailyMetricを更新: \(String(format: "%.1f", roundedWeight))kg")
                        existingMetric.weightKg = roundedWeight
                        existingMetric.dataSource = .manual
                        existingMetric.updatedAt = Date()
                    } else {
                        // 新しいDailyMetricを作成
                        Logger.database.info("新規DailyMetricを作成: \(String(format: "%.1f", roundedWeight))kg")
                        let newMetric = DailyMetric(
                            date: startOfDay,
                            weightKg: roundedWeight,
                            dataSource: .manual
                        )
                        modelContext.insert(newMetric)
                    }
                } catch {
                    Logger.error.error("DailyMetric検索エラー: \(error.localizedDescription)")
                    // エラーが発生した場合も新規作成で続行
                    Logger.database.info("エラー回復: 新規DailyMetricを作成")
                    let newMetric = DailyMetric(
                        date: startOfDay,
                        weightKg: roundedWeight,
                        dataSource: .manual
                    )
                    modelContext.insert(newMetric)
                }
                
                // 後方互換性のためDailyLogも作成（将来的に削除予定）
                let newLog = DailyLog(date: date, weightKg: roundedWeight)
                modelContext.insert(newLog)
                Logger.database.info("DailyLogも作成: \(String(format: "%.1f", roundedWeight))kg")
                
            case .cycling:
                let newRecord = WorkoutRecord(date: date, workoutType: .cycling, summary: workoutSummary)
                newRecord.cyclingData = SimpleCyclingData(
                    zone: .z2,  // default zone
                    duration: cyclingDuration,
                    power: Int(cyclingAveragePower)
                )
                newRecord.markAsCompleted()
                modelContext.insert(newRecord)
                
                // TODO: Implement WPR update trigger
                // newRecord.triggerWPRUpdate(context: modelContext)
                
            case .strength:
                let newRecord = WorkoutRecord(date: date, workoutType: .strength, summary: workoutSummary)
                newRecord.strengthData = strengthData
                newRecord.markAsCompleted()
                modelContext.insert(newRecord)
                
                // TODO: Implement WPR update trigger
                // newRecord.triggerWPRUpdate(context: modelContext)
                
            case .flexibility:
                let newRecord = WorkoutRecord(date: date, workoutType: .flexibility, summary: workoutSummary)
                newRecord.flexibilityData = SimpleFlexibilityData(
                    type: .general,  // default type
                    duration: flexibilityDuration,
                    measurement: flexibilityForwardBend > 0 ? flexibilityForwardBend : nil
                )
                newRecord.markAsCompleted()
                modelContext.insert(newRecord)
                
                // TODO: Implement WPR update trigger
                // newRecord.triggerWPRUpdate(context: modelContext)
            }
            
            // 永続化を実行
            try modelContext.save()
            Logger.database.info("✅ データベース保存成功: \(self.logType.rawValue)")
            
            // 保存後にベースラインを更新（hasChangesをリセット）
            captureBaseline()
            Logger.database.info("📏 ベースライン更新完了")
            
            saveState = .success
            
        } catch {
            Logger.error.error("保存エラー: \(error.localizedDescription)")
            saveState = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Data Migration
    
    /// DailyLogからDailyMetricへの一回限りマイグレーション
    @MainActor
    private func migrateDailyLogToMetric() async {
        // マイグレーション済みフラグをチェック
        let migrationKey = "DailyLogToMetricMigrationCompleted"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }
        
        do {
            // すべてのDailyLogを取得
            let logDescriptor = FetchDescriptor<DailyLog>(
                sortBy: [SortDescriptor(\DailyLog.date, order: .reverse)]
            )
            let dailyLogs = try modelContext.fetch(logDescriptor)
            
            Logger.database.info("DailyLog→DailyMetricマイグレーション開始: \(dailyLogs.count)件")
            
            var migratedCount = 0
            
            for log in dailyLogs {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: log.date)
                
                // 同じ日付のDailyMetricがすでに存在するかチェック
                let predicate = DailyMetric.sameDayPredicate(for: startOfDay)
                let descriptor = FetchDescriptor<DailyMetric>(predicate: predicate)
                
                if let existingMetric = try? modelContext.fetch(descriptor).first {
                    // 既存のDailyMetricがあるが体重データがない場合のみ更新
                    if existingMetric.weightKg == nil {
                        existingMetric.weightKg = log.weightKg
                        existingMetric.dataSource = .manual
                        existingMetric.updatedAt = Date()
                        migratedCount += 1
                    }
                } else {
                    // 新しいDailyMetricを作成
                    let newMetric = DailyMetric(
                        date: startOfDay,
                        weightKg: log.weightKg,
                        dataSource: .manual
                    )
                    modelContext.insert(newMetric)
                    migratedCount += 1
                }
            }
            
            // 永続化
            try modelContext.save()
            
            // マイグレーション完了フラグを設定
            UserDefaults.standard.set(true, forKey: migrationKey)
            
            Logger.database.info("DailyLog→DailyMetricマイグレーション完了: \(migratedCount)件を移行")
            
        } catch {
            Logger.error.error("マイグレーションエラー: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapZoneToIntensity(_ zone: CyclingZone) -> CyclingZone {
        switch zone {
        case .z2: return .z2
        case .sst: return .sst
        case .vo2: return .vo2
        case .recovery: return .recovery
        }
    }
}
