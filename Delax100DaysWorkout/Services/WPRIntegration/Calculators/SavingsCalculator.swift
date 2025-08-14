import Foundation
import SwiftData
import OSLog

// MARK: - Savings Calculator

class SavingsCalculator {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - SST Calculations
    
    func isQualifiedSST(cyclingDetail: CyclingDetail, currentFTP: Int) -> Bool {
        guard cyclingDetail.duration >= 1200 else { return false }  // 20分以上
        guard currentFTP > 0 else { return false }
        
        // FTPの88-95%範囲をSST判定
        let lowerBound = Double(currentFTP) * 0.88
        let upperBound = Double(currentFTP) * 0.95
        
        return cyclingDetail.averagePower >= lowerBound && cyclingDetail.averagePower <= upperBound
    }
    
    func calculateSSTContributionToWPR(_ sstSavings: TrainingSavings) -> Double {
        let progressRatio = Double(sstSavings.currentCount) / Double(sstSavings.targetCount)
        let baseContribution = 0.25  // SST基本寄与度25%
        
        // ストリーク効果 (連続で更新している場合のボーナス)
        let streakBonus = min(Double(sstSavings.currentStreak) * 0.01, 0.10)  // 最大10%ボーナス
        
        return progressRatio * baseContribution + streakBonus
    }
    
    // MARK: - Volume Calculations
    
    func extractMuscleGroupSets(from strengthDetails: [StrengthDetail]) -> VolumeCount {
        var pushSets = 0
        var pullSets = 0
        var legsSets = 0
        
        for detail in strengthDetails {
            let exercise = detail.exercise.lowercased()
            
            if isPushExercise(exercise) {
                pushSets += detail.sets
            } else if isPullExercise(exercise) {
                pullSets += detail.sets
            } else if isLegsExercise(exercise) {
                legsSets += detail.sets
            }
        }
        
        return VolumeCount(push: pushSets, pull: pullSets, legs: legsSets)
    }
    
    func calculateStrengthContributionToWPR(_ volumeCount: VolumeCount) -> Double {
        let totalVolume = Double(volumeCount.total)
        let baseContribution = 0.20  // 筋力基本寄与度20%
        
        // バランス評価 (各筋群が均等に鍛えられているかどうか)
        let balanceScore = calculateMuscleGroupBalance(volumeCount)
        
        return (totalVolume / 100.0) * baseContribution * balanceScore  // 100セットで満点
    }
    
    // MARK: - Flexibility Calculations
    
    func calculateFlexibilityContributionToWPR(_ flexDetail: FlexibilityDetail) -> Double {
        var flexibilityScore = 0.0
        let baseContribution = 0.10  // 柔軟性基本寄与度10%
        
        // 前屈評価 (20cm以上で満点)
        flexibilityScore += min(Double(flexDetail.forwardBendDistance) / 20.0, 1.0) * 0.25
        
        // 開脚評価 (左右の平均、90度以上で満点)
        let avgSplitAngle = (Double(flexDetail.leftSplitAngle) + Double(flexDetail.rightSplitAngle)) / 2.0
        flexibilityScore += min(avgSplitAngle / 90.0, 1.0) * 0.25
        
        // 前後開脚評価 (前後の平均、90度以上で満点)
        let avgFrontBackSplit = (Double(flexDetail.frontSplitAngle) + Double(flexDetail.backSplitAngle)) / 2.0
        flexibilityScore += min(avgFrontBackSplit / 90.0, 1.0) * 0.25
        
        // 継続時間評価 (30分以上で満点)
        flexibilityScore += min(Double(flexDetail.duration) / 30.0, 1.0) * 0.25
        
        return flexibilityScore * baseContribution
    }
    
    // MARK: - Helper Methods
    
    private func isPushExercise(_ exercise: String) -> Bool {
        let pushKeywords = ["push", "press", "chest", "triceps", "shoulder", "dip"]
        return pushKeywords.contains { exercise.contains($0) }
    }
    
    private func isPullExercise(_ exercise: String) -> Bool {
        let pullKeywords = ["pull", "row", "lat", "chin", "biceps", "back"]
        return pullKeywords.contains { exercise.contains($0) }
    }
    
    private func isLegsExercise(_ exercise: String) -> Bool {
        let legsKeywords = ["squat", "lunge", "leg", "calf", "quad", "hamstring", "glute"]
        return legsKeywords.contains { exercise.contains($0) }
    }
    
    private func calculateMuscleGroupBalance(_ volumeCount: VolumeCount) -> Double {
        let groups = [volumeCount.push, volumeCount.pull, volumeCount.legs]
        let maxGroup = groups.max() ?? 1
        let minGroup = groups.min() ?? 0
        
        // バランススコア: 最小グループ/最大グループ
        return maxGroup > 0 ? Double(minGroup) / Double(maxGroup) : 0.0
    }
}