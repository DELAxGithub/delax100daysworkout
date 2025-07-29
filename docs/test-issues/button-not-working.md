# テスト用Issue: ボタンが効かない

このファイルの内容をコピーして、GitHubで新しいIssueを作成してテストできます。

## Issue タイトル
[ボタンが効かない] TodayViewでの問題

## Issue 本文

## バグ報告

**カテゴリ**: ボタンが効かない
**報告時刻**: 2024-01-28T10:30:00Z
**デバイス**: iPhone 14 (iOS 17.5)
**アプリバージョン**: 1.0.0
**現在の画面**: TodayView

### 問題の説明
TodayViewで「やった」ボタンをタップしても反応しません。ボタンはグレーアウトしておらず、タップ可能に見えますが、タップしても何も起こりません。

### 再現手順
1. アプリを起動
2. TodayViewを表示
3. タスクカードの「やった」ボタンをタップ
4. ボタンが反応しない

### 期待される動作
ボタンをタップすると、タスクが完了状態になり、チェックマークアニメーションが表示される

### 実際の動作  
ボタンをタップしても何も起こらない

### 操作履歴
1. [10:29:45] Navigation in MainView
2. [10:29:50] Navigation in TodayView - from: MainView
3. [10:29:55] Button Tap in TaskCardView - button: やった
4. [10:30:00] Error Occurred in TaskCardView - error: ViewModel is nil

### ログ（エラー・警告のみ）
```
[10:29:55] [ERROR] ViewModel is nil (TaskCardView)
[10:29:55] [WARNING] Quick complete action failed (TodayView)
```

### デバイス情報
- Model: iPhone 14
- OS: iOS 17.5
- Screen: 390x844
- App Version: 1.0.0

---
*このIssueは自動的に作成されました*