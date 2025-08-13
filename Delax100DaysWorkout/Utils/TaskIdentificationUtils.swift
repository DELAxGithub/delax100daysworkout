import Foundation

/// 種目識別ユーティリティ
/// WorkoutRecordやDailyTaskから統一識別子を生成
struct TaskIdentificationUtils {
    
    /// DailyTaskから種目識別子を生成
    static func generateTaskType(from task: DailyTask) -> String {
        switch task.workoutType {
        case .cycling:
            // サイクリングの場合、intensityを基準に分類
            if let targetDetails = task.targetDetails,
               let intensity = targetDetails.intensity {
                return "サイクリング-\(intensity.description)"
            }
            // タイトルから推測
            if let intensity = extractCyclingIntensityFromTitle(task.title) {
                return "サイクリング-\(intensity.description)"
            }
            return "サイクリング"
            
        case .strength:
            // 筋トレの場合、種目名を基準に分類
            if let targetDetails = task.targetDetails,
               let exercises = targetDetails.exercises,
               let firstExercise = exercises.first {
                return "筋トレ-\(firstExercise)"
            }
            // タイトルから推測
            if let exerciseName = extractStrengthExerciseFromTitle(task.title, task.taskDescription) {
                return "筋トレ-\(exerciseName)"
            }
            return "筋トレ"
            
        case .flexibility:
            return "柔軟性トレーニング"
            
        case .pilates:
            return "ピラティス"
            
        case .yoga:
            return "ヨガ"
        }
    }
    
    /// WorkoutRecordから種目識別子を生成
    static func generateTaskType(from record: WorkoutRecord) -> String {
        switch record.workoutType {
        case .cycling:
            if let cyclingDetail = record.cyclingDetail {
                return "サイクリング-\(cyclingDetail.intensity.description)"
            }
            return "サイクリング"
            
        case .strength:
            if let strengthDetails = record.strengthDetails,
               let firstExercise = strengthDetails.first {
                return "筋トレ-\(firstExercise.exercise)"
            }
            return "筋トレ"
            
        case .flexibility:
            return "柔軟性トレーニング"
            
        case .pilates:
            return "ピラティス"
            
        case .yoga:
            return "ヨガ"
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// タイトルからCyclingIntensityを抽出
    private static func extractCyclingIntensityFromTitle(_ title: String) -> CyclingIntensity? {
        let lowercased = title.lowercased()
        
        if lowercased.contains("sst") {
            return .sst
        } else if lowercased.contains("z2") || lowercased.contains("zone2") {
            return .z2
        } else if lowercased.contains("tempo") || lowercased.contains("テンポ") {
            return .tempo
        } else if lowercased.contains("vo2") {
            return .vo2max
        } else if lowercased.contains("sprint") || lowercased.contains("スプリント") {
            return .sprint
        } else if lowercased.contains("recovery") || lowercased.contains("リカバリー") {
            return .recovery
        } else if lowercased.contains("endurance") || lowercased.contains("エンデュランス") {
            return .endurance
        } else if lowercased.contains("anaerobic") || lowercased.contains("アナエロビック") {
            return .anaerobic
        }
        
        return nil
    }
    
    /// タイトルから筋トレ種目を抽出
    private static func extractStrengthExerciseFromTitle(_ title: String, _ description: String?) -> String? {
        let titleLower = title.lowercased()
        let descriptionLower = description?.lowercased() ?? ""
        let combined = "\(titleLower) \(descriptionLower)"
        
        // 各種目のキーワードマッチング
        if combined.contains("スクワット") || combined.contains("squat") {
            return "スクワット"
        } else if combined.contains("ベンチプレス") || combined.contains("bench") {
            return "ベンチプレス"
        } else if combined.contains("プルアップ") || combined.contains("pullup") || combined.contains("pull up") {
            return "プルアップ"
        } else if combined.contains("デッドリフト") || combined.contains("deadlift") {
            return "デッドリフト"
        } else if combined.contains("プッシュアップ") || combined.contains("pushup") || combined.contains("push up") {
            return "プッシュアップ"
        } else if combined.contains("ダンベル") || combined.contains("dumbbell") {
            if combined.contains("プレス") {
                return "ダンベルプレス"
            } else if combined.contains("カール") {
                return "ダンベルカール"
            }
            return "ダンベル"
        } else if combined.contains("プランク") || combined.contains("plank") {
            return "プランク"
        }
        
        return nil // 特定できない場合は種目名なし
    }
    
    /// 種目識別子の表示名を生成（よりユーザーフレンドリー）
    static func getDisplayName(for taskType: String) -> String {
        if taskType.hasPrefix("サイクリング-") {
            let intensity = String(taskType.dropFirst("サイクリング-".count))
            return intensity // "SST", "Zone2"など
        } else if taskType.hasPrefix("筋トレ-") {
            let exercise = String(taskType.dropFirst("筋トレ-".count))
            return exercise
        } else {
            return taskType
        }
    }
}

