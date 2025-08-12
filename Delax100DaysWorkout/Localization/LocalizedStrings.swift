import Foundation
import SwiftUI

// MARK: - Localized String System

enum LocalizedString: String, CaseIterable {
    // MARK: - Common Actions
    case done = "common.done"
    case cancel = "common.cancel"
    case save = "common.save"
    case edit = "common.edit"
    case delete = "common.delete"
    case add = "common.add"
    case remove = "common.remove"
    case close = "common.close"
    case back = "common.back"
    case next = "common.next"
    case previous = "common.previous"
    case refresh = "common.refresh"
    case loading = "common.loading"
    case retry = "common.retry"
    
    // MARK: - Navigation
    case home = "navigation.home"
    case schedule = "navigation.schedule"
    case progress = "navigation.progress"
    case settings = "navigation.settings"
    case today = "navigation.today"
    case history = "navigation.history"
    
    // MARK: - Workout Types
    case cycling = "workout.cycling"
    case strength = "workout.strength"
    case flexibility = "workout.flexibility"
    case cardio = "workout.cardio"
    case workout = "workout.general"
    
    // MARK: - Card Actions
    case cardTapHint = "card.tap.hint"
    case cardLongPressHint = "card.longpress.hint"
    case cardEditHint = "card.edit.hint"
    case cardDeleteHint = "card.delete.hint"
    case cardSelectHint = "card.select.hint"
    
    // MARK: - Accessibility Labels
    case workoutCard = "accessibility.workout.card"
    case taskCard = "accessibility.task.card"
    case progressCard = "accessibility.progress.card"
    case metricCard = "accessibility.metric.card"
    case summaryCard = "accessibility.summary.card"
    
    // MARK: - Status Messages
    case completed = "status.completed"
    case inProgress = "status.inprogress"
    case pending = "status.pending"
    case error = "status.error"
    case success = "status.success"
    case warning = "status.warning"
    
    // MARK: - Time & Duration
    case minutes = "time.minutes"
    case hours = "time.hours"
    case seconds = "time.seconds"
    case days = "time.days"
    case weeks = "time.weeks"
    case months = "time.months"
    
    // MARK: - Units
    case watts = "units.watts"
    case bpm = "units.bpm"
    case kg = "units.kg"
    case cm = "units.cm"
    case degrees = "units.degrees"
    case percentage = "units.percentage"
    
    // MARK: - Error Messages
    case errorGeneric = "error.generic"
    case errorNetwork = "error.network"
    case errorSave = "error.save"
    case errorLoad = "error.load"
    case errorInvalidInput = "error.invalid.input"
    
    // MARK: - Success Messages
    case saveSuccess = "success.save"
    case deleteSuccess = "success.delete"
    case updateSuccess = "success.update"
    case syncSuccess = "success.sync"
    
    var localized: String {
        NSLocalizedString(self.rawValue, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}

// MARK: - SwiftUI Text Extension

extension Text {
    init(_ localizedString: LocalizedString) {
        self.init(localizedString.localized)
    }
    
    init(_ localizedString: LocalizedString, arguments: CVarArg...) {
        self.init(localizedString.localized(with: arguments))
    }
}

// MARK: - String Interpolation Support

extension LocalizedString: ExpressibleByStringInterpolation {
    init(stringLiteral value: String) {
        self = LocalizedString(rawValue: value) ?? .errorGeneric
    }
}

// MARK: - Button Text Helper

struct LocalizedButtonText {
    static func done() -> Text { Text(.done) }
    static func cancel() -> Text { Text(.cancel) }
    static func save() -> Text { Text(.save) }
    static func edit() -> Text { Text(.edit) }
    static func delete() -> Text { Text(.delete) }
    static func add() -> Text { Text(.add) }
    static func close() -> Text { Text(.close) }
    static func retry() -> Text { Text(.retry) }
}

// MARK: - Accessibility Text Helper

struct AccessibilityText {
    static func cardTapHint() -> String { LocalizedString.cardTapHint.localized }
    static func cardLongPressHint() -> String { LocalizedString.cardLongPressHint.localized }
    static func cardEditHint() -> String { LocalizedString.cardEditHint.localized }
    static func cardDeleteHint() -> String { LocalizedString.cardDeleteHint.localized }
    
    static func workoutCardLabel(type: String) -> String {
        LocalizedString.workoutCard.localized(with: type)
    }
    
    static func taskCardLabel(title: String, status: String) -> String {
        "\(title), \(status)"
    }
}

// MARK: - Time Formatting Helper

struct TimeFormatter {
    static func duration(minutes: Int) -> String {
        if minutes < 60 {
            return LocalizedString.minutes.localized(with: minutes)
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return LocalizedString.hours.localized(with: hours)
            } else {
                return "\(hours)時間\(remainingMinutes)分"
            }
        }
    }
    
    static func shortDuration(minutes: Int) -> String {
        "\(minutes)分"
    }
}

// MARK: - Unit Formatting Helper

struct UnitFormatter {
    static func power(_ watts: Int) -> String {
        "\(watts)W"
    }
    
    static func heartRate(_ bpm: Int) -> String {
        "\(bpm)bpm"
    }
    
    static func weight(_ kg: Double) -> String {
        String(format: "%.1fkg", kg)
    }
    
    static func distance(_ cm: Double) -> String {
        String(format: "%.1fcm", cm)
    }
    
    static func angle(_ degrees: Int) -> String {
        "\(degrees)°"
    }
    
    static func percentage(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }
}

// MARK: - Localizable.strings keys (for reference)
/*
 To be added to Localizable.strings:
 
 // Common Actions
 "common.done" = "完了";
 "common.cancel" = "キャンセル";
 "common.save" = "保存";
 "common.edit" = "編集";
 "common.delete" = "削除";
 "common.add" = "追加";
 "common.remove" = "削除";
 "common.close" = "閉じる";
 "common.back" = "戻る";
 "common.next" = "次へ";
 "common.previous" = "前へ";
 "common.refresh" = "更新";
 "common.loading" = "読み込み中...";
 "common.retry" = "再試行";
 
 // Navigation
 "navigation.home" = "ホーム";
 "navigation.schedule" = "スケジュール";
 "navigation.progress" = "進捗";
 "navigation.settings" = "設定";
 "navigation.today" = "今日";
 "navigation.history" = "履歴";
 
 // Workout Types
 "workout.cycling" = "サイクリング";
 "workout.strength" = "筋力トレーニング";
 "workout.flexibility" = "柔軟性";
 "workout.cardio" = "有酸素運動";
 "workout.general" = "ワークアウト";
 
 // Card Actions
 "card.tap.hint" = "タップして詳細を表示";
 "card.longpress.hint" = "長押しして編集";
 "card.edit.hint" = "編集";
 "card.delete.hint" = "削除";
 "card.select.hint" = "選択";
 
 // Accessibility Labels
 "accessibility.workout.card" = "%@のワークアウトカード";
 "accessibility.task.card" = "タスクカード";
 "accessibility.progress.card" = "進捗カード";
 "accessibility.metric.card" = "指標カード";
 "accessibility.summary.card" = "サマリーカード";
 
 // Status Messages
 "status.completed" = "完了";
 "status.inprogress" = "進行中";
 "status.pending" = "待機中";
 "status.error" = "エラー";
 "status.success" = "成功";
 "status.warning" = "警告";
 
 // Time & Duration
 "time.minutes" = "%d分";
 "time.hours" = "%d時間";
 "time.seconds" = "%d秒";
 "time.days" = "%d日";
 "time.weeks" = "%d週";
 "time.months" = "%dヶ月";
 
 // Units
 "units.watts" = "W";
 "units.bpm" = "bpm";
 "units.kg" = "kg";
 "units.cm" = "cm";
 "units.degrees" = "°";
 "units.percentage" = "%%";
 
 // Error Messages
 "error.generic" = "エラーが発生しました";
 "error.network" = "ネットワークエラーが発生しました";
 "error.save" = "保存に失敗しました";
 "error.load" = "読み込みに失敗しました";
 "error.invalid.input" = "入力が無効です";
 
 // Success Messages
 "success.save" = "保存しました";
 "success.delete" = "削除しました";
 "success.update" = "更新しました";
 "success.sync" = "同期しました";
 */