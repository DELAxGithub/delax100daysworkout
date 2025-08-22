import Foundation

/// 柔軟性トレーニングの種類別プリセット値管理クラス
class FlexibilityPresetManager {
    static let shared = FlexibilityPresetManager()
    private init() {}
    
    // MARK: - Default Values
    
    /// 種類別のデフォルト時間値（分）
    private let defaultDurations: [FlexibilityType: Int] = [
        .forwardBend: 20,     // 前屈
        .split: 25,           // 開脚
        .pilates: 30,         // ピラティス
        .yoga: 45,            // ヨガ
        .general: 15          // 一般柔軟
    ]
    
    /// 種類別のデフォルト測定値（cm）
    private let defaultMeasurements: [FlexibilityType: Double] = [
        .forwardBend: 0.0,    // 前屈（マイナス値も可能）
        .split: 120.0,        // 開脚（角度）
        .pilates: 0.0,        // ピラティス（測定なし）
        .yoga: 0.0,           // ヨガ（測定なし）
        .general: 0.0         // 一般柔軟（測定なし）
    ]
    
    // MARK: - Preset Management
    
    /// 種類の時間前回値を取得
    func getDurationPreset(for type: FlexibilityType) -> Int {
        let key = "flexibility_preset_\(type.rawValue)_duration"
        let savedValue = UserDefaults.standard.integer(forKey: key)
        return savedValue > 0 ? savedValue : defaultDurations[type] ?? 20
    }
    
    /// 種類の測定値前回値を取得
    func getMeasurementPreset(for type: FlexibilityType) -> Double {
        let key = "flexibility_preset_\(type.rawValue)_measurement"
        let savedValue = UserDefaults.standard.double(forKey: key)
        // 測定値は0以下も有効（前屈のマイナス値など）なので、保存値があれば使用
        if UserDefaults.standard.object(forKey: key) != nil {
            return savedValue
        }
        return defaultMeasurements[type] ?? 0.0
    }
    
    /// 時間値を保存
    func saveDurationPreset(_ duration: Int, for type: FlexibilityType) {
        guard duration > 0 else { return }
        let key = "flexibility_preset_\(type.rawValue)_duration"
        UserDefaults.standard.set(duration, forKey: key)
    }
    
    /// 測定値を保存
    func saveMeasurementPreset(_ measurement: Double, for type: FlexibilityType) {
        // 測定値は0以下も有効（前屈のマイナス値など）
        let key = "flexibility_preset_\(type.rawValue)_measurement"
        UserDefaults.standard.set(measurement, forKey: key)
    }
    
    /// プリセット値を一括保存
    func savePresets(type: FlexibilityType, duration: Int, measurement: Double?) {
        saveDurationPreset(duration, for: type)
        if let measurement = measurement {
            saveMeasurementPreset(measurement, for: type)
        }
    }
    
    // MARK: - Formatted Display
    
    /// 前回値の表示用文字列を生成
    func getPresetDisplayString(for type: FlexibilityType) -> String {
        let duration = getDurationPreset(for: type)
        
        if type.hasMeasurement {
            let measurement = getMeasurementPreset(for: type)
            if type == .forwardBend {
                // 前屈は cm で表示
                return "前回: \(duration)分・\(Int(measurement))cm"
            } else {
                // 開脚は度で表示
                return "前回: \(duration)分・\(Int(measurement))°"
            }
        } else {
            // 測定なしの場合は時間のみ
            return "前回: \(duration)分"
        }
    }
    
    // MARK: - Picker Range Generation
    
    /// 時間用のピッカー範囲を生成（5-120分）
    func getDurationPickerRange() -> [Int] {
        return Array(5...120)
    }
    
    /// 前屈測定値用のピッカー範囲を生成（-30 to +30cm）
    func getForwardBendPickerRange() -> [Int] {
        return Array(-30...30)
    }
    
    /// 開脚測定値用のピッカー範囲を生成（60-180度）
    func getSplitAnglePickerRange() -> [Int] {
        return Array(60...180)
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// プリセット値をリセット（デバッグ用）
    func resetAllPresets() {
        for type in FlexibilityType.allCases {
            UserDefaults.standard.removeObject(forKey: "flexibility_preset_\(type.rawValue)_duration")
            UserDefaults.standard.removeObject(forKey: "flexibility_preset_\(type.rawValue)_measurement")
        }
    }
    
    /// 現在のプリセット値を出力（デバッグ用）
    func printCurrentPresets() {
        for type in FlexibilityType.allCases {
            let duration = getDurationPreset(for: type)
            let measurement = getMeasurementPreset(for: type)
            print("FlexibilityType \(type.rawValue): Duration=\(duration)min, Measurement=\(measurement)")
        }
    }
    #endif
}