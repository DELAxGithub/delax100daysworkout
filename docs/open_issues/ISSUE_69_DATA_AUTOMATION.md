# Issue #69: データ投入完全自動化システム

**Priority**: High  
**Type**: Enhancement  
**Epic**: Academic Analysis System (Issue #58)  
**Estimated Effort**: 8-10 days

---

## 📋 Problem Statement

現在の仕様ではHealthKit/Strava/Garmin連携がCSV/JSON経由の手動処理前提となっており、運用負荷が高い。リアルタイム分析のためには完全自動化が必要。

---

## 🎯 Goals

### Primary Goals
- **HealthKit自動同期**: リアルタイム体重・心拍数取得
- **Strava Webhook**: 新規アクティビティの即座取り込み  
- **Garmin Connect IQ**: デバイス直接連携
- **重複排除**: 複数ソース間の自動重複検出・統合

### Success Metrics
- データ投入の手動作業を95%削減
- 新規データ取り込み遅延 < 5分
- データ品質スコア維持 > 90%

---

## 🏗️ Technical Implementation

### HealthKit自動同期
```swift
// リアルタイム監視
class HealthKitAutoSync {
    func enableBackgroundUpdates() {
        // 体重・心拍数の変更を即座検知
        healthStore.enableBackgroundDelivery(for: .bodyMass, frequency: .immediate)
        healthStore.enableBackgroundDelivery(for: .restingHeartRate, frequency: .immediate)
    }
    
    func handleHealthKitUpdate(_ samples: [HKSample]) {
        // 自動的にDailyMetricへ保存
        Task {
            await dataProcessor.processHealthKitSamples(samples)
        }
    }
}
```

### Strava Webhook連携
```swift
// Webhook受信エンドポイント
struct StravaWebhookHandler {
    func handleActivityUpdate(_ payload: StravaWebhookPayload) async {
        guard payload.aspectType == "create" else { return }
        
        // 新規アクティビティの詳細取得
        let activity = await stravaAPI.getDetailedActivity(payload.objectId)
        
        // WorkoutRecord + CyclingDetailへ自動変換
        let workoutRecord = await convertToWorkoutRecord(activity)
        await dataStore.save(workoutRecord)
    }
}
```

### Garmin Connect IQ SDK
```swift
// Garmin直接連携
class GarminConnectSync {
    func setupRealTimeSync() {
        // .fit ファイルの自動パース
        garminSDK.onActivityComplete { fitFile in
            Task {
                let parsedData = await fitFileParser.parse(fitFile)
                await processGarminActivity(parsedData)
            }
        }
    }
}
```

### 重複排除エンジン
```swift
struct DuplicateDetectionEngine {
    func detectDuplicates(_ newRecord: WorkoutRecord) -> [WorkoutRecord] {
        // 複合キーでの重複検出
        let duplicateKey = "\(newRecord.date.dayKey)_\(newRecord.duration)_\(newRecord.deviceName ?? "")"
        return existingRecords.filter { $0.duplicateKey == duplicateKey }
    }
    
    func mergeRecords(_ records: [WorkoutRecord]) -> WorkoutRecord {
        // 最も詳細なデータソースを優先
        // Garmin > Strava > HealthKit の優先順位
        return records.sorted { $0.dataQuality > $1.dataQuality }.first!
    }
}
```

---

## 📱 User Experience

### 自動化設定画面
- HealthKit権限管理
- Strava/Garmin連携ステータス
- 自動同期間隔設定
- 重複解決ルール設定

### 同期ステータス表示
- リアルタイム同期状況
- 最終同期時刻
- エラー・警告表示
- データソース別統計

---

## ⚡ Implementation Plan

### Phase 1: HealthKit完全自動化 (3 days)
1. Background delivery設定
2. 自動データ変換・保存
3. エラーハンドリング・リトライ

### Phase 2: Strava Webhook (3 days)  
1. Webhook受信サーバー
2. OAuth認証・トークン管理
3. Activity詳細取得・変換

### Phase 3: Garmin統合 (2 days)
1. Connect IQ SDK組み込み
2. .fitファイルパース
3. デバイス別対応

### Phase 4: 重複排除・統合 (2 days)
1. 重複検出アルゴリズム
2. データマージロジック
3. 統合テスト

---

## 🧪 Testing Strategy

### 自動化テスト
```swift
class AutomationE2ETests: XCTestCase {
    func testHealthKitAutoSync() {
        // HealthKitデータ変更をシミュレート
        // 5分以内の自動取り込み確認
    }
    
    func testStravaWebhookFlow() {
        // Webhook payload送信
        // WorkoutRecord自動生成確認
    }
    
    func testDuplicateResolution() {
        // 同一アクティビティを複数ソースから投入
        // 適切な重複排除・統合確認
    }
}
```

---

## 📊 Success Criteria

- [ ] HealthKit変更検知 < 1分
- [ ] Strava新規アクティビティ取り込み < 5分  
- [ ] Garmin同期完了 < 10分
- [ ] 重複データ自動解決率 > 95%
- [ ] 手動データ投入作業 95%削減達成

*Created: 2025-08-13*  
*Status: Ready for Implementation*  
*Dependencies: Issue #58 (Academic Analysis System)*