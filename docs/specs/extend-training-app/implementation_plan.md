# 総合トレーニングアプリ拡張 実装計画書

## 1. 実装順序と優先度

### Phase 1: 基盤整備（優先度：高）
1. **Xcodeプロジェクト設定の自動化**
   - プロジェクトファイル（.pbxproj）の自動更新スクリプト作成
   - 新規ファイルの自動追加機能

2. **データモデルの実装**
   - WeeklyTemplate, DailyTask, TargetDetailsモデル作成
   - WorkoutRecordモデルの拡張（isQuickRecord追加）
   - モデル間のリレーション設定

### Phase 2: コア機能実装（優先度：高）
3. **TodayView画面の実装**
   - 基本レイアウト作成
   - タスクカードコンポーネント
   - クイック完了機能

4. **TaskSuggestionManager実装**
   - 今日のタスク取得ロジック
   - テンプレートからのタスク生成

5. **DashboardView改良**
   - 3種類のトレーニング進捗表示
   - 週間サマリーセクション追加

### Phase 3: 記録機能強化（優先度：中）
6. **QuickRecordSheet実装**
   - モーダルシート作成
   - ワンタップ完了フロー

7. **LogEntryViewの統合**
   - 既存の詳細入力機能との連携
   - クイック記録からの遷移

### Phase 4: 分析・フィードバック機能（優先度：中）
8. **ProgressAnalyzer実装**
   - PR検出ロジック
   - 週次統計計算
   - 励ましメッセージ生成

9. **WeeklyReport機能**
   - レポート自動生成
   - 達成率計算

### Phase 5: UI/UX改善（優先度：低）
10. **アニメーション実装**
    - チェックマークアニメーション
    - PRバッジ表示
    - プログレスリング

11. **ビジュアルフィードバック**
    - カラースキーム統一
    - アイコン整備

## 2. 各フェーズの詳細タスク

### Phase 1 詳細（推定：2-3時間）

#### 1.1 Xcodeプロジェクト自動化
```bash
# スクリプト作成
- add_to_xcode.py: 新規ファイルをプロジェクトに追加
- update_project.sh: バッチ処理用シェルスクリプト
```

#### 1.2 データモデル実装
```swift
// 作成するファイル
- Models/WeeklyTemplate.swift
- Models/DailyTask.swift
- Models/TargetDetails.swift
- Models/WeeklyReport.swift
```

### Phase 2 詳細（推定：3-4時間）

#### 2.1 TodayView実装
```swift
// 作成するファイル
- Features/Today/TodayView.swift
- Features/Today/TodayViewModel.swift
- Features/Today/TaskCardView.swift
- Features/Today/QuickCompleteButton.swift
```

#### 2.2 ビジネスロジック
```swift
// 作成するファイル
- Services/TaskSuggestionManager.swift
- Services/TemplateManager.swift
```

### Phase 3 詳細（推定：2-3時間）

#### 3.1 QuickRecord機能
```swift
// 作成するファイル
- Features/QuickRecord/QuickRecordSheet.swift
- Features/QuickRecord/QuickRecordViewModel.swift
```

### Phase 4 詳細（推定：2-3時間）

#### 4.1 分析機能
```swift
// 作成するファイル
- Services/ProgressAnalyzer.swift
- Models/Achievement.swift
- Models/WeeklyStats.swift
```

### Phase 5 詳細（推定：1-2時間）

#### 5.1 UI改善
```swift
// 作成するファイル
- Components/AnimatedCheckmark.swift
- Components/PRBadge.swift
- Components/ProgressRing.swift
- Styles/AppColors.swift
```

## 3. 実装時の注意点

### 3.1 既存コードとの整合性
- 既存のDailyLogモデルとの互換性維持
- 既存のUIパターンを踏襲
- 命名規則の統一

### 3.2 パフォーマンス考慮
- SwiftDataのクエリ最適化
- 不要な再描画の防止
- 大量データ時の対応

### 3.3 テスト可能性
- ViewModelの単体テスト準備
- モックデータの作成
- プレビュー用データセット

## 4. リスクと対策

### 4.1 技術的リスク
- **リスク**: Xcodeプロジェクトファイルの自動更新失敗
- **対策**: 手動追加の代替手順を用意

### 4.2 スケジュールリスク
- **リスク**: 実装時間の見積もり超過
- **対策**: Phase単位での段階的リリース

## 5. 成功基準

### 5.1 機能面
- [ ] アプリ起動時に今日のタスクが表示される
- [ ] ワンタップでタスク完了が記録できる
- [ ] 3種類のトレーニングが統合的に管理できる
- [ ] 週次レポートが自動生成される

### 5.2 品質面
- [ ] ビルドエラーなし
- [ ] 既存機能への影響なし
- [ ] レスポンシブなUI動作

## 6. 実装開始前チェックリスト

- [x] 要件定義の確認完了
- [x] 設計書の確認完了
- [x] 既存コードの理解
- [ ] 開発環境の準備
- [ ] Xcodeプロジェクトのバックアップ

## 7. 推定総工数

- Phase 1: 2-3時間
- Phase 2: 3-4時間
- Phase 3: 2-3時間
- Phase 4: 2-3時間
- Phase 5: 1-2時間
- **合計: 10-15時間**

段階的に実装し、各フェーズで動作確認を行いながら進めます。