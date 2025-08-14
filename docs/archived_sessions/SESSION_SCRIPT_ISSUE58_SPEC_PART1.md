# Issue #58 学術レベル相関分析システム仕様書 (Part 1)

**Issue #58 実装仕様書 - 概要・データモデル編**  
**Date**: 2025-08-13  
**Status**: ✅ **Part1完了** | 準拠: アナリスト鬼チェックリスト

---

## 0. 概要

- **アプリ名**: Delax 100 Days Workout  
- **バージョン**: 1.0 (iOS 17.0+, SwiftUI + SwiftData)  
- **対応OS**: iOS 17.0以上  
- **データ保管**: ローカル (SwiftData) + Apple HealthKit連携  
- **タイムゾーン固定**: **America/Toronto** (UTC-5/UTC-4)

---

## 1. データモデル (SwiftData @Model完全定義)

### 基本テーブル構造

#### 1. `WorkoutRecord` (1ライド＝1レコード)
```swift
@Model final class WorkoutRecord {
    var id: UUID = UUID()
    var date: Date                    // 実施日時
    var workoutType: WorkoutType      // enum: cycling|strength|flexibility|pilates|yoga
    var summary: String               // ワークアウト概要
    var isCompleted: Bool = false     // 完了フラグ
    var isQuickRecord: Bool = false   // クイック記録フラグ
    
    @Relationship(deleteRule: .cascade)
    var cyclingDetail: CyclingDetail? // サイクリング詳細
    
    @Relationship(deleteRule: .cascade) 
    var strengthDetails: [StrengthDetail]? // 筋力詳細配列
}
```

#### 2. `CyclingDetail` (パワートレーニング詳細)
```swift
@Model final class CyclingDetail {
    var duration: Int                 // 時間(分)
    var averagePower: Int?           // 平均パワー(W) 
    var normalizedPower: Int?        // NP(W)
    var averageHeartRate: Int?       // 平均心拍(bpm)
    var maxHeartRate: Int?           // 最大心拍(bpm)
    var tss: Double?                 // Training Stress Score
    var intensityFactor: Double?     // IF = NP/FTP
    var kilojoules: Double?          // 総エネルギー(kJ)
    var deviceName: String?          // デバイス名(Zwift|Garmin等)
    var notes: String?               // 備考
}
```

#### 3. `FTPHistory` (FTPテスト履歴)
```swift
@Model final class FTPHistory {
    var id: UUID = UUID()
    var date: Date                    // 測定日
    var ftpValue: Int                // FTP値(W)
    var measurementMethod: FTPMeasurementMethod // enum: 20MinTest|RampTest|Manual
    var notes: String?               // 備考
    var isAutoCalculated: Bool       // 自動計算フラグ
    var sourceWorkoutId: UUID?       // 元ワークアウトID
    var createdAt: Date              // 作成日時
}
```

#### 4. `StrengthDetail` (筋力セット詳細)
```swift
@Model final class StrengthDetail {
    var exerciseName: String         // 種目名(Squat|Deadlift|Bulgarian等)
    var weight: Double               // 重量(kg)
    var reps: Int                    // 回数
    var sets: Int                    // セット数
    var rpe: Double?                 // RPE(6-10)
    var restTimeSeconds: Int?        // 休憩時間(秒)
    var oneRepMax: Double?           // 推定1RM (Epley式: weight*(1+reps/30))
    var notes: String?               // 備考
}
```

#### 5. `FlexibilityDetail` (柔軟性測定)
```swift
@Model final class FlexibilityDetail {
    var sitAndReachCm: Double?       // 前屈(cm) 床到達=0、超過=負値
    var shoulderFlexibilityDeg: Double? // 肩関節可動域(度)
    var hipFlexibilityDeg: Double?   // 股関節可動域(度) 
    var hamstringFlexibilityDeg: Double? // ハムストリング(度)
    var notes: String?               // 備考
}
```

#### 6. `DailyMetric` (日次体調メトリクス)
```swift
@Model final class DailyMetric {
    var id: UUID = UUID()
    var date: Date                   // 測定日
    var weightKg: Double?            // 体重(kg)
    var restingHeartRate: Int?       // 安静時心拍(bpm)
    var maxHeartRate: Int?           // 最大心拍(bpm)
    var dataSource: MetricDataSource // enum: Manual|AppleHealth|Calculated
    var lastSyncDate: Date?          // 最終同期日時
    var createdAt: Date              // 作成日時
    var updatedAt: Date              // 更新日時
}
```

#### 7. `WeeklyComputedMetrics` (週次集計キャッシュ)
```swift
@Model final class WeeklyComputedMetrics {
    var weekStartDate: Date          // 週開始日(月曜)
    var totalTSS: Double            // 週TSS合計
    var avgNormalizedPower: Double?  // 週平均NP(W)
    var heartRateEfficiency: Double? // 心拍効率 = NP/avgHR
    var avgOneRepMaxSquat: Double?   // 週平均1RMスクワット(kg)
    var avgSitReach: Double?         // 週平均前屈(cm)
    var powerToWeightRatio: Double?  // PWR = FTP/体重
    var computedAt: Date             // 計算日時
}
```

### 制約・インデックス定義

#### 主キー制約
- 全モデル: `id: UUID` 主キー
- `DailyMetric`: `date + dataSource` 複合ユニーク
- `FTPHistory`: `date + measurementMethod` 複合ユニーク

#### 外部キー制約
- `CyclingDetail.workoutRecord` → `WorkoutRecord.id`
- `StrengthDetail.workoutRecord` → `WorkoutRecord.id`
- `FlexibilityDetail.workoutRecord` → `WorkoutRecord.id`

#### データ整合性
- **欠測値**: `NULL`許容 (Optional型で対応)
- **重複排除**: `date + duration + deviceName` で重複検出
- **単位系**: パワー(W整数)、心拍(bpm整数)、角度(度1decimal)、距離(0.1cm)

---

*続き: Part2 (集計・解析・ダッシュボード仕様)*