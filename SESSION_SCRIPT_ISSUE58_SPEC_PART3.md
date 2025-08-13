# Issue #58 学術レベル相関分析システム仕様書 (Part 3)

**Issue #58 実装仕様書 - API・品質保証・セキュリティ編**  
**Date**: 2025-08-13  
**Status**: ✅ **Part3完了** | 準拠: アナリスト鬼チェックリスト

---

## 6. 入出力・API仕様

### データインポート

#### **CSV取り込みスキーマ**
```csv
# rides.csv (サイクリングデータ)
date,type,duration_min,avg_power,normalized_power,avg_hr,tss,intensity_factor,kilojoules,device,notes
2025-08-12,SST,70,190,205,152,84,0.90,650,Zwift,"SST 2x20"
2025-08-11,Z2,90,165,170,142,65,0.75,550,Garmin,"ベース走"

# strength_sets.csv (筋力データ)
date,exercise,weight_kg,reps,sets,rpe,rest_seconds,notes
2025-08-12,Squat,60.0,8,3,7.5,120,"フルレンジ"
2025-08-12,Deadlift,80.0,5,3,8.0,180,"コンベンショナル"

# flexibility_tests.csv (柔軟性データ)
date,sit_reach_cm,shoulder_flex_deg,hip_flex_deg,hamstring_flex_deg,notes
2025-08-12,5.2,35,70,80,"朝測定"

# daily_metrics.csv (日次メトリクス)
date,weight_kg,resting_hr,max_hr,data_source,notes
2025-08-12,63.8,45,185,AppleHealth,"自動同期"

# ftp_tests.csv (FTPテスト)
date,ftp_value,method,source,notes
2025-08-11,201,20MinTest,Zwift,"post-trip retest"
```

#### **JSON インポート形式**
```json
{
  "workoutRecord": {
    "date": "2025-08-12T10:00:00Z",
    "workoutType": "cycling",
    "summary": "SST 2x20分",
    "isCompleted": true,
    "cyclingDetail": {
      "duration": 70,
      "averagePower": 190,
      "normalizedPower": 205,
      "averageHeartRate": 152,
      "tss": 84.0,
      "intensityFactor": 0.90,
      "kilojoules": 650.0,
      "deviceName": "Zwift"
    }
  }
}
```

### API エンドポイント仕様

#### **データ投入API**
```swift
// ワークアウトデータ投入
POST /api/v1/workouts
Content-Type: application/json
Body: WorkoutRecord JSON

// FTPテスト投入
POST /api/v1/ftp-tests  
Content-Type: application/json
Body: FTPHistory JSON

// 日次メトリクス投入
POST /api/v1/daily-metrics
Content-Type: application/json
Body: DailyMetric JSON

// 筋力セット投入
POST /api/v1/strength-sets
Content-Type: application/json
Body: [StrengthDetail] JSON配列
```

#### **分析結果取得API**
```swift
// 相関分析結果
GET /api/v1/analytics/correlation?window=12w&method=pearson
Response: {
  "correlationMatrix": [[Double]],
  "labels": [String],
  "computedAt": "2025-08-13T12:00:00Z",
  "dataQuality": 0.95
}

// ラグ相関分析
GET /api/v1/analytics/lag?target=ftp&maxLag=6
Response: {
  "targetMetric": "ftp",
  "lagCorrelations": [
    {"lag": 1, "correlation": 0.45, "pValue": 0.02},
    {"lag": 2, "correlation": 0.67, "pValue": 0.001}
  ]
}

// 週次レポート
GET /api/v1/reports/weekly?week=2025-W33
Response: WeeklyMetricsCard JSON
```

### エクスポート機能

#### **PDF週次レポート**
```swift
struct WeeklyReportPDF {
    var header: ReportHeader          // 期間・ユーザー情報
    var metricsOverview: MetricsSummary // 主要指標サマリー
    var correlationHeatmap: UIImage   // 相関ヒートマップ画像
    var lagAnalysisCharts: [UIImage]  // ラグ分析チャート
    var factorRanking: [FactorRanking] // 要因ランキング表
    var recommendations: [String]     // 改善提案
    var dataQualityReport: QualityReport // データ品質レポート
}
```

#### **CSV データエクスポート**
```swift
// 統合分析データ
GET /api/v1/export/analysis-data?format=csv&period=12w
Content-Disposition: attachment; filename="analysis_data_2025W33.csv"

# 出力例
week_start,ftp,weight_kg,pwr,weekly_tss,hr_efficiency,squat_1rm,sit_reach_cm
2025-08-05,201,63.8,3.15,420,1.33,100.0,5.2
2025-07-29,198,64.1,3.09,380,1.28,98.5,5.8
```

---

## 7. 品質保証・テスト仕様

### 単体テスト

#### **派生指標計算テスト**
```swift
class MetricsCalculationTests: XCTestCase {
    func testPowerToWeightRatio() {
        // 境界値テスト
        XCTAssertEqual(calculatePWR(ftp: 250, weight: 62.5), 4.0, accuracy: 0.01)
        
        // 欠測値テスト  
        XCTAssertNil(calculatePWR(ftp: nil, weight: 65.0))
        
        // ゼロ除算テスト
        XCTAssertNil(calculatePWR(ftp: 250, weight: 0))
    }
    
    func testCorrelationCalculation() {
        let x = [1.0, 2.0, 3.0, 4.0, 5.0]
        let y = [2.0, 4.0, 6.0, 8.0, 10.0]
        XCTAssertEqual(pearsonCorrelation(x, y), 1.0, accuracy: 0.001)
    }
}
```

#### **統計分析テスト**
```swift
class StatisticalAnalysisTests: XCTestCase {
    func testRegressionModel() {
        // 既知データでの回帰テスト
        let knownData = loadTestDataset()
        let model = multipleLinearRegression(knownData)
        XCTAssertEqual(model.rSquared, 0.85, accuracy: 0.05)
    }
    
    func testLagCorrelation() {
        // 人工的な遅延相関データ
        let laggedData = generateLaggedTestData(lag: 2)
        let result = lagCorrelation(laggedData)
        XCTAssertEqual(result.maxCorrelationLag, 2)
    }
}
```

### E2Eテスト

#### **データパイプラインテスト**
```swift
class DataPipelineE2ETests: XCTestCase {
    func testFullWorkflow() {
        // 1. Stravaデータ取り込み (モック)
        let mockStravaData = createMockStravaData()
        
        // 2. データベース保存
        dataImporter.importWorkout(mockStravaData)
        
        // 3. 週次集計実行
        weeklyAggregator.computeWeeklyMetrics()
        
        // 4. 相関分析実行
        let correlations = correlationEngine.analyze()
        
        // 5. ダッシュボード更新確認
        XCTAssertNotNil(correlations.matrix)
        XCTAssertGreaterThan(correlations.dataQuality, 0.8)
    }
}
```

### パフォーマンステスト

#### **大規模データ処理**
```swift
class PerformanceTests: XCTestCase {
    func testLargeDatasetProcessing() {
        // 26週間・1000レコード/週のデータ生成
        let largeDataset = generateLargeTestDataset(weeks: 26, recordsPerWeek: 1000)
        
        // 処理時間測定
        measure {
            let result = correlationEngine.analyzeDataset(largeDataset)
            XCTAssertNotNil(result)
        }
        
        // メモリ使用量チェック
        XCTAssertLessThan(memoryFootprint(), 100_000_000) // 100MB制限
    }
}
```

#### **リアルタイム更新性能**
- **要求**: データ更新→ダッシュボード反映 < 2秒
- **測定**: UI更新完了までの時間計測
- **制約**: メインスレッドブロッキング < 100ms

---

## 8. セキュリティ・監査・運用

### PII保護・プライバシー

#### **データ匿名化**
```swift
struct AnonymizedUser {
    var hashedUserId: String         // SHA-256ハッシュ化
    var createdAt: Date             // 作成日時のみ保持
    // 個人特定情報は完全除去
}

// ログ出力時の自動マスキング
func logMetric(_ metric: String, value: Double) {
    logger.info("Metric: \(metric), Value: [REDACTED]")
}
```

#### **データ保持期間**
- **生データ**: 2年間保持後自動削除
- **集計データ**: 5年間保持
- **監査ログ**: 7年間保持 (法規制対応)

### 監査ログ

#### **操作ログ記録**
```swift
struct AuditLog {
    var timestamp: Date              // 操作日時
    var userId: String              // ハッシュ化ユーザーID
    var operation: Operation        // enum: Create|Read|Update|Delete
    var dataType: String           // 操作対象データ型
    var recordId: UUID?             // 対象レコードID
    var ipAddress: String           // アクセス元IP
    var userAgent: String           // ユーザーエージェント
    var result: OperationResult     // enum: Success|Failure|Unauthorized
}
```

### バックアップ・災害対策

#### **Recovery目標**
- **RTO (復旧時間目標)**: 4時間以内
- **RPO (復旧時点目標)**: 1時間以内のデータ損失許容

#### **バックアップ戦略**
```swift
// 差分バックアップ (日次)
func performIncrementalBackup() {
    let lastBackupDate = getLastBackupDate()
    let changedRecords = fetchChangedRecords(since: lastBackupDate)
    encryptAndStore(changedRecords, to: .cloudStorage)
}

// フルバックアップ (週次)
func performFullBackup() {
    let allData = fetchAllData()
    let encryptedData = encrypt(allData, key: backupEncryptionKey)
    store(encryptedData, to: .offSiteStorage)
}
```

### 運用監視

#### **ヘルスチェック**
```swift
struct SystemHealthMetrics {
    var databaseResponseTime: TimeInterval    // DB応答時間
    var analysisComputeTime: TimeInterval    // 分析計算時間
    var memoryUsage: Double                 // メモリ使用率
    var diskUsage: Double                   // ディスク使用率
    var errorRate: Double                   // エラー率
    var dataQualityScore: Double           // データ品質スコア
}

// アラート条件
if healthMetrics.databaseResponseTime > 1.0 {
    alertManager.triggerAlert(.databaseSlowResponse)
}
```

---

## ✅ 受け取り合否チェックリスト

### ✅ 必須要件クリア確認

#### **📋 データモデル**
- ✅ 全9テーブル完全定義済み
- ✅ 主キー・外部キー・制約明記
- ✅ 欠測処理・重複排除規則明記

#### **📊 集計・統計**
- ✅ 派生指標数式完全定義
- ✅ Pearson・Spearman・重回帰仕様
- ✅ ラグ相関・偏相関実装仕様

#### **📱 ダッシュボード**
- ✅ 週次カード・相関マップ・ラグプロット・ランキング
- ✅ UI仕様・アラート条件明記
- ✅ データ欠測警告システム

#### **🔌 API・入出力**
- ✅ CSV/JSONスキーマ・具体例
- ✅ REST API仕様・エンドポイント
- ✅ エクスポート機能・PDF/CSV

#### **🛡️ 品質・セキュリティ**
- ✅ 単体・E2E・パフォーマンステスト
- ✅ PII保護・監査ログ・バックアップ
- ✅ RTO/RPO・運用監視仕様

---

**📈 Issue #58 学術レベル相関分析システム: 実装準備100%完了**

*Report Generated: 2025-08-13*  
*Specification Status: ✅ Complete - Ready for Implementation*  
*Compliance: アナリスト鬼チェックリスト 100%準拠*