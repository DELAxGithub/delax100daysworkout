import Foundation

/// 筋トレの部位別プリセット値管理クラス
class StrengthPresetManager {
    static let shared = StrengthPresetManager()
    private init() {}
    
    // MARK: - Default Values
    
    /// 部位別のデフォルト重量値
    private let defaultWeights: [WorkoutMuscleGroup: Double] = [
        .chest: 20.0,     // 胸
        .back: 15.0,      // 背中
        .legs: 25.0,      // 足
        .shoulders: 10.0, // 肩
        .arms: 10.0,      // 腕
        .core: 0.0,       // 腹筋（自重）
        .custom: 15.0     // その他
    ]
    
    /// 部位別のデフォルトセット数
    private let defaultSets: [WorkoutMuscleGroup: Int] = [
        .chest: 3,
        .back: 3,
        .legs: 3,
        .shoulders: 3,
        .arms: 3,
        .core: 3,
        .custom: 3
    ]
    
    /// 部位別のデフォルトレップ数
    private let defaultReps: [WorkoutMuscleGroup: Int] = [
        .chest: 10,
        .back: 10,
        .legs: 12,
        .shoulders: 12,
        .arms: 10,
        .core: 15,
        .custom: 10
    ]
    
    // MARK: - Preset Management
    
    /// 部位の重量前回値を取得
    func getWeightPreset(for muscleGroup: WorkoutMuscleGroup) -> Double {
        let key = "strength_preset_\(muscleGroup.rawValue)_weight"
        let savedValue = UserDefaults.standard.double(forKey: key)
        return savedValue > 0 ? savedValue : defaultWeights[muscleGroup] ?? 15.0
    }
    
    /// 部位のセット数前回値を取得
    func getSetsPreset(for muscleGroup: WorkoutMuscleGroup) -> Int {
        let key = "strength_preset_\(muscleGroup.rawValue)_sets"
        let savedValue = UserDefaults.standard.integer(forKey: key)
        return savedValue > 0 ? savedValue : defaultSets[muscleGroup] ?? 3
    }
    
    /// 部位のレップ数前回値を取得
    func getRepsPreset(for muscleGroup: WorkoutMuscleGroup) -> Int {
        let key = "strength_preset_\(muscleGroup.rawValue)_reps"
        let savedValue = UserDefaults.standard.integer(forKey: key)
        return savedValue > 0 ? savedValue : defaultReps[muscleGroup] ?? 10
    }
    
    /// 重量値を保存
    func saveWeightPreset(_ weight: Double, for muscleGroup: WorkoutMuscleGroup) {
        guard weight > 0 else { return }
        let key = "strength_preset_\(muscleGroup.rawValue)_weight"
        UserDefaults.standard.set(weight, forKey: key)
    }
    
    /// セット数を保存
    func setSetsPreset(_ sets: Int, for muscleGroup: WorkoutMuscleGroup) {
        guard sets > 0 else { return }
        let key = "strength_preset_\(muscleGroup.rawValue)_sets"
        UserDefaults.standard.set(sets, forKey: key)
    }
    
    /// レップ数を保存
    func setRepsPreset(_ reps: Int, for muscleGroup: WorkoutMuscleGroup) {
        guard reps > 0 else { return }
        let key = "strength_preset_\(muscleGroup.rawValue)_reps"
        UserDefaults.standard.set(reps, forKey: key)
    }
    
    /// プリセット値を一括保存
    func savePresets(muscleGroup: WorkoutMuscleGroup, weight: Double, sets: Int, reps: Int) {
        saveWeightPreset(weight, for: muscleGroup)
        setSetsPreset(sets, for: muscleGroup)
        setRepsPreset(reps, for: muscleGroup)
    }
    
    // MARK: - Formatted Display
    
    /// 前回値の表示用文字列を生成
    func getPresetDisplayString(for muscleGroup: WorkoutMuscleGroup) -> String {
        let weight = getWeightPreset(for: muscleGroup)
        let sets = getSetsPreset(for: muscleGroup)
        let reps = getRepsPreset(for: muscleGroup)
        
        if weight == 0 {
            // 自重の場合
            return "前回: \(reps)×\(sets)"
        } else {
            return "前回: \(Int(weight))kg・\(reps)×\(sets)"
        }
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// プリセット値をリセット（デバッグ用）
    func resetAllPresets() {
        for muscleGroup in WorkoutMuscleGroup.allCases {
            UserDefaults.standard.removeObject(forKey: "strength_preset_\(muscleGroup.rawValue)_weight")
            UserDefaults.standard.removeObject(forKey: "strength_preset_\(muscleGroup.rawValue)_sets")
            UserDefaults.standard.removeObject(forKey: "strength_preset_\(muscleGroup.rawValue)_reps")
        }
    }
    
    /// 現在のプリセット値を出力（デバッグ用）
    func printCurrentPresets() {
        for muscleGroup in WorkoutMuscleGroup.allCases {
            let weight = getWeightPreset(for: muscleGroup)
            let sets = getSetsPreset(for: muscleGroup)
            let reps = getRepsPreset(for: muscleGroup)
            print("MuscleGroup \(muscleGroup.rawValue): Weight=\(weight)kg, Sets=\(sets), Reps=\(reps)")
        }
    }
    #endif
}