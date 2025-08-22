import Foundation

/// サイクリングのゾーン別プリセット値管理クラス
class CyclingPresetManager {
    static let shared = CyclingPresetManager()
    private init() {}
    
    // MARK: - Default Values
    
    /// ゾーン別のデフォルトパワー値
    private let defaultPowers: [CyclingZone: Int] = [
        .z2: 170,
        .sst: 230,
        .vo2: 280,
        .recovery: 120
    ]
    
    /// ゾーン別のデフォルト心拍数値
    private let defaultHeartRates: [CyclingZone: Int] = [
        .z2: 140,
        .sst: 155,
        .vo2: 175,
        .recovery: 120
    ]
    
    // MARK: - Preset Management
    
    /// ゾーンのパワー前回値を取得
    func getPowerPreset(for zone: CyclingZone) -> Int {
        let key = "cycling_preset_\(zone.rawValue)_power"
        let savedValue = UserDefaults.standard.integer(forKey: key)
        return savedValue > 0 ? savedValue : defaultPowers[zone] ?? 170
    }
    
    /// ゾーンの心拍数前回値を取得
    func getHeartRatePreset(for zone: CyclingZone) -> Int {
        let key = "cycling_preset_\(zone.rawValue)_heartRate"
        let savedValue = UserDefaults.standard.integer(forKey: key)
        return savedValue > 0 ? savedValue : defaultHeartRates[zone] ?? 140
    }
    
    /// パワー値を保存
    func savePowerPreset(_ power: Int, for zone: CyclingZone) {
        guard power > 0 else { return }
        let key = "cycling_preset_\(zone.rawValue)_power"
        UserDefaults.standard.set(power, forKey: key)
    }
    
    /// 心拍数値を保存
    func saveHeartRatePreset(_ heartRate: Int, for zone: CyclingZone) {
        guard heartRate > 0 else { return }
        let key = "cycling_preset_\(zone.rawValue)_heartRate"
        UserDefaults.standard.set(heartRate, forKey: key)
    }
    
    /// プリセット値を一括保存
    func savePresets(zone: CyclingZone, power: Int?, heartRate: Int?) {
        if let power = power {
            savePowerPreset(power, for: zone)
        }
        if let heartRate = heartRate {
            saveHeartRatePreset(heartRate, for: zone)
        }
    }
    
    // MARK: - Picker Range Generation
    
    /// パワー用のピッカー範囲を生成（0-300W全範囲）
    func getPowerPickerRange(for zone: CyclingZone) -> [Int] {
        return Array(0...300)
    }
    
    /// 心拍数用のピッカー範囲を生成（100-200bpm全範囲）
    func getHeartRatePickerRange(for zone: CyclingZone) -> [Int] {
        return Array(100...200)
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// プリセット値をリセット（デバッグ用）
    func resetAllPresets() {
        for zone in CyclingZone.allCases {
            UserDefaults.standard.removeObject(forKey: "cycling_preset_\(zone.rawValue)_power")
            UserDefaults.standard.removeObject(forKey: "cycling_preset_\(zone.rawValue)_heartRate")
        }
    }
    
    /// 現在のプリセット値を出力（デバッグ用）
    func printCurrentPresets() {
        for zone in CyclingZone.allCases {
            let power = getPowerPreset(for: zone)
            let heartRate = getHeartRatePreset(for: zone)
            print("Zone \(zone.rawValue): Power=\(power)W, HR=\(heartRate)bpm")
        }
    }
    #endif
}