# Issue #58 学術レベル相関分析システム仕様書 (Part 2)

**Issue #58 実装仕様書 - 集計・解析・ダッシュボード編**  
**Date**: 2025-08-13  
**Status**: ✅ **Part2完了** | 準拠: アナリスト鬼チェックリスト

---

## 3. 集計・派生指標 (数式を仕様明記)

### 基本派生指標計算

#### **PWR (Power-to-Weight Ratio)**
```swift
PWR = latest(ftpValue) / latest(weightKg)
// 単位: W/kg、小数点1位
// 例: FTP 250W, 体重 63.8kg → PWR = 3.9 W/kg
```

#### **心拍効率 (Heart Rate Efficiency)**
```swift
// ライド単位
hrEfficiency = normalizedPower / averageHeartRate
// 週次加重平均
weeklyHREfficiency = Σ(normalizedPower * duration) / Σ(averageHeartRate * duration)
// 単位: W/bpm、小数点2位
// 例: NP 200W, 平均心拍 150bpm → 1.33 W/bpm
```

#### **筋力効率指数 (Strength Efficiency Index)**
```swift
strengthIndex = max_weekly(oneRepMaxSquat) / latest(weightKg)
// 単位: 無次元、小数点2位
// 例: 1RMスクワット 100kg, 体重 63.8kg → 1.57
```

#### **柔軟性改善率 (Flexibility Improvement Rate)**
```swift
flexibilityImprovement = baseline_sitReach - current_sitReach
// 負値が改善（より深く前屈可能）
// 単位: cm、小数点1位
// 例: ベースライン 5cm, 現在 2cm → 改善率 3cm
```

### 週次集計指標

#### **週間TSS合計**
```swift
weeklyTSS = Σ(tss) WHERE date BETWEEN weekStart AND weekEnd
// 平滑化: 4週移動平均
rollingTSS = AVG(weeklyTSS) OVER (ORDER BY week ROWS 3 PRECEDING)
```

#### **CTL/ATL/TSB算出 (オプション)**
```swift
// 慢性負荷 (CTL): 42日指数移動平均
CTL[n] = CTL[n-1] + (TSS[n] - CTL[n-1]) * (1 - exp(-1/42))

// 急性負荷 (ATL): 7日指数移動平均  
ATL[n] = ATL[n-1] + (TSS[n] - ATL[n-1]) * (1 - exp(-1/7))

// 負荷バランス (TSB)
TSB[n] = CTL[n] - ATL[n]
```

### 欠測データ処理

#### **補間ルール**
- **線形補間**: 3日以内の欠測 → 前後値の線形補間
- **前値保持**: 7日以内の欠測 → 直前値を使用
- **除外**: 7日超の欠測 → 該当期間を解析から除外

#### **品質スコア**
```swift
dataQualityScore = (実測日数 / 対象期間日数) * 100
// 90%以上: 高品質、70-89%: 中品質、70%未満: 低品質
```

---

## 4. 解析モジュール (統計手法明記)

### 単相関分析

#### **Pearson相関係数**
```swift
func pearsonCorrelation(x: [Double], y: [Double]) -> Double {
    // r = Σ((xi - x̄)(yi - ȳ)) / √(Σ(xi - x̄)²Σ(yi - ȳ)²)
    // 有効範囲: -1.0 ≤ r ≤ 1.0
    // 解釈: |r| ≥ 0.7 強相関, 0.3-0.7 中相関, < 0.3 弱相関
}

// 解析対象ペア
correlationPairs = [
    (ftpValue, oneRepMaxSquat),      // FTP vs 筋力
    (ftpValue, sitAndReachCm),       // FTP vs 柔軟性  
    (heartRateEfficiency, totalTSS), // 心拍効率 vs 負荷
    (powerToWeightRatio, weightKg)   // PWR vs 体重
]
```

#### **Spearman順位相関 (ノンパラメトリック)**
```swift
func spearmanCorrelation(x: [Double], y: [Double]) -> Double {
    // rs = 1 - (6Σd²) / (n(n²-1))
    // 非線形関係・外れ値に頑健
}
```

### 重回帰分析

#### **多重線形回帰**
```swift
// 目的変数: FTP値
// 説明変数: 筋力、柔軟性、心拍効率、負荷
ftpValue ~ β₀ + β₁*oneRepMaxSquat + β₂*sitReachCm + β₃*hrEfficiency + β₄*totalTSS + ε

// VIF (多重共線性) チェック
VIF = 1 / (1 - R²ᵢ)  // VIF > 5で除外

// 有意性検定
tStatistic = βᵢ / SE(βᵢ)  // p < 0.05で採用
```

#### **偏相関分析**
```swift
func partialCorrelation(x: [Double], y: [Double], controls: [[Double]]) -> Double {
    // 制御変数の影響を除去した純粋な相関
    // 例: FTP vs 筋力 (体重を制御)
}
```

### ラグ相関分析

#### **時間遅れ相関**
```swift
func lagCorrelation(dependent: [(Date, Double)], independent: [(Date, Double)], maxLag: Int = 6) -> [(Int, Double)] {
    // ラグ1-6週での相関探索
    // 例: 筋力トレーニング → 2週後のFTP向上
    // 最大相関とそのラグ週数を返却
}
```

### モデル更新仕様

#### **学習データ期間**
- **最小期間**: 12週間のデータ
- **更新頻度**: 週1回 (月曜日)
- **ローリング窓**: 直近26週間 (約6ヶ月)

#### **モデル評価指標**
```swift
// 決定係数
R² = 1 - (SS_res / SS_tot)

// 平均二乗誤差
RMSE = √(Σ(yᵢ - ŷᵢ)² / n)

// 調整済み決定係数
R²_adj = 1 - (1 - R²) * (n - 1) / (n - k - 1)
```

---

## 5. ダッシュボード要件 (MVP必須)

### 週次メトリクスカード

#### **表示項目**
```swift
struct WeeklyMetricsCard {
    var currentFTP: Int              // 最新FTP (W)
    var currentWeight: Double        // 最新体重 (kg)
    var powerToWeightRatio: Double   // PWR (W/kg)
    var weeklyTSS: Double           // 週TSS合計
    var heartRateEfficiency: Double  // 心拍効率 (W/bpm)
    var maxOneRepMax: Double        // 週最大1RM (kg)
    var avgSitReach: Double         // 週平均前屈 (cm)
    var dataQualityScore: Double    // データ品質 (%)
}
```

### 相関マップ (ヒートマップ)

#### **UI仕様**
- **期間**: 直近12週間
- **マトリックス**: 7×7指標相関表
- **色分け**: 強正相関(青)、弱相関(白)、強負相関(赤)
- **数値表示**: 相関係数 (-1.00 to 1.00)

### ラグ分析プロット

#### **チャート仕様**
```swift
struct LagAnalysisChart {
    var targetMetric: String         // 目的変数 (FTP等)
    var lagWeeks: [Int]             // 1-6週ラグ
    var correlations: [Double]      // 各ラグでの相関係数
    var maxCorrelationLag: Int      // 最大相関のラグ週
    var significance: [Bool]        // 統計的有意性 (p<0.05)
}
```

### 要因ランキング

#### **重要度指標**
```swift
struct FactorRanking {
    var factorName: String          // 要因名
    var standardizedCoeff: Double   // 標準化回帰係数
    var importance: Double          // |係数|の絶対値
    var pValue: Double             // 有意確率
    var confidenceInterval: (Double, Double) // 95%信頼区間
}
```

### アラートシステム

#### **自動警告条件**
```swift
// 柔軟性悪化警告
if sitReach_3weeks_trend > 0 && consecutive_weeks >= 3 {
    alert("柔軟性3週連続悪化: ペダリング効率低下リスク")
}

// 筋力低下警告  
if oneRepMax_change < -0.05 {  // 5%以上低下
    alert("筋力5%低下検出: トレーニング強度見直し推奨")
}

// 過負荷警告
if hrEfficiency_change < -0.05 && weeklyTSS > historical_avg * 1.3 {
    alert("心拍効率低下 + TSS過多: 過負荷疑い")
}
```

### データ欠測警告

#### **不足データ通知**
```swift
struct DataGapAlert {
    var missingTable: String        // 不足テーブル名
    var lastEntryDate: Date        // 最終入力日
    var daysSinceLast: Int         // 経過日数
    var impactOnAnalysis: String   // 解析への影響度
    var recommendedAction: String  // 推奨アクション
}
```

---

*続き: Part3 (API・品質保証・セキュリティ仕様)*