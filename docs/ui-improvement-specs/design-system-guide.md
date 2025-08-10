# 🎨 WPRシステム デザインシステム・スタイルガイド

## 🎯 デザイン哲学

**コンセプト**: "科学的信頼性 × 直感的理解 × モチベーション向上"

- **科学的信頼性**: データの正確性と信頼性を視覚的に表現
- **直感的理解**: 複雑な科学指標を瞬時に把握可能  
- **モチベーション向上**: 進捗と達成感を鮮明に演出

---

## 🎨 **1. カラーパレット**

### **プライマリカラー: WPR専用**
```swift
enum WPRColor {
    // WPRメインカラー
    static let wprBlue = Color(red: 0.0, green: 0.48, blue: 1.0)      // #007AFF
    static let wprGreen = Color(red: 0.20, green: 0.78, blue: 0.35)   // #34C759
    static let wprRed = Color(red: 1.0, green: 0.23, blue: 0.19)      // #FF3B30
    
    // 進捗状態カラー
    static let excellent = Color(red: 0.0, green: 0.8, blue: 0.2)     // 90%+ 
    static let good = Color(red: 0.4, green: 0.8, blue: 0.2)          // 70-89%
    static let average = Color(red: 1.0, green: 0.8, blue: 0.0)       // 50-69%
    static let needsWork = Color(red: 1.0, green: 0.6, blue: 0.0)     // 30-49%
    static let critical = Color(red: 1.0, green: 0.3, blue: 0.3)      // <30%
}
```

### **科学的指標別カラー**
```swift
enum MetricColor {
    // 各指標の固有カラー（識別性重視）
    static let efficiency = Color(red: 1.0, green: 0.8, blue: 0.0)    // ⚡ イエロー
    static let powerProfile = Color(red: 1.0, green: 0.0, blue: 0.0)  // 🚀 レッド  
    static let hrEfficiency = Color(red: 1.0, green: 0.0, blue: 0.5)  // 💓 ピンク
    static let volumeLoad = Color(red: 0.0, green: 0.8, blue: 0.0)    // 💪 グリーン
    static let rom = Color(red: 0.6, green: 0.0, blue: 1.0)           // 🤸 パープル
}
```

### **セマンティックカラー**
```swift  
enum SemanticColor {
    // 機能的カラー
    static let success = WPRColor.wprGreen
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let error = WPRColor.wprRed
    static let info = WPRColor.wprBlue
    
    // 背景・テキスト
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
}
```

---

## 📝 **2. Typography階層**

### **フォントシステム**
```swift
enum WPRFont {
    // 数値表示（WPR値、指標値）
    static let heroNumber = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let largeNumber = Font.system(size: 32, weight: .bold, design: .rounded) 
    static let mediumNumber = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let smallNumber = Font.system(size: 18, weight: .medium, design: .rounded)
    
    // 見出し・ラベル
    static let sectionTitle = Font.system(size: 22, weight: .bold, design: .default)
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .default)
    static let metricLabel = Font.system(size: 16, weight: .medium, design: .default)
    static let caption = Font.system(size: 14, weight: .regular, design: .default)
    
    // 説明・補助テキスト  
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let scientificNote = Font.system(size: 12, weight: .regular, design: .monospaced)
}
```

### **テキストスタイル適用例**
```swift
struct MetricDisplayText: View {
    let value: Double
    let unit: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", value))
                    .font(WPRFont.largeNumber)
                    .foregroundColor(SemanticColor.primaryText)
                
                Text(unit)
                    .font(WPRFont.metricLabel)
                    .foregroundColor(SemanticColor.secondaryText)
            }
            
            Text(label)
                .font(WPRFont.caption)
                .foregroundColor(SemanticColor.secondaryText)
        }
    }
}
```

---

## 🔸 **3. アイコンシステム**

### **SF Symbols統一使用**
```swift
enum WPRIcon {
    // WPRシステム専用アイコン
    static let wprMain = "target"
    static let progress = "chart.line.uptrend.xyaxis"
    static let bottleneck = "exclamationmark.triangle.fill"
    static let achievement = "rosette"
    
    // 科学的指標アイコン
    static let efficiency = "bolt.fill"              // ⚡ Efficiency Factor
    static let powerProfile = "speedometer"          // 🚀 Power Profile  
    static let hrEfficiency = "heart.fill"           // 💓 HR Efficiency
    static let volumeLoad = "figure.strengthtraining.traditional" // 💪 Volume Load
    static let rom = "figure.flexibility"            // 🤸 ROM
    
    // アクション・ナビゲーション
    static let drillDown = "chevron.right"
    static let back = "chevron.left"
    static let refresh = "arrow.clockwise"
    static let test = "testtube.2"
    static let settings = "gearshape.fill"
}
```

### **アイコン表示仕様**
```swift
struct MetricIcon: View {
    let type: MetricType
    let size: CGFloat = 24
    
    var body: some View {
        Image(systemName: type.icon)
            .font(.system(size: size, weight: .medium))
            .foregroundColor(type.color)
            .frame(width: size * 1.5, height: size * 1.5)
            .background(
                Circle()
                    .fill(type.color.opacity(0.1))
            )
    }
}
```

---

## 📐 **4. レイアウト・スペーシング**

### **グリッドシステム**
```swift
enum WPRSpacing {
    // 基本スペーシング (8ptグリッド)
    static let xs: CGFloat = 4    // 0.5x
    static let sm: CGFloat = 8    // 1x
    static let md: CGFloat = 16   // 2x
    static let lg: CGFloat = 24   // 3x
    static let xl: CGFloat = 32   // 4x
    static let xxl: CGFloat = 48  // 6x
    
    // カード・コンポーネント専用
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 20
    static let sectionSpacing: CGFloat = 32
}
```

### **カードデザイン統一**
```swift
struct WPRCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(WPRSpacing.cardPadding)
            .background(SemanticColor.cardBackground)
            .cornerRadius(12)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

extension View {
    func wprCardStyle() -> some View {
        modifier(WPRCardStyle())
    }
}
```

---

## 📊 **5. データ可視化スタイル**

### **プログレスバー統一仕様**
```swift
struct WPRProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))
                    .frame(height: height)
                
                // プログレス
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(
                        width: geometry.size.width * progress,
                        height: height
                    )
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: height)
    }
}
```

### **チャート配色**
```swift
enum ChartColor {
    // Swift Charts用カラーパレット
    static let primary = WPRColor.wprBlue
    static let secondary = WPRColor.wprGreen
    static let tertiary = Color.gray
    static let accent = WPRColor.wprRed
    
    // グラデーション
    static let progressGradient = LinearGradient(
        colors: [WPRColor.wprBlue, WPRColor.wprGreen],
        startPoint: .leading,
        endPoint: .trailing
    )
}
```

---

## 🎭 **6. アニメーション仕様**

### **標準トランジション**
```swift
enum WPRAnimation {
    // 基本アニメーション
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let smooth = Animation.easeInOut(duration: 0.5)
    static let slow = Animation.easeInOut(duration: 0.8)
    
    // 特殊効果
    static let bounce = Animation.spring(response: 0.6, dampingFraction: 0.7)
    static let gentle = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    // 遅延
    static func withDelay(_ delay: Double) -> Animation {
        standard.delay(delay)
    }
}
```

### **アニメーション適用例**
```swift
struct AnimatedMetricCard: View {
    @State private var isVisible = false
    
    var body: some View {
        MetricCardContent()
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .onAppear {
                withAnimation(WPRAnimation.bounce) {
                    isVisible = true
                }
            }
    }
}
```

---

## 📱 **7. レスポンシブデザイン**

### **デバイス別適応**
```swift
enum DeviceCategory {
    case compact    // iPhone SE, iPhone 12 mini
    case regular    // iPhone 12, iPhone 13  
    case large      // iPhone 14 Plus, iPhone 15 Pro Max
    case pad        // iPad
    
    var cardColumns: Int {
        switch self {
        case .compact: return 1
        case .regular: return 2
        case .large: return 2
        case .pad: return 3
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .compact: return WPRSpacing.md
        case .regular: return WPRSpacing.lg
        case .large: return WPRSpacing.xl
        case .pad: return WPRSpacing.xl
        }
    }
}
```

---

## ♿ **8. アクセシビリティガイドライン**

### **色覚対応**
```swift
// 色だけに依存しない設計
struct AccessibleProgressIndicator: View {
    let progress: Double
    let status: ProgressStatus
    
    var body: some View {
        HStack {
            // 色 + アイコンでステータス表現
            Image(systemName: status.icon)
                .foregroundColor(status.color)
            
            // 色 + テキストでプログレス表現
            Text("\(Int(progress * 100))%")
                .font(WPRFont.mediumNumber)
        }
    }
}
```

### **VoiceOver対応**
```swift
struct VoiceOverMetricCard: View {
    let metric: MetricData
    
    var body: some View {
        MetricCard(metric: metric)
            .accessibilityLabel("\(metric.name): \(metric.currentValue) / \(metric.targetValue)")
            .accessibilityValue("進捗 \(Int(metric.progress * 100))パーセント")
            .accessibilityHint("タップして詳細を表示")
            .accessibilityAddTraits(.isButton)
    }
}
```

---

## 🛠️ **9. 実装用SwiftUIコンポーネント**

### **再利用可能コンポーネント群**
```swift
// 1. WPRメトリック表示
struct WPRMetricDisplay: View
struct WPRProgressCard: View
struct WPRComparisonView: View

// 2. 科学指標表示
struct ScientificMetricRow: View
struct MetricTrendChart: View
struct MetricDetailSheet: View

// 3. インタラクション
struct TappableMetricCard: View
struct SwipeableMetricsView: View
struct PullToRefreshIndicator: View

// 4. フィードバック
struct SuccessAnimation: View
struct AchievementBadge: View
struct LoadingStateView: View
```

---

## 🎯 **10. 実装優先順位**

### **Phase 1: 基本デザインシステム（1日）**
1. カラーパレット定義・適用
2. Typography階層実装
3. 基本カードスタイル

### **Phase 2: コンポーネントライブラリ（1日）**
4. 再利用可能コンポーネント作成
5. アイコンシステム統合
6. レスポンシブ対応

### **Phase 3: 高度な表現（1日）**
7. アニメーション統合
8. データ可視化スタイル
9. アクセシビリティ対応

---

このデザインシステムにより、WPRシステム全体で一貫性のある、科学的でありながら直感的なユーザー体験が実現されます。各コンポーネントが統一されたルールに従うことで、ユーザーの学習コストを削減し、データの理解と行動促進を最大化します。