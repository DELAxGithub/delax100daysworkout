# 総合トレーニングアプリ拡張 設計書

## 1. アーキテクチャ概要

### 1.1 レイヤー構成
```
┌─────────────────────────────────────┐
│         Views (SwiftUI)             │
├─────────────────────────────────────┤
│      ViewModels (@Observable)       │
├─────────────────────────────────────┤
│    Models (SwiftData @Model)       │
├─────────────────────────────────────┤
│      Services / Managers            │
└─────────────────────────────────────┘
```

### 1.2 データフロー
- 単方向データフロー：View → ViewModel → Model → SwiftData
- ViewModelがビジネスロジックとデータ変換を担当
- Modelは純粋なデータ構造

## 2. データモデル設計

### 2.1 既存モデルの拡張

#### WorkoutRecord（既存を拡張）
```swift
@Model
final class WorkoutRecord {
    var date: Date
    var workoutType: WorkoutType
    var summary: String
    var isCompleted: Bool = false
    var isQuickRecord: Bool = false  // クイック記録フラグ
    
    // リレーション
    var cyclingDetail: CyclingDetail?
    var strengthDetails: [StrengthDetail]?
    var flexibilityDetail: FlexibilityDetail?
    var templateTask: DailyTask?  // テンプレートとの関連
}
```

### 2.2 新規モデル

#### WeeklyTemplate
```swift
@Model
final class WeeklyTemplate {
    var name: String
    var isActive: Bool = false
    var createdAt: Date
    var updatedAt: Date
    var dailyTasks: [DailyTask]
}
```

#### DailyTask
```swift
@Model
final class DailyTask {
    var dayOfWeek: Int  // 0=日曜, 1=月曜...
    var workoutType: WorkoutType
    var title: String  // "Push筋トレ", "SST 60分"等
    var description: String?
    var targetDetails: TargetDetails  // 目標値
    var isFlexible: Bool = false  // 自動調整可能フラグ
}
```

#### TargetDetails
```swift
struct TargetDetails: Codable {
    // サイクリング用
    var duration: Int?
    var intensity: CyclingIntensity?
    var targetPower: Int?
    
    // 筋トレ用
    var exercises: [String]?
    var targetSets: Int?
    
    // 柔軟性用
    var targetDuration: Int?
}
```

#### WeeklyReport
```swift
@Model
final class WeeklyReport {
    var weekStartDate: Date
    var cyclingCompleted: Int
    var cyclingTarget: Int
    var strengthCompleted: Int
    var strengthTarget: Int
    var flexibilityCompleted: Int
    var flexibilityTarget: Int
    var summary: String
    var achievements: [String]  // ["体重-0.4kg", "FTP+8W"等]
}
```

## 3. 画面設計

### 3.1 メイン画面構成
```
TabView
├── TodayView（今日のタスク）★新規
├── DashboardView（ダッシュボード）
├── LogEntryView（記録入力）
├── ProgressView（進捗グラフ）
└── SettingsView（設定）
```

### 3.2 TodayView（新規）
- **構成要素**
  - 日付と挨拶メッセージ
  - 今日のタスクカード（最大3つ）
  - クイック完了ボタン
  - 詳細入力への遷移ボタン
  - 進捗インジケーター

- **タスクカード**
  ```
  ┌─────────────────────────┐
  │ 🚴 バイク SST 45分      │
  │ 目標: 230W              │
  │ [✓ やった] [詳細入力]   │
  └─────────────────────────┘
  ```

### 3.3 DashboardView（改良）
- **週間サマリーセクション**
  - 達成率サークル（筋トレ 3/4、バイク 2/3、柔軟 6/7）
  - 今週のハイライト（PR達成、連続記録等）
  
- **統計セクション**
  - 体重/FTP/柔軟性の変化
  - ミニグラフ表示

### 3.4 QuickRecordSheet（新規）
- モーダルシートで表示
- ワンタップで完了記録
- オプションで簡易メモ追加
- 「詳細を後で入力」オプション

## 4. ビジネスロジック設計

### 4.1 TaskSuggestionManager
```swift
class TaskSuggestionManager {
    func getTodaysTasks(template: WeeklyTemplate, history: [WorkoutRecord]) -> [DailyTask]
    func adjustTaskDifficulty(task: DailyTask, recentPerformance: Performance) -> DailyTask
    func suggestAlternative(originalTask: DailyTask, reason: SkipReason) -> DailyTask?
}
```

### 4.2 ProgressAnalyzer
```swift
class ProgressAnalyzer {
    func detectPR(newRecord: WorkoutRecord, history: [WorkoutRecord]) -> Achievement?
    func calculateWeeklyStats(records: [WorkoutRecord]) -> WeeklyStats
    func generateMotivationalMessage(progress: Progress) -> String
}
```

### 4.3 TemplateManager
```swift
class TemplateManager {
    func createDefaultTemplate() -> WeeklyTemplate
    func adjustTemplate(current: WeeklyTemplate, weeklyReport: WeeklyReport) -> WeeklyTemplate
    func activateTemplate(_ template: WeeklyTemplate)
}
```

## 5. UI/UXパターン

### 5.1 インタラクション
- **プライマリアクション**: 大きなタップターゲット（最小44pt）
- **スワイプジェスチャー**: タスクカードを横スワイプで完了
- **長押し**: クイックアクションメニュー表示

### 5.2 フィードバック
- **即時フィードバック**: チェックマークアニメーション
- **達成感演出**: PRバッジのポップアップ、紙吹雪アニメーション
- **進捗可視化**: プログレスリングの段階的な埋まり

### 5.3 カラースキーム
```swift
extension Color {
    static let cycling = Color.blue
    static let strength = Color.orange
    static let flexibility = Color.green
    static let achievement = Color.purple
    static let encouragement = Color.pink
}
```

## 6. データ永続化戦略

### 6.1 SwiftData設定
- モデルバージョニング対応
- マイグレーション計画
- インデックス設定（date, workoutType）

### 6.2 キャッシュ戦略
- 週次レポートは生成後キャッシュ
- グラフデータは表示時に計算

## 7. 将来の拡張ポイント

### 7.1 通知システム
- UserNotificationsフレームワーク用のプロトコル定義
- 通知タイミングの設定保存

### 7.2 HealthKit連携
- HealthKitManagerプロトコルの定義
- 体重、心拍数データの同期準備

### 7.3 ウィジェット対応
- WidgetKitデータプロバイダーの準備
- 今日のタスク表示用データ構造