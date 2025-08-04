# 自転車トレーニング集計機能　実装計画書

## 1. 実装フェーズ概要

### Phase 1: データ基盤構築（Priority: High）
**目標**: 新しいデータモデルとHealthKit連携の基盤を作成
**期間**: 2024年9月1日 - 2024年9月30日
**成果物**: FTPHistory, DailyMetric, HealthKitService

### Phase 2: 基本UI実装（Priority: Medium）
**目標**: トレーニングカレンダーとSST基本ダッシュボードを実装
**期間**: 2024年10月1日 - 2024年10月31日
**成果物**: CalendarView, BasicChartViews

### Phase 3: 高度な分析機能（Priority: Low）
**目標**: W/HR分析、自動FTP提案、エクスポート機能を実装
**期間**: 2024年11月1日 - 2024年11月30日
**成果物**: Advanced Analytics, Export Features

## 2. Phase 1: データ基盤構築

### 2.1 Task 1: FTPHistoryモデル作成
**所要時間**: 2時間
**ファイル**: `Delax100DaysWorkout/Models/FTPHistory.swift`

#### 実装内容
```swift
// 完全なFTPHistoryモデルとenumの実装
// SwiftDataアノテーションの適用
// バリデーションロジックの実装
```

#### 実装ステップ
1. FTPMeasurementMethod enum作成
2. FTPHistory @Modelクラス作成
3. バリデーションメソッド追加
4. Preview用のサンプルデータ作成

#### 検証基準
- [ ] SwiftDataでの永続化が正常動作
- [ ] バリデーションが異常値を適切に検出
- [ ] Xcodeプレビューでサンプルデータ表示

### 2.2 Task 2: DailyMetricモデル作成
**所要時間**: 2時間
**ファイル**: `Delax100DaysWorkout/Models/DailyMetric.swift`

#### 実装内容
```swift
// DailyMetricモデルと関連enumの実装
// Apple Healthデータソース管理
// 重複データ検出・マージロジック
```

#### 実装ステップ
1. MetricDataSource enum作成
2. DailyMetric @Modelクラス作成
3. 重複検出ロジック実装
4. 日付ベースクエリメソッド追加

#### 検証基準
- [ ] 同日の重複データが適切にマージされる
- [ ] データソース別の管理が正常動作
- [ ] 日付範囲検索が高速動作

### 2.3 Task 3: CyclingDetail拡張
**所要時間**: 1時間
**ファイル**: `Delax100DaysWorkout/Models/CyclingDetail.swift`

#### 実装内容
```swift
// 既存CyclingDetailへの新フィールド追加
// W/HR計算プロパティ実装
// 後方互換性保証
```

#### 実装ステップ
1. 新フィールド追加（averageHeartRate, maxHeartRate, maxPower）
2. whrRatio計算プロパティ実装
3. マイグレーション対応（オプショナルフィールド）
4. 既存データとの互換性テスト

#### 検証基準
- [ ] 既存CyclingDetailデータが破壊されない
- [ ] 新フィールドがオプショナルで正常動作
- [ ] W/HR計算が数学的に正確

### 2.4 Task 4: HealthKitService基盤作成
**所要時間**: 4時間
**ファイル**: `Delax100DaysWorkout/Services/HealthKitService.swift`

#### 実装内容
```swift
// HealthKit権限管理
// 基本的なデータ取得メソッド
// エラーハンドリング
```

#### 実装ステップ
1. HKHealthStore初期化
2. 権限要求メソッド実装
3. 体重データ取得メソッド実装
4. ワークアウトデータ取得メソッド実装
5. エラーハンドリング実装

#### 検証基準
- [ ] iOS実機でHealthKit権限要求が正常動作
- [ ] 体重データが正確に取得される
- [ ] ワークアウトデータが正確に取得される
- [ ] 権限拒否時のエラーハンドリング

### 2.5 Task 5: MainApp更新
**所要時間**: 1時間
**ファイル**: `Delax100DaysWorkout/Delax100DaysWorkoutApp.swift`

#### 実装内容
```swift
// SwiftDataモデルコンテナに新モデル追加
// HealthKit権限要求の統合
```

#### 実装ステップ
1. modelContainer設定にFTPHistory, DailyMetric追加
2. アプリ起動時のHealthKit初期化
3. 必要な権限説明文（Info.plist）追加

#### 検証基準
- [ ] アプリ起動時にクラッシュしない
- [ ] SwiftDataで新モデルが永続化される
- [ ] HealthKit権限ダイアログが適切に表示

## 3. Phase 2: 基本UI実装

### 3.1 Task 6: TrainingCalendarView作成
**所要時間**: 6時間
**ファイル**: `Delax100DaysWorkout/Features/Calendar/TrainingCalendarView.swift`

#### 実装内容
```swift
// 月次カレンダーグリッド表示
// 日別のアクティビティインジケーター
// 日付タップでの詳細表示
```

#### 実装ステップ
1. CalendarViewModel作成
2. 月次グリッドレイアウト実装
3. 日別データ表示インジケーター
4. DayDetailSheet実装
5. ナビゲーション統合

#### 検証基準
- [ ] カレンダーが正常に月次表示される
- [ ] アクティビティのある日が視覚的に区別される
- [ ] 日付タップで詳細情報が表示される
- [ ] スムーズな月次ナビゲーション

### 3.2 Task 7: SSTDashboard基本機能
**所要時間**: 4時間
**ファイル**: `Delax100DaysWorkout/Features/SST/SSTDashboardView.swift`

#### 実装内容
```swift
// 現在のFTP表示カード
// 基本的なFTP推移チャート
// 目標との比較表示
```

#### 実装ステップ
1. SSTDashboardViewModel作成
2. CurrentFTPCard UI実装
3. 基本FTPProgressChart実装（Swift Charts）
4. データ取得・表示ロジック

#### 検証基準
- [ ] 現在のFTPが正確に表示される
- [ ] FTP推移チャートが描画される
- [ ] データがない場合の適切なUI表示
- [ ] チャート描画が1秒以内で完了

### 3.3 Task 8: データ入力UI
**所要時間**: 3時間
**ファイル**: `Delax100DaysWorkout/Features/DataEntry/`

#### 実装内容
```swift
// FTP手動入力フォーム
// 体重入力フォーム
// Apple Health手動同期ボタン
```

#### 実装ステップ
1. FTPEntrySheet作成
2. WeightEntrySheet作成
3. HealthSyncButton実装
4. バリデーション・エラーハンドリング

#### 検証基準
- [ ] FTP入力時の妥当性チェックが動作
- [ ] 体重入力がDailyMetricに保存される
- [ ] Health同期が手動実行できる
- [ ] 入力完了時の適切なフィードバック

## 4. Phase 3: 高度な分析機能

### 4.1 Task 9: W/HR効率分析
**所要時間**: 3時間
**ファイル**: `Delax100DaysWorkout/Services/WHRAnalysisService.swift`

#### 実装内容
```swift
// W/HR計算ロジック
// 効率トレンド分析
// 改善提案アルゴリズム
```

### 4.2 Task 10: 自動FTP提案機能
**所要時間**: 4時間
**ファイル**: `Delax100DaysWorkout/Services/FTPAnalysisService.swift`

#### 実装内容
```swift
// 20分テスト検出
// FTP推定計算
// 提案UI実装
```

### 4.3 Task 11: エクスポート機能
**所要時間**: 3時間
**ファイル**: `Delax100DaysWorkout/Services/ExportService.swift`

#### 実装内容
```swift
// CSV形式エクスポート
// PDFレポート生成
// 共有機能統合
```

## 5. 実装順序とマイルストーン

### Week 1 (9/1-9/7): データモデル基盤
- [ ] FTPHistory作成・テスト
- [ ] DailyMetric作成・テスト
- [ ] CyclingDetail拡張・マイグレーション確認

### Week 2 (9/8-9/14): HealthKit連携
- [ ] HealthKitService基本機能実装
- [ ] 権限管理・エラーハンドリング
- [ ] 実機での動作確認

### Week 3 (9/15-9/21): UI基盤準備
- [ ] MainApp更新・統合テスト
- [ ] 既存機能への影響確認
- [ ] データ入力UI実装

### Week 4 (9/22-9/30): Phase 1 完了・検証
- [ ] 全機能の統合テスト
- [ ] 性能テスト・メモリリーク確認
- [ ] ドキュメント更新

### Week 5-6 (10/1-10/14): カレンダーUI
- [ ] TrainingCalendarView実装
- [ ] DayDetailView実装
- [ ] ナビゲーション統合

### Week 7-8 (10/15-10/31): ダッシュボードUI
- [ ] SSTDashboardView実装
- [ ] チャート機能実装
- [ ] Phase 2 完了検証

## 6. リスク管理

### 高リスク項目
1. **HealthKit実機テスト**: iOS Simulatorで完全テストできない
   - **対策**: 早期の実機テスト実施、複数デバイスでの検証

2. **既存データ破壊**: CyclingDetail拡張時のデータ損失
   - **対策**: マイグレーション前のデータバックアップ、段階的ロールアウト

3. **性能問題**: 大量データでのチャート描画遅延
   - **対策**: 早期の性能テスト、データ間引きアルゴリズム準備

### 中リスク項目
1. **UIレスポンシブ対応**: 異なるiOSデバイスサイズ
   - **対策**: 各デバイスサイズでのレイアウト確認

2. **エラーハンドリング**: HealthKitアクセス拒否時のUX
   - **対策**: 適切なフォールバック画面とガイダンス実装

## 7. 品質保証計画

### 7.1 テスト項目
#### 単体テスト
- [ ] FTPHistory, DailyMetricのCRUD操作
- [ ] W/HR計算の数学的正確性
- [ ] バリデーションロジックの境界値テスト

#### 統合テスト
- [ ] HealthKit連携の正常・異常系
- [ ] SwiftDataマイグレーションの安全性
- [ ] 既存機能との共存確認

#### ユーザビリティテスト
- [ ] カレンダーナビゲーションの直感性
- [ ] データ入力フローの効率性
- [ ] エラーメッセージの理解しやすさ

### 7.2 コードレビュー基準
- SwiftUIベストプラクティス準拠
- SwiftDataの適切な使用
- メモリリークの回避
- アクセシビリティ対応

## 8. デプロイメント計画

### 8.1 段階リリース
1. **Alpha**: Phase 1完了後、開発者内テスト
2. **Beta**: Phase 2完了後、限定ユーザーテスト  
3. **Production**: Phase 3完了後、全ユーザーリリース

### 8.2 ロールバック計画
- SwiftDataマイグレーション失敗時の復旧手順
- HealthKit連携問題時の代替フロー
- 性能問題発生時の機能無効化オプション

## 9. 成功基準

### 9.1 機能的成功基準
- [ ] 全てのMUST要件が実装され動作する
- [ ] Apple Health連携が安定動作する（成功率95%以上） 
- [ ] カレンダー表示が1秒以内で完了する
- [ ] チャート描画が2秒以内で完了する

### 9.2 品質成功基準
- [ ] クラッシュ率0.1%以下
- [ ] 既存機能への影響なし
- [ ] メモリ使用量増加50MB以下
- [ ] バッテリー消費への影響軽微

### 9.3 ユーザー体験成功基準
- [ ] FTP向上が視覚的に理解できる
- [ ] トレーニング全体像が一目で把握できる
- [ ] データ入力が5タップ以内で完了する

この実装計画に従って、spec-driven developmentアプローチで確実に機能を構築していきます。