# 🔬 科学的指標可視化デザイン仕様書

## 🎯 科学的指標の可視化目標

**目的**: 5つの科学的指標（EF, PowerProfile, HR効率, VL, ROM）を統合的に表示し、ユーザーがWPR 4.5達成への進捗と改善点を直感的に理解できるUI設計

---

## 📊 **1. WPR メイン進捗表示**

### **WPRMainCard 詳細仕様**

#### **レイアウト構造**
```
┌─────────────────────────────────────┐
│  🎯 WPR 4.5 達成への道のり          │
│                                     │
│     3.2  ████████░░░  4.5          │
│    現在     64%        目標         │
│                                     │
│  📅 残り 45日  📈 月間 +0.3 WPR     │
│  🔥 ボトルネック: 筋力               │
└─────────────────────────────────────┘
```

#### **データソース**
```swift
struct WPRProgressData {
    let currentWPR: Double // wprSystem.calculatedWPR
    let targetWPR: Double = 4.5
    let progressRatio: Double // wprSystem.targetProgressRatio
    let daysRemaining: Int? // wprSystem.daysToTarget
    let monthlyGain: Double // wprSystem.projectedWPRGain
    let currentBottleneck: BottleneckType // wprSystem.currentBottleneck
}
```

#### **ビジュアル要素**
- **プログレスバー**: Linear, 高さ12pt, 角丸6pt
- **カラー**: 現在値は青 (#007AFF), 目標は緑 (#34C759)
- **数値**: 大きなフォント (32pt), 太字
- **アイコン**: SF Symbolsを活用

---

## 📈 **2. 科学的指標統合ダッシュボード**

### **ScientificMetricsSummaryCard 詳細仕様**

#### **5指標レイアウト**
```
┌─────────────────────────────────────┐
│           科学的指標概要            │
├─────────────────────────────────────┤
│ ⚡ EF: 1.28/1.5  ████████░░ 85%    │
│ 🚀 Power: 12%/15%  ████████░ 80%    │  
│ 💓 HR: -8/-15bpm  ████░░░░░░ 53%    │
│ 💪 VL: +18%/+30%  ████████░░ 60%    │
│ 🤸 ROM: +12°/+15°  ████████████ 80% │
└─────────────────────────────────────┘
```

#### **指標別データ仕様**

##### **Efficiency Factor (EF)**
```swift
struct EFVisualizationData {
    let current: Double // wprSystem.efficiencyFactor
    let target: Double = 1.5
    let baseline: Double // wprSystem.efficiencyBaseline
    let progressRatio: Double // wprSystem.efficiencyProgress
    let icon: String = "bolt.fill"
    let color: Color = .yellow
}
```

##### **Power Profile**  
```swift
struct PowerProfileVisualizationData {
    let improvementRatio: Double // wprSystem.powerProfileProgress
    let target: Double = 0.15 // 15%向上
    let powerValues: [PowerValue] // 5秒,1分,5分,20分,60分
    let icon: String = "speedometer"
    let color: Color = .red
}

struct PowerValue {
    let duration: PowerDuration // .fiveSecond, .oneMinute等
    let current: Int
    let baseline: Int  
    let improvementRatio: Double
}
```

##### **HR Efficiency**
```swift
struct HREfficiencyVisualizationData {
    let currentReduction: Double // 現在の心拍数削減量
    let targetReduction: Double = -15.0 // -15bpm目標
    let progressRatio: Double
    let hrAtPowerData: [HRAtPowerPoint] // 200W,250W,300W時点
    let icon: String = "heart.fill"  
    let color: Color = .pink
}
```

##### **Volume Load (VL)**
```swift
struct VLVisualizationData {
    let pushVL: Double // 現在のPushボリューム
    let pullVL: Double // 現在のPullボリューム  
    let legsVL: Double // 現在のLegsボリューム
    let targetIncrease: Double = 0.30 // 30%向上目標
    let overallProgress: Double // 総合改善率
    let icon: String = "figure.strengthtraining.traditional"
    let color: Color = .green
}
```

##### **ROM (Range of Motion)**
```swift
struct ROMVisualizationData {
    let forwardBendAngle: Double // 前屈角度
    let hipFlexibility: Double // 股関節柔軟性
    let shoulderMobility: Double // 肩可動域  
    let averageImprovement: Double // 平均改善度
    let targetIncrease: Double = 15.0 // +15°目標
    let icon: String = "figure.flexibility"
    let color: Color = .purple  
}
```

---

## 🎨 **3. 可視化デザインパターン**

### **プログレスバー統一仕様**
```swift
struct ScientificProgressBar: View {
    let current: Double
    let target: Double
    let color: Color
    
    // 標準: 高さ8pt, 角丸4pt, 背景gray
    // アニメーション: .easeInOut(duration: 0.5)
}
```

### **数値表示パターン**  
```swift
struct MetricValueDisplay: View {
    let current: String  // "1.28"
    let target: String   // "1.5" 
    let unit: String     // "EF"
    let progress: Double // 0.85
    
    // レイアウト: current/target (unit) progress%
    // フォント: current=20pt太字, target=16pt, unit=12pt
}
```

### **アイコン・カラーシステム**
```swift
enum MetricType: CaseIterable {
    case efficiency     // ⚡ bolt.fill, .yellow  
    case powerProfile   // 🚀 speedometer, .red
    case hrEfficiency   // 💓 heart.fill, .pink
    case volumeLoad     // 💪 figure.strengthtraining, .green
    case rom           // 🤸 figure.flexibility, .purple
    
    var icon: String { ... }
    var color: Color { ... }
    var displayName: String { ... }
}
```

---

## 📱 **4. インタラクティブ要素**

### **ドリルダウン表示**
```swift
// タップ可能な指標要素
struct TappableMetricRow: View {
    let metric: MetricType
    let data: MetricVisualizationData
    let onTap: (MetricType) -> Void
    
    // タップ → 詳細シート表示
    // アニメーション: スケール＋フェード
}
```

### **詳細表示シート**
```swift
struct MetricDetailSheet: View {
    let metric: MetricType
    
    // 内容:
    // - 過去30日のトレンドグラフ  
    // - 具体的改善アクション
    // - 科学的根拠の説明
    // - 次回測定予定
}
```

---

## 📊 **5. Swift Charts統合**

### **WPR予測チャート仕様**
```swift
struct WPRPredictionChart: View {
    let currentWPR: Double
    let predictions: [WPRPrediction] // 30日,60日,100日予測
    let target: Double = 4.5
    
    var body: some View {
        Chart {
            LineMark(x: .value("日数", 0), y: .value("WPR", currentWPR))
                .foregroundStyle(.blue)
            
            ForEach(predictions) { prediction in
                LineMark(x: .value("日数", prediction.days), 
                        y: .value("WPR", prediction.predictedWPR))
                    .foregroundStyle(.blue)
            }
            
            RuleMark(y: .value("目標", target))
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
        }
        .chartYScale(domain: 3.0...5.0)
        .chartXScale(domain: 0...100)
    }
}
```

### **指標別トレンドチャート**
```swift  
struct MetricTrendChart: View {
    let metric: MetricType
    let historicalData: [MetricDataPoint]
    
    // 過去30日の推移を表示
    // Y軸: 指標値, X軸: 日付
    // トレンドライン + 目標値ライン
}
```

---

## 🔢 **6. データ計算ロジック**

### **進捗率計算**
```swift
extension WPRTrackingSystem {
    func getMetricProgress(_ type: MetricType) -> Double {
        switch type {
        case .efficiency:
            return efficiencyProgress // 既存実装
        case .powerProfile:  
            return powerProfileProgress // 既存実装
        case .hrEfficiency:
            return hrEfficiencyProgress // 新規実装必要
        case .volumeLoad:
            return volumeLoadProgress // 新規実装必要  
        case .rom:
            return romProgress // 新規実装必要
        }
    }
}
```

### **ボトルネック判定**
```swift
func detectBottleneck() -> MetricType {
    let progresses = MetricType.allCases.map { type in
        (type, getMetricProgress(type))
    }
    
    return progresses.min { $0.1 < $1.1 }?.0 ?? .efficiency
}
```

---

## 🎯 **7. 実装優先順位**

### **Phase 1: 基本表示（1日）**
1. WPRMainCard - メイン進捗
2. ScientificMetricsSummaryCard - 5指標概要

### **Phase 2: インタラクション（1日）**  
3. タップ可能な指標行
4. 詳細表示シート

### **Phase 3: 可視化強化（1日）**
5. WPRPredictionChart - Swift Charts
6. トレンドチャート各指標

---

この仕様により、科学的根拠に基づく5つの指標が統合的に可視化され、ユーザーはWPR 4.5達成への明確な道筋を把握できるUIが実現されます。