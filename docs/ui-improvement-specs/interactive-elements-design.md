# 🎮 インタラクティブ要素デザイン仕様書

## 🎯 インタラクション設計目標

**目的**: WPRシステムの科学的データを、ユーザーが直感的に探索・理解・行動できるインタラクティブ体験の設計

---

## 🎪 **1. タップ・ドリルダウン設計**

### **階層的情報表示**

#### **Level 1: ダッシュボード概要**
```swift
WPRCentralDashboard
├── WPRMainCard [タップ可能]
├── ScientificMetricsSummaryCard [各指標タップ可能]  
├── BottleneckAnalysisCard [ボトルネックタップ可能]
└── RecommendedActionsCard [アクションタップ可能]
```

#### **Level 2: 詳細表示シート**
```swift
// 各要素タップ → 対応詳細シート表示
WPRMainCard → WPRDetailSheet
EF指標 → EfficiencyDetailSheet  
PowerProfile → PowerProfileDetailSheet
HR効率 → HREfficiencyDetailSheet
VL筋力 → VolumeLoadDetailSheet
ROM柔軟性 → ROMDetailSheet
```

#### **Level 3: アクション実行**
```swift
// 詳細シート内からの直接アクション
"SST推奨" → WeeklyPlanManager統合
"筋トレ提案" → DailyTask追加
"柔軟性改善" → FlexibilityProgram表示
```

---

## 🎨 **2. アニメーション・トランジション**

### **タップフィードバック**
```swift
struct TappableMetricCard: View {
    @State private var isPressed = false
    
    var body: some View {
        MetricContent()
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                withAnimation {
                    // アクション実行
                }
            }
            .pressEvents(
                onPress: { isPressed = true },
                onRelease: { isPressed = false }
            )
    }
}
```

### **プログレスバー更新アニメーション**
```swift
struct AnimatedProgressBar: View {
    let progress: Double
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ProgressView(value: animatedProgress)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = progress
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedProgress = newValue  
                }
            }
    }
}
```

### **シート表示トランジション**
```swift
struct MetricDetailSheet: View {
    @State private var offset: CGFloat = UIScreen.main.bounds.height
    
    var body: some View {
        DetailContent()
            .offset(y: offset)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    offset = 0
                }
            }
    }
}
```

---

## 📊 **3. データ更新リアルタイムフィードバック**

### **ワークアウト記録 → WPR更新の視覚的フィードバック**

#### **更新フロー**
```swift
struct WPRUpdateIndicator: View {
    @State private var isUpdating = false
    @State private var showSuccess = false
    
    var body: some View {
        HStack {
            if isUpdating {
                ProgressView()
                    .scaleEffect(0.8)
                Text("WPR更新中...")
                    .font(.caption)
            } else if showSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("WPR更新完了!")
                    .font(.caption)
            }
        }
        .animation(.easeInOut, value: isUpdating)
        .animation(.easeInOut, value: showSuccess)
    }
}
```

#### **数値変化アニメーション**
```swift
struct CountingNumberText: View {
    let targetValue: Double
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text(String(format: "%.2f", displayValue))
            .font(.largeTitle.bold())
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    displayValue = targetValue
                }
            }
            .onChange(of: targetValue) { _, newValue in
                withAnimation(.easeInOut(duration: 0.8)) {
                    displayValue = newValue
                }
            }
    }
}
```

---

## 🎯 **4. スワイプ・ジェスチャー操作**

### **水平スワイプ: 指標切り替え**
```swift
struct SwipeableMetricsView: View {
    @State private var selectedMetric: MetricType = .efficiency
    
    var body: some View {
        TabView(selection: $selectedMetric) {
            ForEach(MetricType.allCases, id: \.self) { metric in
                MetricDetailView(metric: metric)
                    .tag(metric)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .animation(.easeInOut, value: selectedMetric)
    }
}
```

### **縦スワイプ: 時間軸切り替え**
```swift
struct TimeframeSelector: View {
    @State private var selectedTimeframe: Timeframe = .week
    
    enum Timeframe: CaseIterable {
        case week, month, quarter
        
        var displayName: String {
            switch self {
            case .week: return "1週間"
            case .month: return "1ヶ月"  
            case .quarter: return "3ヶ月"
            }
        }
    }
    
    var body: some View {
        Picker("期間", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.displayName).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .animation(.easeInOut, value: selectedTimeframe)
    }
}
```

---

## 🔥 **5. 成功・達成時のフィードバック**

### **バッジ獲得アニメーション**
```swift
struct AchievementBadgeAnimation: View {
    let achievement: Achievement
    @State private var scale: Double = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack {
            Image(systemName: achievement.iconName)
                .font(.system(size: 60))
                .foregroundColor(achievement.color)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
            
            Text(achievement.title)
                .font(.headline)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                rotation = 360
            }
        }
    }
}
```

### **WPR目標達成セレブレーション**
```swift
struct WPRCelebrationView: View {
    @State private var showConfetti = false
    @State private var showMessage = false
    
    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 100))
                    .scaleEffect(showMessage ? 1.0 : 0.5)
                
                Text("WPR 4.5 達成！")
                    .font(.largeTitle.bold())
                    .opacity(showMessage ? 1.0 : 0)
                
                Text("100日チャレンジ完了")
                    .font(.title2)
                    .opacity(showMessage ? 1.0 : 0)
            }
        }
        .onAppear {
            showConfetti = true
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5)) {
                showMessage = true
            }
        }
    }
}
```

---

## 📱 **6. 長押し・コンテキストメニュー**

### **指標長押しメニュー**
```swift
struct MetricContextMenu: View {
    let metric: MetricType
    
    var body: some View {
        MetricRow(metric: metric)
            .contextMenu {
                Button("詳細を表示", systemImage: "info.circle") {
                    showDetailSheet(for: metric)
                }
                
                Button("履歴を確認", systemImage: "clock.arrow.circlepath") {
                    showHistory(for: metric)
                }
                
                Button("改善提案", systemImage: "lightbulb") {
                    showRecommendations(for: metric)
                }
                
                if metric == currentBottleneck {
                    Button("集中改善プラン", systemImage: "target") {
                        createFocusedPlan(for: metric)
                    }
                }
            }
    }
}
```

---

## 🔄 **7. Pull-to-Refresh機能**

### **データ更新操作**
```swift
struct RefreshableWPRDashboard: View {
    @State private var isRefreshing = false
    
    var body: some View {
        ScrollView {
            WPRDashboardContent()
        }
        .refreshable {
            await refreshWPRData()
        }
        .overlay(alignment: .top) {
            if isRefreshing {
                RefreshIndicator()
                    .transition(.move(edge: .top))
            }
        }
    }
    
    @MainActor
    private func refreshWPRData() async {
        isRefreshing = true
        
        // WPRシステム再計算
        await wprSystem.recalculateAllMetrics()
        
        // ボトルネック再検出
        await bottleneckSystem.reanalyze()
        
        withAnimation {
            isRefreshing = false
        }
    }
}
```

---

## 🎪 **8. ハプティックフィードバック統合**

### **触覚フィードバック設計**
```swift
struct HapticFeedbackManager {
    static func lightTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func achievement() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impactFeedback.impactOccurred()
        }
    }
}
```

### **フィードバック統合例**
```swift
struct InteractiveMetricCard: View {
    var body: some View {
        MetricContent()
            .onTapGesture {
                HapticFeedbackManager.lightTap() // タップ時
                showDetail()
            }
            .onChange(of: metricValue) { _, _ in
                if metricValue >= targetValue {
                    HapticFeedbackManager.achievement() // 目標達成時
                }
            }
    }
}
```

---

## 🔧 **9. 実装優先順位**

### **Phase 1: 基本インタラクション（1日）**
1. タップ可能指標カード
2. 詳細シート表示・非表示
3. 基本アニメーション（スケール・フェード）

### **Phase 2: フィードバック強化（1日）**
4. データ更新アニメーション
5. プログレスバー更新
6. ハプティックフィードバック

### **Phase 3: 高度な操作（1日）**  
7. スワイプジェスチャー
8. コンテキストメニュー
9. Pull-to-Refresh

### **Phase 4: 成功体験演出（1日）**
10. 達成アニメーション
11. バッジ獲得エフェクト
12. セレブレーション画面

---

この設計により、WPRシステムの科学的データが静的な表示から、ユーザーが積極的に探索・操作したくなる動的なインタラクティブ体験へと進化します。各操作に対する適切なフィードバックにより、ユーザーのエンゲージメントと満足感が大幅に向上します。