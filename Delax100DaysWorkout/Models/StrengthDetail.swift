import Foundation
import SwiftData

@Model
final class StrengthDetail {
    var exercise: String
    var sets: Int
    var reps: Int
    var weight: Double
    var notes: String?
    var isPersonalRecord: Bool = false
    
    // プルアップ専用フィールド（文字列として保存）
    var pullUpVariantRawValue: String?
    var isAssisted: Bool = false
    var assistWeight: Double = 0.0  // アシスト使用時の補助重量
    var maxConsecutiveReps: Int = 0  // 連続最大回数
    
    // 計算プロパティでenumとして使用
    var pullUpVariant: PullUpVariant? {
        get {
            guard let rawValue = pullUpVariantRawValue else { return nil }
            return PullUpVariant(rawValue: rawValue)
        }
        set {
            pullUpVariantRawValue = newValue?.rawValue
        }
    }
    
    init(exercise: String, sets: Int, reps: Int, weight: Double, notes: String? = nil) {
        self.exercise = exercise
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.notes = notes
    }
    
    // プルアップ専用イニシャライザ
    init(pullUpVariant: PullUpVariant, sets: Int, reps: Int, isAssisted: Bool = false, assistWeight: Double = 0.0, maxConsecutiveReps: Int = 0, notes: String? = nil) {
        self.exercise = "プルアップ"
        self.pullUpVariantRawValue = pullUpVariant.rawValue
        self.sets = sets
        self.reps = reps
        self.weight = 0.0  // 自重なので0
        self.isAssisted = isAssisted
        self.assistWeight = assistWeight
        self.maxConsecutiveReps = maxConsecutiveReps
        self.notes = notes
    }
}

enum StrengthExercise: String, CaseIterable {
    case benchPress = "ベンチプレス"
    case dumbbellPress = "ダンベルプレス"
    case pushUp = "プッシュアップ"
    case pullUp = "プルアップ"
    case latPulldown = "ラットプルダウン"
    case rowing = "ローイング"
    case squat = "スクワット"
    case deadlift = "デッドリフト"
    case legPress = "レッグプレス"
    case shoulderPress = "ショルダープレス"
    case bicepCurl = "バイセップカール"
    case tricepExtension = "トライセップエクステンション"
    case plank = "プランク"
    case other = "その他"
}

enum PullUpVariant: String, CaseIterable {
    case normal = "ノーマル"
    case wide = "ワイド"
    case close = "クローズ"
    case neutral = "ニュートラル"
    case chinUp = "チンアップ"
    case commando = "コマンドー"
    
    var description: String {
        switch self {
        case .normal:
            return "肩幅程度の順手グリップ"
        case .wide:
            return "肩幅より広い順手グリップ"
        case .close:
            return "肩幅より狭い順手グリップ"
        case .neutral:
            return "ニュートラルグリップ（手のひら向かい合わせ）"
        case .chinUp:
            return "逆手グリップ（手のひら手前向き）"
        case .commando:
            return "コマンドー（横向き交互上下）"
        }
    }
    
    var targetMuscles: [String] {
        switch self {
        case .normal:
            return ["広背筋", "僧帽筋", "上腕二頭筋"]
        case .wide:
            return ["広背筋上部", "大円筋", "僧帽筋中部"]
        case .close:
            return ["広背筋下部", "菱形筋", "上腕二頭筋"]
        case .neutral:
            return ["広背筋", "上腕二頭筋", "前腕"]
        case .chinUp:
            return ["上腕二頭筋", "広背筋下部", "前腕"]
        case .commando:
            return ["広背筋", "僧帽筋", "腹斜筋"]
        }
    }
}