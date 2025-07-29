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
    
    init(exercise: String, sets: Int, reps: Int, weight: Double, notes: String? = nil) {
        self.exercise = exercise
        self.sets = sets
        self.reps = reps
        self.weight = weight
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
    case other = "その他"
}