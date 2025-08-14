# Issue #71: 個別適応型警告閾値システム

**Priority**: High  
**Type**: Enhancement  
**Epic**: Academic Analysis System (Issue #58)  
**Estimated Effort**: 4-5 days

---

## 📋 Problem Statement

現行の警告システムは固定閾値（心拍効率-5%等）を使用。個人のベースライン特性を考慮した適応型閾値により精度と納得感を向上。

---

## 🎯 Goals

### Primary Goals
- **個別ベースライン**: 各ユーザーの過去データから動的ベースライン計算
- **適応型閾値**: 個人の変動パターンに基づく閾値自動調整
- **早期警告**: 個人パフォーマンス悪化の早期検出
- **偽陽性削減**: 固定閾値による不要警告の削減

### Success Metrics
- 偽陽性警告を60%削減
- 真の異常検出率を20%向上
- ユーザー警告有用性評価≥4.0/5.0

---

## 🏗️ Technical Implementation

### 個別ベースライン計算
```swift
struct PersonalizedBaselineEngine {
    func calculateDynamicBaseline(userId: String, metric: MetricType, period: TimeInterval = .weeks(12)) -> PersonalBaseline {
        let historicalData = fetchUserMetrics(userId: userId, metric: metric, period: period)
        
        return PersonalBaseline(
            userId: userId,
            metricType: metric,
            meanValue: calculateRobustMean(historicalData),
            standardDeviation: calculateRobustStandardDeviation(historicalData),
            seasonalPattern: detectSeasonalPattern(historicalData),
            trendDirection: calculateTrendDirection(historicalData),
            confidenceInterval: calculateConfidenceInterval(historicalData),
            lastUpdated: Date()
        )
    }
    
    // 外れ値に頑健な統計量計算
    func calculateRobustMean(_ data: [MetricValue]) -> Double {
        let sortedData = data.map(\.value).sorted()
        let trimmedData = Array(sortedData.dropFirst(data.count / 10).dropLast(data.count / 10))
        return trimmedData.reduce(0, +) / Double(trimmedData.count)
    }
    
    // 季節性パターン検出
    func detectSeasonalPattern(_ data: [MetricValue]) -> SeasonalPattern? {
        let weeklyAverages = groupByWeekOfYear(data).mapValues { calculateMean($0) }
        let seasonalVariation = calculateSeasonalVariation(weeklyAverages)
        
        return seasonalVariation > 0.1 ? SeasonalPattern(variation: seasonalVariation, peaks: findSeasonalPeaks(weeklyAverages)) : nil
    }
}
```

### 適応型閾値計算
```swift
struct AdaptiveThresholdEngine {
    func calculatePersonalizedThresholds(baseline: PersonalBaseline, sensitivity: ThresholdSensitivity = .medium) -> AdaptiveThresholds {
        let multiplier = sensitivity.multiplier // low: 3.0, medium: 2.5, high: 2.0
        
        return AdaptiveThresholds(
            warningLowerBound: baseline.meanValue - (baseline.standardDeviation * multiplier * 0.7),
            warningUpperBound: baseline.meanValue + (baseline.standardDeviation * multiplier * 0.7),
            alertLowerBound: baseline.meanValue - (baseline.standardDeviation * multiplier),
            alertUpperBound: baseline.meanValue + (baseline.standardDeviation * multiplier),
            adjustedForTrend: adjustForTrend(baseline),
            adjustedForSeason: adjustForSeason(baseline),
            confidenceLevel: 0.95
        )
    }
    
    // トレンド調整
    func adjustForTrend(_ baseline: PersonalBaseline) -> TrendAdjustment {
        guard let trend = baseline.trendDirection else { return .none }
        
        let adjustmentFactor = abs(trend.slope) * 0.1 // 10%の調整
        return TrendAdjustment(
            factor: adjustmentFactor,
            direction: trend.direction,
            confidence: trend.confidence
        )
    }
    
    // 季節調整
    func adjustForSeason(_ baseline: PersonalBaseline) -> SeasonalAdjustment? {
        guard let seasonal = baseline.seasonalPattern else { return nil }
        
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let expectedVariation = seasonal.getExpectedVariation(week: currentWeek)
        
        return SeasonalAdjustment(
            factor: expectedVariation,
            confidence: seasonal.confidence
        )
    }
}

enum ThresholdSensitivity: CaseIterable {
    case low, medium, high
    
    var multiplier: Double {
        switch self {
        case .low: return 3.0      // 保守的（警告少なめ）
        case .medium: return 2.5   // バランス
        case .high: return 2.0     // 敏感（警告多め）
        }
    }
}
```

### 早期警告システム
```swift
struct EarlyWarningSystem {
    func evaluateMetricValue(_ value: Double, for metric: MetricType, userId: String) async -> WarningResult {
        let baseline = await baselineEngine.calculateDynamicBaseline(userId: userId, metric: metric)
        let thresholds = thresholdEngine.calculatePersonalizedThresholds(baseline: baseline)
        
        let severity = determineSeverity(value: value, thresholds: thresholds)
        let context = await gatherContext(userId: userId, metric: metric)
        
        return WarningResult(
            severity: severity,
            message: generatePersonalizedMessage(value: value, baseline: baseline, context: context),
            recommendations: generateRecommendations(severity: severity, context: context),
            confidence: calculateConfidence(baseline: baseline, context: context),
            shouldAlert: severity >= .warning && context.isReliable
        )
    }
    
    func determineSeverity(value: Double, thresholds: AdaptiveThresholds) -> WarningSeverity {
        if value < thresholds.alertLowerBound || value > thresholds.alertUpperBound {
            return .critical
        } else if value < thresholds.warningLowerBound || value > thresholds.warningUpperBound {
            return .warning
        } else {
            return .normal
        }
    }
    
    // コンテキスト情報収集
    func gatherContext(userId: String, metric: MetricType) async -> WarningContext {
        let recentWorkouts = await fetchRecentWorkouts(userId: userId, days: 7)
        let sleepData = await fetchSleepData(userId: userId, days: 3)
        let stressIndicators = await fetchStressIndicators(userId: userId, days: 7)
        
        return WarningContext(
            recentTrainingLoad: calculateTrainingLoad(recentWorkouts),
            sleepQuality: calculateSleepQuality(sleepData),
            stressLevel: calculateStressLevel(stressIndicators),
            dataQuality: assessDataQuality(userId: userId, metric: metric),
            isReliable: assessReliability(recentWorkouts, sleepData)
        )
    }
}

enum WarningSeverity: Int, CaseIterable {
    case normal = 0
    case info = 1
    case warning = 2
    case critical = 3
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}
```

### パーソナライズド警告メッセージ
```swift
struct PersonalizedMessageGenerator {
    func generateMessage(value: Double, baseline: PersonalBaseline, context: WarningContext) -> String {
        let deviation = ((value - baseline.meanValue) / baseline.standardDeviation)
        let deviationText = String(format: "%.1f", abs(deviation))
        
        switch (deviation, context.recentTrainingLoad) {
        case let (d, _) where d < -2.0:
            return "心拍効率が個人平均より\(deviationText)σ低下。最近のトレーニング負荷（\(context.recentTrainingLoad)）を考慮すると、回復が必要かもしれません。"
            
        case let (d, load) where d < -1.5 && load > .high:
            return "心拍効率が\(deviationText)σ低下＋高負荷継続中。過負荷リスクがあります。"
            
        case let (d, _) where d > 2.0:
            return "心拍効率が個人平均より\(deviationText)σ向上！トレーニング効果が表れています。"
            
        default:
            return "心拍効率は個人範囲内（\(deviationText)σ偏差）で正常です。"
        }
    }
    
    func generateRecommendations(severity: WarningSeverity, context: WarningContext) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        switch severity {
        case .critical:
            recommendations.append(.immediateRest)
            recommendations.append(.consultCoach)
            
        case .warning:
            if context.sleepQuality < 0.7 {
                recommendations.append(.improveSleep)
            }
            if context.stressLevel > 0.7 {
                recommendations.append(.stressManagement)
            }
            recommendations.append(.reduceIntensity)
            
        case .info:
            recommendations.append(.monitor)
            
        case .normal:
            recommendations.append(.continue)
        }
        
        return recommendations
    }
}
```

---

## ⚡ Implementation Plan

### Phase 1: ベースライン計算エンジン (2 days)
1. PersonalizedBaselineEngine実装
2. 頑健統計量・季節性検出
3. トレンド分析機能

### Phase 2: 適応型閾値システム (2 days)
1. AdaptiveThresholdEngine実装
2. 感度レベル調整機能
3. トレンド・季節調整

### Phase 3: 早期警告・メッセージ生成 (1 day)
1. EarlyWarningSystem統合
2. パーソナライズドメッセージ
3. レコメンデーション生成

---

## 📊 Success Criteria

- [ ] 個別ベースライン自動計算
- [ ] 適応型閾値システム稼働
- [ ] パーソナライズド警告メッセージ
- [ ] 偽陽性60%削減達成
- [ ] 早期異常検出率20%向上

*Created: 2025-08-13*  
*Status: Ready for Implementation*  
*Dependencies: Issue #58*