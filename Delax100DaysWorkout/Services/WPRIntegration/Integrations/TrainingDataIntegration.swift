import Foundation
import SwiftData
import OSLog

// MARK: - Training Data Integration Service

class TrainingDataIntegration {
    private let modelContext: ModelContext
    private let savingsCalculator: SavingsCalculator
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.savingsCalculator = SavingsCalculator(modelContext: modelContext)
    }
    
    // MARK: - Workout Integration
    
    func updateLegacySavings(from workout: WorkoutRecord, legacySavings: [TrainingSavings]) async {
        // 既存のTrainingSavingsロジックを統合
        switch workout.workoutType {
        case .cycling:
            await updateSSTSavings(from: workout, legacySavings: legacySavings)
        case .strength:
            await updateVolumeSavings(from: workout, legacySavings: legacySavings)
        case .flexibility:
            await updateFlexibilityStreaks(from: workout, legacySavings: legacySavings)
        case .pilates:
            // ピラティス節約は後で実装
            break
        case .yoga:
            // ヨガ節約は後で実装
            break
        }
    }
    
    // MARK: - SST Integration
    
    private func updateSSTSavings(
        from workout: WorkoutRecord,
        legacySavings: [TrainingSavings]
    ) async {
        guard let cyclingDetail = workout.cyclingDetail,
              let currentFTP = getCurrentFTPFromHistory() else { return }
        
        let isSST = savingsCalculator.isQualifiedSST(
            cyclingDetail: cyclingDetail,
            currentFTP: currentFTP
        )
        
        if isSST, let sstSavings = getSavings(for: .sstCounter, from: legacySavings) {
            sstSavings.currentCount += 1
            sstSavings.lastUpdated = Date()
            checkLegacyMilestones(sstSavings)
        }
    }
    
    // MARK: - Volume Integration
    
    private func updateVolumeSavings(
        from workout: WorkoutRecord,
        legacySavings: [TrainingSavings]
    ) async {
        guard let strengthDetails = workout.strengthDetails else { return }
        
        let volumeCount = savingsCalculator.extractMuscleGroupSets(from: strengthDetails)
        
        // 各筋群の更新
        updateMuscleGroupSavings(.pushVolume, sets: volumeCount.push, legacySavings: legacySavings)
        updateMuscleGroupSavings(.pullVolume, sets: volumeCount.pull, legacySavings: legacySavings)
        updateMuscleGroupSavings(.legsVolume, sets: volumeCount.legs, legacySavings: legacySavings)
    }
    
    // MARK: - Flexibility Integration
    
    private func updateFlexibilityStreaks(
        from workout: WorkoutRecord,
        legacySavings: [TrainingSavings]
    ) async {
        guard let flexDetail = workout.flexibilityDetail else { return }
        
        let today = Date()
        
        // 各柔軟性ストリークの更新
        if (flexDetail.forwardSplitLeft ?? 0) > 0 || (flexDetail.forwardSplitRight ?? 0) > 0 {
            updateFlexibilityStreak(.forwardSplitStreak, date: today, legacySavings: legacySavings)
        }
        
        if (flexDetail.sideSplitAngle ?? 0) > 0 {
            updateFlexibilityStreak(.sideSplitStreak, date: today, legacySavings: legacySavings)
        }
        
        if flexDetail.forwardBendDistance > 0 {
            updateFlexibilityStreak(.forwardBendStreak, date: today, legacySavings: legacySavings)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getSavings(for type: SavingsType, from legacySavings: [TrainingSavings]) -> TrainingSavings? {
        return legacySavings.first { $0.savingsType == type }
    }
    
    private func updateMuscleGroupSavings(
        _ type: SavingsType,
        sets: Int,
        legacySavings: [TrainingSavings]
    ) {
        if let savings = getSavings(for: type, from: legacySavings) {
            savings.currentCount += sets
            savings.lastUpdated = Date()
            checkLegacyMilestones(savings)
        }
    }
    
    private func updateFlexibilityStreak(
        _ type: SavingsType,
        date: Date,
        legacySavings: [TrainingSavings]
    ) {
        if let savings = getSavings(for: type, from: legacySavings) {
            updateStreakLogic(savings, date: date)
        }
    }
    
    private func updateStreakLogic(_ savings: TrainingSavings, date: Date) {
        let calendar = Calendar.current
        
        let lastUpdate = savings.lastUpdated
        if calendar.isDate(lastUpdate, inSameDayAs: date) {
            // 同日内の重複更新は無視
            return
        } else if calendar.isDate(lastUpdate, equalTo: date, toGranularity: .day) ||
                  calendar.dateInterval(of: .day, for: lastUpdate)?.end == calendar.dateInterval(of: .day, for: date)?.start {
                // 連続日
                savings.currentStreak += 1
            } else {
                // ストリーク中断
                savings.currentStreak = 1
            }
        } else {
            // ストリーク中断
            savings.currentStreak = 1
        }
        
        savings.currentCount += 1
        savings.lastUpdated = date
        checkLegacyMilestones(savings)
    }
    
    private func checkLegacyMilestones(_ savings: TrainingSavings) {
        // マイルストーンチェックロジック
        let milestones = [10, 25, 50, 100, 200, 500]
        
        for milestone in milestones {
            if savings.currentCount == milestone {
                Logger.system.info("マイルストーン達成: \(savings.savingsType.displayName) \(milestone)回")
                // 実際のマイルストーン処理はここに追加
                break
            }
        }
    }
    
    private func getCurrentFTPFromHistory() -> Int? {
        let descriptor = FetchDescriptor<FTPHistory>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let ftpHistory = try modelContext.fetch(descriptor)
            return ftpHistory.first?.ftpValue
        } catch {
            return nil
        }
    }
}